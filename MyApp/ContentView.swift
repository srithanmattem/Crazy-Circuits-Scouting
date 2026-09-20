import Foundation
import SwiftUI

struct ContentView: View {
    @State private var selectedSection: AppSection? = .dashboard
    @State private var seasons: [Season] = [Season.blank()]
    @State private var activeSeasonID: UUID?
    @State private var searchText = ""
    @State private var selectedTeamID: Int?
    @State private var selectedComparisonTeamIDs: Set<Int> = []
    @State private var syncStatusMessage = "Automatic sync"

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selection: $selectedSection,
                seasons: $seasons,
                activeSeasonID: activeSeasonIDBinding,
                onNewSeason: createSeason,
                onDeleteSeason: deleteActiveSeason,
                syncStatusMessage: syncStatusMessage
            )
        } detail: {
            content
                .navigationTitle(selectedSection?.title ?? "Circuit Scout")
        }
        .onAppear {
            if activeSeasonID == nil {
                activeSeasonID = seasons.first?.id
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selectedSection ?? .dashboard {
        case .dashboard:
            DashboardView(
                season: activeSeason,
                onStartScouting: { selectedSection = .scout },
                onCompare: { selectedSection = .compare },
                onNewSeason: createSeason
            )
        case .scout:
            ScoutInputView(season: activeSeasonBinding)
        case .teams:
            TeamDatabaseView(
                season: activeSeasonBinding,
                searchText: $searchText,
                selectedTeamID: $selectedTeamID,
                selectedComparisonTeamIDs: $selectedComparisonTeamIDs
            )
        case .matches:
            MatchNotesView(season: activeSeasonBinding)
        case .compare:
            CompareTeamsView(season: activeSeason, selectedTeamIDs: $selectedComparisonTeamIDs)
        case .assistant:
            AssistantView(season: activeSeason)
        }
    }

    private var activeSeason: Season {
        seasons.first { $0.id == activeSeasonID } ?? seasons[0]
    }

    private var activeSeasonIDBinding: Binding<UUID?> {
        Binding(
            get: { activeSeasonID ?? seasons.first?.id },
            set: { newValue in
                activeSeasonID = newValue
                selectedTeamID = nil
                selectedComparisonTeamIDs = []
                searchText = ""
            }
        )
    }

    private var activeSeasonBinding: Binding<Season> {
        Binding(
            get: { activeSeason },
            set: { updatedSeason in
                guard let index = seasons.firstIndex(where: { $0.id == updatedSeason.id }) else {
                    return
                }
                seasons[index] = updatedSeason
            }
        )
    }

    private func createSeason() {
        let newSeason = Season.blank(number: seasons.count + 1)
        seasons.append(newSeason)
        activeSeasonID = newSeason.id
        selectedSection = .dashboard
        selectedTeamID = nil
        selectedComparisonTeamIDs = []
        searchText = ""
        syncSeasonToBase44(newSeason)
    }

    private func deleteActiveSeason() {
        guard seasons.count > 1, let activeSeasonID else {
            return
        }

        seasons.removeAll { $0.id == activeSeasonID }
        self.activeSeasonID = seasons.first?.id
        selectedTeamID = nil
        selectedComparisonTeamIDs = []
    }

    private func syncSeasonToBase44(_ season: Season) {
        Task {
            do {
                try await Base44SyncClient().pushSeasonSnapshot(season)
                await MainActor.run {
                    syncStatusMessage = "Synced \(season.displayName)"
                }
            } catch {
                await MainActor.run {
                    syncStatusMessage = error.localizedDescription
                }
            }
        }
    }
}

private enum AppSection: String, CaseIterable, Identifiable {
    case dashboard
    case scout
    case teams
    case matches
    case compare
    case assistant

    var id: Self { self }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .scout: "Scout"
        case .teams: "Teams"
        case .matches: "Match Notes"
        case .compare: "Compare"
        case .assistant: "AI Assistant"
        }
    }

    var symbolName: String {
        switch self {
        case .dashboard: "chart.bar.xaxis"
        case .scout: "square.and.pencil"
        case .teams: "person.3.sequence"
        case .matches: "note.text"
        case .compare: "arrow.left.arrow.right"
        case .assistant: "sparkles"
        }
    }
}

private enum ScoutingTab: String, CaseIterable, Identifiable {
    case teamInfo = "Team"
    case autonomous = "Auto"
    case teleOp = "Tele-Op"
    case endgame = "Endgame"

    var id: Self { self }
}

private struct Season: Identifiable, Hashable {
    let id: UUID
    var name: String
    var gameName: String
    var year: String
    var teams: [Team]
    var matchNotes: [MatchNote]

    static func blank(number: Int = 1) -> Season {
        Season(
            id: UUID(),
            name: number == 1 ? "New Season" : "New Season \(number)",
            gameName: "",
            year: "",
            teams: [],
            matchNotes: []
        )
    }

    var displayName: String {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedName.isEmpty ? "Untitled Season" : trimmedName
    }

    var subtitle: String {
        let parts = [gameName, year]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return parts.isEmpty ? "Blank season" : parts.joined(separator: " - ")
    }
}

private struct Team: Identifiable, Hashable {
    var id: Int { number }

    var number: Int
    var name: String
    var region: String
    var driveTrain: String
    var autoScore: Int
    var teleOpScore: Int
    var endgameScore: Int
    var lastSeen: String
    var notes: String

    var overallScore: Int {
        autoScore + teleOpScore + endgameScore
    }
}

private struct MatchNote: Identifiable, Hashable {
    let id: UUID
    var teamNumber: Int
    var teamName: String
    var event: String
    var summary: String
    var score: Int
    var date: Date

    init(id: UUID = UUID(), teamNumber: Int, teamName: String, event: String, summary: String, score: Int, date: Date) {
        self.id = id
        self.teamNumber = teamNumber
        self.teamName = teamName
        self.event = event
        self.summary = summary
        self.score = score
        self.date = date
    }
}

private struct TeamDraft {
    var number = ""
    var name = ""
    var region = ""
    var driveTrain = "Mecanum"
    var autoScore = 0.0
    var teleOpScore = 0.0
    var endgameScore = 0.0
    var notes = ""

    init() {}

    init(team: Team) {
        number = String(team.number)
        name = team.name
        region = team.region
        driveTrain = team.driveTrain
        autoScore = Double(team.autoScore)
        teleOpScore = Double(team.teleOpScore)
        endgameScore = Double(team.endgameScore)
        notes = team.notes
    }

    var canSave: Bool {
        Int(number) != nil
            && !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !region.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var team: Team? {
        guard let number = Int(number), canSave else {
            return nil
        }

        return Team(
            number: number,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            region: region.trimmingCharacters(in: .whitespacesAndNewlines),
            driveTrain: driveTrain,
            autoScore: Int(autoScore),
            teleOpScore: Int(teleOpScore),
            endgameScore: Int(endgameScore),
            lastSeen: "Today",
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }
}

private struct NoteDraft {
    var teamNumber = ""
    var event = ""
    var summary = ""
    var score = 0.0

    var canSave: Bool {
        Int(teamNumber) != nil
            && !event.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private struct SidebarView: View {
    @Binding var selection: AppSection?
    @Binding var seasons: [Season]
    @Binding var activeSeasonID: UUID?
    let onNewSeason: () -> Void
    let onDeleteSeason: () -> Void
    let syncStatusMessage: String

    @State private var isManagingSeason = false

    private var activeSeason: Season? {
        seasons.first { $0.id == activeSeasonID }
    }

    private var activeSeasonBinding: Binding<Season>? {
        guard let index = seasons.firstIndex(where: { $0.id == activeSeasonID }) else {
            return nil
        }

        return $seasons[index]
    }

    var body: some View {
        List(selection: $selection) {
            Section("Navigate") {
                ForEach(AppSection.allCases) { section in
                    NavigationLink(value: section) {
                        Label(section.title, systemImage: section.symbolName)
                    }
                }
            }
        }
        .navigationTitle("Circuit Scout")
        .safeAreaInset(edge: .bottom) {
            SeasonSummaryCard(
                seasons: seasons,
                activeSeasonID: $activeSeasonID,
                activeSeason: activeSeason,
                onManage: { isManagingSeason = true },
                onNewSeason: onNewSeason,
                onDeleteSeason: onDeleteSeason,
                syncStatusMessage: syncStatusMessage
            )
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.thinMaterial)
        }
        .sheet(isPresented: $isManagingSeason) {
            if let activeSeasonBinding {
                SeasonManagerSheet(
                    season: activeSeasonBinding,
                    seasons: seasons,
                    activeSeasonID: $activeSeasonID,
                    canDelete: seasons.count > 1,
                    onNewSeason: onNewSeason,
                    onDeleteSeason: {
                        onDeleteSeason()
                        if seasons.count <= 2 {
                            isManagingSeason = false
                        }
                    }
                )
            }
        }
    }
}

private struct SeasonSummaryCard: View {
    let seasons: [Season]
    @Binding var activeSeasonID: UUID?
    let activeSeason: Season?
    let onManage: () -> Void
    let onNewSeason: () -> Void
    let onDeleteSeason: () -> Void
    let syncStatusMessage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.clock")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Active Season")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(activeSeason?.displayName ?? "No Season")
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: 8)
            }

            if let activeSeason {
                HStack(spacing: 8) {
                    SeasonStatPill(value: "\(activeSeason.teams.count)", label: "Teams", tint: .blue)
                    SeasonStatPill(value: "\(activeSeason.matchNotes.count)", label: "Notes", tint: .orange)
                }

                Text(activeSeason.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Label(syncStatusMessage, systemImage: syncStatusMessage.localizedCaseInsensitiveContains("synced") ? "checkmark.icloud.fill" : "icloud.slash")
                .font(.caption2)
                .foregroundStyle(syncStatusMessage.localizedCaseInsensitiveContains("synced") ? .green : .secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Picker("Season", selection: $activeSeasonID) {
                ForEach(seasons) { season in
                    Text(season.displayName).tag(Optional(season.id))
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Button("New", systemImage: "plus", action: onNewSeason)
                    .buttonStyle(.bordered)

                Button("Manage", systemImage: "slider.horizontal.3", action: onManage)
                    .buttonStyle(.borderedProminent)

                Spacer(minLength: 0)

                Button("Delete", systemImage: "trash", action: onDeleteSeason)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
                    .tint(.red)
                    .disabled(seasons.count <= 1)
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        }
    }
}

private struct SeasonStatPill: View {
    let value: String
    let label: String
    let tint: Color

    var body: some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.caption.bold())
                .monospacedDigit()
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(tint.opacity(0.12), in: Capsule())
    }
}

private struct SeasonManagerSheet: View {
    @Binding var season: Season
    let seasons: [Season]
    @Binding var activeSeasonID: UUID?
    let canDelete: Bool
    let onNewSeason: () -> Void
    let onDeleteSeason: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Current Season") {
                    TextField("Season name", text: $season.name)
                    TextField("Game name", text: $season.gameName)
                    TextField("Year", text: $season.year)
                }

                Section("Switch Season") {
                    Picker("Active Season", selection: $activeSeasonID) {
                        ForEach(seasons) { season in
                            Text(season.displayName).tag(Optional(season.id))
                        }
                    }
                }

                Section("Summary") {
                    LabeledContent("Teams", value: "\(season.teams.count)")
                    LabeledContent("Match Notes", value: "\(season.matchNotes.count)")
                    LabeledContent("Details", value: season.subtitle)
                }

                Section {
                    Button("Create New Blank Season", systemImage: "calendar.badge.plus") {
                        onNewSeason()
                        dismiss()
                    }

                    Button("Delete This Season", systemImage: "trash", role: .destructive) {
                        onDeleteSeason()
                    }
                    .disabled(!canDelete)
                }
            }
            .navigationTitle("Manage Season")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct DashboardView: View {
    let season: Season
    let onStartScouting: () -> Void
    let onCompare: () -> Void
    let onNewSeason: () -> Void

    private var sortedTeams: [Team] {
        season.teams.sorted { $0.overallScore > $1.overallScore }
    }

    var body: some View {
        ScrollView {
            PageContainer {
                PageHeader(
                    title: season.displayName,
                    subtitle: season.subtitle,
                    symbolName: "flag.checkered"
                ) {
                    HStack {
                        Button("New Season", systemImage: "calendar.badge.plus", action: onNewSeason)
                            .buttonStyle(.bordered)
                        Button("Scout", systemImage: "square.and.pencil", action: onStartScouting)
                            .buttonStyle(.borderedProminent)
                    }
                }

                LazyVGrid(columns: adaptiveColumns(minimum: 210), spacing: 16) {
                    MetricCard(title: "Teams Scouted", value: "\(season.teams.count)", symbolName: "person.3.fill", tint: .blue)
                    MetricCard(title: "Match Notes", value: "\(season.matchNotes.count)", symbolName: "note.text", tint: .orange)
                    MetricCard(title: "Top Score", value: "\(sortedTeams.first?.overallScore ?? 0)", symbolName: "trophy.fill", tint: .yellow)
                    MetricCard(title: "Regions", value: "\(Set(season.teams.map(\.region)).count)", symbolName: "map.fill", tint: .green)
                }

                if season.teams.isEmpty {
                    SectionCard(title: "Ready for a Fresh Season", subtitle: "This season starts blank.") {
                        EmptyStateView(symbolName: "plus.circle", title: "No scouting data yet", message: "Start by adding your first team or match note. Nothing here is sample data.")
                        Button("Start Scouting", systemImage: "square.and.pencil", action: onStartScouting)
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                    }
                } else if let topTeam = sortedTeams.first {
                    HeroCard(team: topTeam)
                }

                LazyVGrid(columns: adaptiveColumns(minimum: 320), spacing: 16) {
                    SectionCard(title: "Top Teams", subtitle: "Ranked by combined auto, tele-op, and endgame performance.") {
                        if sortedTeams.isEmpty {
                            EmptyStateView(symbolName: "person.3.sequence", title: "No teams yet", message: "Add teams from Scout or Teams.")
                        } else {
                            VStack(spacing: 12) {
                                ForEach(Array(sortedTeams.prefix(4))) { team in
                                    TeamRankRow(team: team)
                                }
                            }
                        }
                    }

                    SectionCard(title: "Recent Notes", subtitle: "Fast context for drive team conversations.") {
                        if season.matchNotes.isEmpty {
                            EmptyStateView(symbolName: "note.text", title: "No notes yet", message: "Add notes after each match to build useful history.")
                        } else {
                            VStack(spacing: 12) {
                                ForEach(season.matchNotes.prefix(3)) { note in
                                    NoteSummaryRow(note: note)
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(AppTheme.background)
    }
}

private struct ScoutInputView: View {
    @Binding var season: Season

    @State private var selectedTab: ScoutingTab = .teamInfo
    @State private var draft = TeamDraft()
    @State private var matchEvent = ""
    @State private var didSave = false

    var body: some View {
        ScrollView {
            PageContainer {
                PageHeader(
                    title: "Scout a Team",
                    subtitle: "Add real data for \(season.displayName).",
                    symbolName: "square.and.pencil"
                )

                Picker("Scouting step", selection: $selectedTab) {
                    ForEach(ScoutingTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                SectionCard(title: selectedTab.rawValue, subtitle: selectedTabSubtitle) {
                    switch selectedTab {
                    case .teamInfo:
                        TeamInfoForm(draft: $draft)
                    case .autonomous:
                        ScoreStepper(title: "Autonomous score", value: $draft.autoScore, range: 0...20, tint: .blue)
                    case .teleOp:
                        VStack(alignment: .leading, spacing: 18) {
                            ScoreStepper(title: "Tele-op score", value: $draft.teleOpScore, range: 0...30, tint: .green)
                            LabeledContentView(title: "Match Event") {
                                TextField("Qualifier 12", text: $matchEvent)
                            }
                        }
                    case .endgame:
                        EndgameForm(score: $draft.endgameScore, notes: $draft.notes)
                    }
                }

                SectionCard(title: "Live Summary", subtitle: "A quick check before you submit.") {
                    ScoutingSummary(draft: draft)
                }

                HStack {
                    Button("Reset", systemImage: "arrow.counterclockwise") {
                        draft = TeamDraft()
                        selectedTab = .teamInfo
                        matchEvent = ""
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("Submit Scouting Data", systemImage: "paperplane.fill") {
                        saveScoutingData()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!draft.canSave)
                }
            }
        }
        .background(AppTheme.background)
        .alert("Scouting saved", isPresented: $didSave) {
            Button("Done", role: .cancel) {}
        } message: {
            Text("The season database and match notes were updated.")
        }
    }

    private var selectedTabSubtitle: String {
        switch selectedTab {
        case .teamInfo: "Identify the team and robot setup."
        case .autonomous: "Capture autonomous performance."
        case .teleOp: "Record driver-control performance and match context."
        case .endgame: "Finish with endgame scoring and drive-team notes."
        }
    }

    private func saveScoutingData() {
        guard let team = draft.team else {
            return
        }

        if let existingIndex = season.teams.firstIndex(where: { $0.id == team.id }) {
            season.teams[existingIndex] = team
        } else {
            season.teams.append(team)
        }

        let summary = draft.notes.isEmpty ? "Scouting data submitted for \(team.name)." : draft.notes
        season.matchNotes.insert(
            MatchNote(
                teamNumber: team.number,
                teamName: team.name,
                event: matchEvent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Unspecified match" : matchEvent,
                summary: summary,
                score: team.overallScore,
                date: .now
            ),
            at: 0
        )

        didSave = true
        syncScoutingData(team: team, note: season.matchNotes[0])
    }

    private func syncScoutingData(team: Team, note: MatchNote) {
        Task {
            do {
                try await Base44SyncClient().pushSeasonSnapshot(season)
                try await Base44SyncClient().pushTeam(team, seasonID: season.id)
                try await Base44SyncClient().pushMatchNote(note, seasonID: season.id)
            } catch {
                print("Base44 sync failed: \(error.localizedDescription)")
            }
        }
    }
}

private struct TeamDatabaseView: View {
    @Binding var season: Season
    @Binding var searchText: String
    @Binding var selectedTeamID: Int?
    @Binding var selectedComparisonTeamIDs: Set<Int>

    @State private var isPresentingTeamEditor = false
    @State private var editingDraft = TeamDraft()
    @State private var editingOriginalID: Int?

    private var filteredTeams: [Team] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSearch.isEmpty else {
            return season.teams.sorted { $0.number < $1.number }
        }

        return season.teams.filter { team in
            team.name.localizedCaseInsensitiveContains(trimmedSearch)
                || String(team.number).contains(trimmedSearch)
                || team.region.localizedCaseInsensitiveContains(trimmedSearch)
        }
        .sorted { $0.number < $1.number }
    }

    private var selectedTeam: Team? {
        season.teams.first { $0.id == selectedTeamID }
    }

    var body: some View {
        ScrollView {
            PageContainer {
                PageHeader(
                    title: "Teams",
                    subtitle: "Manage teams for \(season.displayName).",
                    symbolName: "person.3.sequence"
                ) {
                    Button("Add Team", systemImage: "plus") {
                        editingOriginalID = nil
                        editingDraft = TeamDraft()
                        isPresentingTeamEditor = true
                    }
                    .buttonStyle(.borderedProminent)
                }

                SearchField(text: $searchText, prompt: "Team number, name, or region")

                LazyVGrid(columns: adaptiveColumns(minimum: 360), spacing: 16) {
                    SectionCard(title: "Team Database", subtitle: "\(filteredTeams.count) teams match your search.") {
                        if filteredTeams.isEmpty {
                            EmptyStateView(symbolName: "person.crop.circle.badge.plus", title: "No teams yet", message: "Add your first team to begin scouting this season.")
                        } else {
                            VStack(spacing: 0) {
                                ForEach(filteredTeams) { team in
                                    TeamListRow(
                                        team: team,
                                        isSelected: selectedTeamID == team.id,
                                        isCompared: selectedComparisonTeamIDs.contains(team.id),
                                        onSelect: { selectedTeamID = team.id },
                                        onCompare: { toggleComparison(team.id) },
                                        onEdit: { edit(team) },
                                        onDelete: { delete(team) }
                                    )

                                    if team.id != filteredTeams.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }

                    TeamDetailPanel(team: selectedTeam)
                }
            }
        }
        .background(AppTheme.background)
        .sheet(isPresented: $isPresentingTeamEditor) {
            TeamEditorSheet(
                title: editingOriginalID == nil ? "Add Team" : "Edit Team",
                draft: $editingDraft,
                onCancel: { isPresentingTeamEditor = false },
                onSave: saveEditedTeam
            )
        }
    }

    private func toggleComparison(_ teamID: Int) {
        if selectedComparisonTeamIDs.contains(teamID) {
            selectedComparisonTeamIDs.remove(teamID)
        } else if selectedComparisonTeamIDs.count < 5 {
            selectedComparisonTeamIDs.insert(teamID)
        }
    }

    private func edit(_ team: Team) {
        editingOriginalID = team.id
        editingDraft = TeamDraft(team: team)
        isPresentingTeamEditor = true
    }

    private func saveEditedTeam() {
        guard let team = editingDraft.team else {
            return
        }

        if let originalID = editingOriginalID,
           let index = season.teams.firstIndex(where: { $0.id == originalID }) {
            season.teams[index] = team
            if selectedTeamID == originalID {
                selectedTeamID = team.id
            }
        } else if let existingIndex = season.teams.firstIndex(where: { $0.id == team.id }) {
            season.teams[existingIndex] = team
            selectedTeamID = team.id
        } else {
            season.teams.append(team)
            selectedTeamID = team.id
        }

        isPresentingTeamEditor = false
        syncTeamToBase44(team)
    }

    private func syncTeamToBase44(_ team: Team) {
        Task {
            do {
                try await Base44SyncClient().pushSeasonSnapshot(season)
                try await Base44SyncClient().pushTeam(team, seasonID: season.id)
            } catch {
                print("Base44 sync failed: \(error.localizedDescription)")
            }
        }
    }

    private func delete(_ team: Team) {
        season.teams.removeAll { $0.id == team.id }
        selectedComparisonTeamIDs.remove(team.id)

        if selectedTeamID == team.id {
            selectedTeamID = season.teams.first?.id
        }
    }
}

private struct MatchNotesView: View {
    @Binding var season: Season

    @State private var isAddingNote = false
    @State private var draft = NoteDraft()
    @State private var searchText = ""

    private var filteredNotes: [MatchNote] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSearch.isEmpty else {
            return season.matchNotes
        }

        return season.matchNotes.filter { note in
            note.teamName.localizedCaseInsensitiveContains(trimmedSearch)
                || String(note.teamNumber).contains(trimmedSearch)
                || note.summary.localizedCaseInsensitiveContains(trimmedSearch)
                || note.event.localizedCaseInsensitiveContains(trimmedSearch)
        }
    }

    var body: some View {
        ScrollView {
            PageContainer {
                PageHeader(
                    title: "Match Notes",
                    subtitle: "Keep observations for \(season.displayName).",
                    symbolName: "note.text"
                ) {
                    Button("Add Note", systemImage: "plus") {
                        draft = NoteDraft(teamNumber: String(season.teams.first?.number ?? 0), event: "", summary: "", score: 0)
                        isAddingNote = true
                    }
                    .buttonStyle(.borderedProminent)
                }

                SearchField(text: $searchText, prompt: "Search notes")

                if filteredNotes.isEmpty {
                    SectionCard(title: "Notes", subtitle: "No matching notes.") {
                        EmptyStateView(symbolName: "note.text", title: "No notes yet", message: "Add quick notes after matches so everyone has context.")
                    }
                } else {
                    VStack(spacing: 16) {
                        ForEach(filteredNotes) { note in
                            MatchNoteCard(note: note, onDelete: { delete(note) })
                        }
                    }
                }
            }
        }
        .background(AppTheme.background)
        .sheet(isPresented: $isAddingNote) {
            NoteEditorSheet(
                teams: season.teams,
                draft: $draft,
                onCancel: { isAddingNote = false },
                onSave: saveNote
            )
        }
    }

    private func saveNote() {
        guard let teamNumber = Int(draft.teamNumber) else {
            return
        }

        let teamName = season.teams.first { $0.number == teamNumber }?.name ?? "Team \(teamNumber)"
        let note = MatchNote(
            teamNumber: teamNumber,
            teamName: teamName,
            event: draft.event.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Unspecified match" : draft.event,
            summary: draft.summary.trimmingCharacters(in: .whitespacesAndNewlines),
            score: Int(draft.score),
            date: .now
        )
        season.matchNotes.insert(note, at: 0)
        isAddingNote = false
        syncNoteToBase44(note)
    }

    private func syncNoteToBase44(_ note: MatchNote) {
        Task {
            do {
                try await Base44SyncClient().pushSeasonSnapshot(season)
                try await Base44SyncClient().pushMatchNote(note, seasonID: season.id)
            } catch {
                print("Base44 sync failed: \(error.localizedDescription)")
            }
        }
    }

    private func delete(_ note: MatchNote) {
        season.matchNotes.removeAll { $0.id == note.id }
    }
}

private struct CompareTeamsView: View {
    let season: Season
    @Binding var selectedTeamIDs: Set<Int>

    private var selectedTeams: [Team] {
        season.teams
            .filter { selectedTeamIDs.contains($0.id) }
            .sorted { $0.overallScore > $1.overallScore }
    }

    var body: some View {
        ScrollView {
            PageContainer {
                PageHeader(
                    title: "Compare Teams",
                    subtitle: "Build an alliance short list for \(season.displayName).",
                    symbolName: "arrow.left.arrow.right"
                )

                SectionCard(title: "Selected Teams", subtitle: "Choose up to five teams for alliance planning.") {
                    if season.teams.isEmpty {
                        EmptyStateView(symbolName: "person.3.sequence", title: "No teams to compare", message: "Add teams first, then return here to compare them.")
                    } else {
                        FlowLayout(spacing: 8) {
                            ForEach(season.teams.sorted { $0.number < $1.number }) { team in
                                Button {
                                    toggle(team.id)
                                } label: {
                                    Label("\(team.number)", systemImage: selectedTeamIDs.contains(team.id) ? "checkmark.circle.fill" : "plus.circle")
                                }
                                .buttonStyle(.bordered)
                                .tint(selectedTeamIDs.contains(team.id) ? .blue : .secondary)
                                .disabled(!selectedTeamIDs.contains(team.id) && selectedTeamIDs.count >= 5)
                            }
                        }
                    }
                }

                if selectedTeams.isEmpty {
                    SectionCard(title: "Alliance Fit", subtitle: "No teams selected.") {
                        EmptyStateView(symbolName: "arrow.left.arrow.right", title: "Pick teams to compare", message: "Use the buttons above to build an alliance short list.")
                    }
                } else {
                    SectionCard(title: "Alliance Fit", subtitle: "Higher bars show stronger category performance.") {
                        VStack(spacing: 18) {
                            ForEach(selectedTeams) { team in
                                ComparisonRow(team: team)
                            }
                        }
                    }

                    SectionCard(title: "Suggested Captain's Notes", subtitle: "A concise planning snapshot.") {
                        VStack(alignment: .leading, spacing: 10) {
                            if let bestAuto = selectedTeams.max(by: { $0.autoScore < $1.autoScore }) {
                                InsightRow(symbolName: "bolt.fill", tint: .blue, text: "Best auto option: \(bestAuto.number) \(bestAuto.name)")
                            }
                            if let bestTeleOp = selectedTeams.max(by: { $0.teleOpScore < $1.teleOpScore }) {
                                InsightRow(symbolName: "gamecontroller.fill", tint: .green, text: "Best tele-op scorer: \(bestTeleOp.number) \(bestTeleOp.name)")
                            }
                            if let bestEndgame = selectedTeams.max(by: { $0.endgameScore < $1.endgameScore }) {
                                InsightRow(symbolName: "flag.checkered", tint: .orange, text: "Strongest endgame: \(bestEndgame.number) \(bestEndgame.name)")
                            }
                        }
                    }
                }
            }
        }
        .background(AppTheme.background)
    }

    private func toggle(_ teamID: Int) {
        if selectedTeamIDs.contains(teamID) {
            selectedTeamIDs.remove(teamID)
        } else if selectedTeamIDs.count < 5 {
            selectedTeamIDs.insert(teamID)
        }
    }
}

private struct AssistantView: View {
    let season: Season

    @State private var prompt = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, text: "Ask me to rank teams, summarize match notes, or suggest alliance strategy. I use your team backend when it is connected, so scouts never need API keys.")
    ]
    @State private var isSending = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                PageContainer {
                    PageHeader(
                        title: "AI Assistant",
                        subtitle: "Team-friendly scouting help for \(season.displayName).",
                        symbolName: "sparkles"
                    )

                    VStack(spacing: 14) {
                        ForEach(messages) { message in
                            ChatBubble(message: message)
                        }

                        if isSending {
                            ProgressView("Thinking...")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.subheadline)
                                .foregroundStyle(.red)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }

            Divider()

            HStack(spacing: 12) {
                TextField("Ask about teams, matches, or strategy", text: $prompt)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(send)

                Button("Send", systemImage: "paperplane.fill", action: send)
                    .buttonStyle(.borderedProminent)
                    .disabled(isSending || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(.regularMaterial)
        }
        .background(AppTheme.background)
    }

    private func send() {
        let cleanPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanPrompt.isEmpty, !isSending else {
            return
        }

        messages.append(ChatMessage(role: .user, text: cleanPrompt))
        prompt = ""
        errorMessage = nil
        isSending = true

        Task {
            do {
                let response = try await ScoutingAIClient().send(
                    prompt: cleanPrompt,
                    season: season
                )
                await MainActor.run {
                    messages.append(ChatMessage(role: .assistant, text: response))
                    isSending = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSending = false
                }
            }
        }
    }
}

private struct ScoutingAIClient {
    @MainActor
    func send(prompt: String, season: Season) async throws -> String {
        do {
            return try await Base44SyncClient().askAssistant(prompt: prompt, season: season)
        } catch Base44SyncError.notConfigured {
            return LocalScoutingAssistant().answer(prompt: prompt, season: season)
        }
    }
}

private struct LocalScoutingAssistant {
    func answer(prompt: String, season: Season) -> String {
        let topTeams = season.teams
            .sorted { $0.overallScore > $1.overallScore }
            .prefix(3)
            .map { "#\($0.number) \($0.name) (\($0.overallScore) pts)" }
            .joined(separator: ", ")

        let noteSummary = season.matchNotes.isEmpty
            ? "No match notes have been recorded yet."
            : "\(season.matchNotes.count) match notes are available, with an average recorded score of \(averageScore(in: season.matchNotes))."

        let teamSummary = season.teams.isEmpty
            ? "No teams have been scouted yet."
            : "Top teams by scouting score: \(topTeams)."

        return """
        Backend AI is not connected yet, so here is a data-based scouting summary from this device.

        \(teamSummary)
        \(noteSummary)

        Once your Base44 AI endpoint is added, this same question will be answered by the shared team AI automatically with no API keys or login on scout devices.
        """
    }

    private func averageScore(in notes: [MatchNote]) -> Int {
        guard !notes.isEmpty else {
            return 0
        }

        return notes.map(\.score).reduce(0, +) / notes.count
    }
}

private struct Base44SyncClient {
    // Add the Base44 backend function URL here once your site endpoint is ready.
    private static let baseURL = ""
    private static let apiToken = ""

    func pushSeasonSnapshot(_ season: Season) async throws {
        try await post(SeasonSyncPayload(season: season), path: "seasons")
    }

    func pushTeam(_ team: Team, seasonID: UUID) async throws {
        try await post(TeamSyncPayload(team: team, seasonID: seasonID), path: "teams")
    }

    func pushMatchNote(_ note: MatchNote, seasonID: UUID) async throws {
        try await post(MatchNoteSyncPayload(note: note, seasonID: seasonID), path: "match-notes")
    }

    @MainActor
    func askAssistant(prompt: String, season: Season) async throws -> String {
        let response: AssistantSyncResponse = try await postForResponse(
            AssistantSyncRequest(prompt: prompt, season: AssistantSeasonContext(season: season)),
            path: "assistant"
        )

        guard let text = response.bestText, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Base44SyncError.emptyResponse
        }

        return text
    }

    private func post<Payload: Encodable>(_ payload: Payload, path: String) async throws {
        let trimmedBaseURL = Self.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBaseURL.isEmpty else {
            return
        }

        guard let url = URL(string: trimmedBaseURL)?.appendingPathComponent(path) else {
            throw Base44SyncError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let trimmedToken = Self.apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedToken.isEmpty {
            request.setValue("Bearer \(trimmedToken)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONEncoder.base44.encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Base44SyncError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "No response body"
            throw Base44SyncError.serverError("Base44 sync failed (\(httpResponse.statusCode)): \(body)")
        }
    }

    private func postForResponse<Payload: Encodable, Response: Decodable>(_ payload: Payload, path: String) async throws -> Response {
        let trimmedBaseURL = Self.baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBaseURL.isEmpty else {
            throw Base44SyncError.notConfigured
        }

        guard let url = URL(string: trimmedBaseURL)?.appendingPathComponent(path) else {
            throw Base44SyncError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let trimmedToken = Self.apiToken.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedToken.isEmpty {
            request.setValue("Bearer \(trimmedToken)", forHTTPHeaderField: "Authorization")
        }

        request.httpBody = try JSONEncoder.base44.encode(payload)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Base44SyncError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "No response body"
            throw Base44SyncError.serverError("Base44 request failed (\(httpResponse.statusCode)): \(body)")
        }

        return try JSONDecoder().decode(Response.self, from: data)
    }
}

private struct AssistantSyncRequest: Encodable {
    let prompt: String
    let season: AssistantSeasonContext
}

private struct AssistantSeasonContext: Encodable {
    let id: UUID
    let name: String
    let gameName: String
    let year: String
    let teams: [AssistantTeamContext]
    let matchNotes: [AssistantMatchNoteContext]

    @MainActor
    init(season: Season) {
        id = season.id
        name = season.displayName
        gameName = season.gameName
        year = season.year
        teams = season.teams.map(AssistantTeamContext.init)
        matchNotes = season.matchNotes.map(AssistantMatchNoteContext.init)
    }
}

private struct AssistantTeamContext: Encodable {
    let number: Int
    let name: String
    let region: String
    let driveTrain: String
    let autoScore: Int
    let teleOpScore: Int
    let endgameScore: Int
    let overallScore: Int
    let notes: String

    @MainActor
    init(team: Team) {
        number = team.number
        name = team.name
        region = team.region
        driveTrain = team.driveTrain
        autoScore = team.autoScore
        teleOpScore = team.teleOpScore
        endgameScore = team.endgameScore
        overallScore = team.overallScore
        notes = team.notes
    }
}

private struct AssistantMatchNoteContext: Encodable {
    let teamNumber: Int
    let teamName: String
    let event: String
    let summary: String
    let score: Int
    let date: Date

    @MainActor
    init(note: MatchNote) {
        teamNumber = note.teamNumber
        teamName = note.teamName
        event = note.event
        summary = note.summary
        score = note.score
        date = note.date
    }
}

private struct AssistantSyncResponse: Decodable {
    let answer: String?
    let text: String?
    let response: String?

    var bestText: String? {
        answer ?? text ?? response
    }
}

private struct SeasonSyncPayload: Encodable {
    let id: UUID
    let name: String
    let gameName: String
    let year: String
    let teamCount: Int
    let noteCount: Int
    let updatedAt: Date

    init(season: Season) {
        id = season.id
        name = season.displayName
        gameName = season.gameName
        year = season.year
        teamCount = season.teams.count
        noteCount = season.matchNotes.count
        updatedAt = .now
    }
}

private struct TeamSyncPayload: Encodable {
    let seasonID: UUID
    let number: Int
    let name: String
    let region: String
    let driveTrain: String
    let autoScore: Int
    let teleOpScore: Int
    let endgameScore: Int
    let overallScore: Int
    let lastSeen: String
    let notes: String
    let updatedAt: Date

    init(team: Team, seasonID: UUID) {
        self.seasonID = seasonID
        number = team.number
        name = team.name
        region = team.region
        driveTrain = team.driveTrain
        autoScore = team.autoScore
        teleOpScore = team.teleOpScore
        endgameScore = team.endgameScore
        overallScore = team.overallScore
        lastSeen = team.lastSeen
        notes = team.notes
        updatedAt = .now
    }
}

private struct MatchNoteSyncPayload: Encodable {
    let id: UUID
    let seasonID: UUID
    let teamNumber: Int
    let teamName: String
    let event: String
    let summary: String
    let score: Int
    let date: Date
    let updatedAt: Date

    init(note: MatchNote, seasonID: UUID) {
        id = note.id
        self.seasonID = seasonID
        teamNumber = note.teamNumber
        teamName = note.teamName
        event = note.event
        summary = note.summary
        score = note.score
        date = note.date
        updatedAt = .now
    }
}

private enum Base44SyncError: LocalizedError {
    case invalidURL
    case invalidResponse
    case notConfigured
    case emptyResponse
    case serverError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            "The Base44 sync URL is invalid."
        case .invalidResponse:
            "Base44 returned an invalid response."
        case .notConfigured:
            "Base44 is not connected yet."
        case .emptyResponse:
            "Base44 returned an empty answer."
        case .serverError(let message):
            message
        }
    }
}

private extension JSONEncoder {
    static var base44: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private struct PageContainer<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            content()
        }
        .frame(maxWidth: 1120, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.vertical, 28)
    }
}

private struct PageHeader<Trailing: View>: View {
    let title: String
    let subtitle: String
    let symbolName: String
    @ViewBuilder let trailing: () -> Trailing

    init(
        title: String,
        subtitle: String,
        symbolName: String,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.symbolName = symbolName
        self.trailing = trailing
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 16) {
                headerText
                Spacer(minLength: 16)
                trailing()
            }

            VStack(alignment: .leading, spacing: 16) {
                headerText
                trailing()
            }
        }
    }

    private var headerText: some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: symbolName)
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct SectionCard<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.bold())
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            content()
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        }
    }
}

private struct HeroCard: View {
    let team: Team

    var body: some View {
        HStack(alignment: .center, spacing: 18) {
            NumberBadge(number: team.number)

            VStack(alignment: .leading, spacing: 6) {
                Text("Current top alliance signal")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(team.name)
                    .font(.title2.bold())
                Text(team.notes.isEmpty ? "No notes yet." : team.notes)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(team.overallScore)")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .monospacedDigit()
                Text("overall")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
        .background(.blue.opacity(0.12), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.blue.opacity(0.22), lineWidth: 1)
        }
    }
}

private struct MetricCard: View {
    let title: String
    let value: String
    let symbolName: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: symbolName)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .accessibilityHidden(true)
                Spacer()
            }

            Text(value)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .monospacedDigit()
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.background, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        }
    }
}

private struct TeamRankRow: View {
    let team: Team

    var body: some View {
        HStack(spacing: 14) {
            NumberBadge(number: team.number)

            VStack(alignment: .leading, spacing: 4) {
                Text(team.name)
                    .font(.headline)
                Text("\(team.region) - \(team.driveTrain)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(team.overallScore)")
                .font(.title3.bold())
                .monospacedDigit()
        }
        .accessibilityElement(children: .combine)
    }
}

private struct NoteSummaryRow: View {
    let note: MatchNote

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "quote.bubble.fill")
                .foregroundStyle(.indigo)
                .frame(width: 34, height: 34)
                .background(.indigo.opacity(0.12), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(note.teamNumber) - \(note.teamName)")
                    .font(.headline)
                Text(note.summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct TeamInfoForm: View {
    @Binding var draft: TeamDraft

    var body: some View {
        LazyVGrid(columns: adaptiveColumns(minimum: 260), spacing: 16) {
            LabeledContentView(title: "Team Number") {
                TextField("11212", text: $draft.number)
            }
            LabeledContentView(title: "Team Name") {
                TextField("The Claws", text: $draft.name)
            }
            LabeledContentView(title: "Region") {
                TextField("NorCal", text: $draft.region)
            }
            LabeledContentView(title: "Drive Train") {
                Picker("Drive Train", selection: $draft.driveTrain) {
                    Text("Mecanum").tag("Mecanum")
                    Text("Swerve").tag("Swerve")
                    Text("Tank").tag("Tank")
                    Text("Other").tag("Other")
                }
                .labelsHidden()
            }
        }
    }
}

private struct EndgameForm: View {
    @Binding var score: Double
    @Binding var notes: String

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            ScoreStepper(title: "Endgame score", value: $score, range: 0...15, tint: .orange)

            LabeledContentView(title: "Drive Team Notes") {
                TextField("Anything the drive team should know", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
    }
}

private struct LabeledContentView<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
            content()
                .textFieldStyle(.roundedBorder)
        }
    }
}

private struct ScoreStepper: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Stepper(value: $value, in: range, step: 1) {
                HStack {
                    Text(title)
                    Spacer()
                    Text(value.formatted(.number.precision(.fractionLength(0))))
                        .font(.headline.monospacedDigit())
                }
            }

            ProgressView(value: value, total: range.upperBound)
                .tint(tint)
        }
    }
}

private struct ScoutingSummary: View {
    let draft: TeamDraft

    var body: some View {
        LazyVGrid(columns: adaptiveColumns(minimum: 160), spacing: 12) {
            SummaryTile(title: "Team", value: draft.number.isEmpty ? "Missing" : draft.number, tint: .blue)
            SummaryTile(title: "Auto", value: draft.autoScore.formatted(.number.precision(.fractionLength(0))), tint: .blue)
            SummaryTile(title: "Tele-Op", value: draft.teleOpScore.formatted(.number.precision(.fractionLength(0))), tint: .green)
            SummaryTile(title: "Endgame", value: draft.endgameScore.formatted(.number.precision(.fractionLength(0))), tint: .orange)
        }
    }
}

private struct SummaryTile: View {
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(tint)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct TeamEditorSheet: View {
    let title: String
    @Binding var draft: TeamDraft
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Team Number", text: $draft.number)
                    TextField("Team Name", text: $draft.name)
                    TextField("Region", text: $draft.region)
                    Picker("Drive Train", selection: $draft.driveTrain) {
                        Text("Mecanum").tag("Mecanum")
                        Text("Swerve").tag("Swerve")
                        Text("Tank").tag("Tank")
                        Text("Other").tag("Other")
                    }
                }

                Section("Scores") {
                    ScoreStepper(title: "Auto", value: $draft.autoScore, range: 0...20, tint: .blue)
                    ScoreStepper(title: "Tele-Op", value: $draft.teleOpScore, range: 0...30, tint: .green)
                    ScoreStepper(title: "Endgame", value: $draft.endgameScore, range: 0...15, tint: .orange)
                }

                Section("Notes") {
                    TextField("Strengths, weaknesses, or strategy notes", text: $draft.notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .disabled(!draft.canSave)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct NoteEditorSheet: View {
    let teams: [Team]
    @Binding var draft: NoteDraft
    let onCancel: () -> Void
    let onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Match") {
                    if teams.isEmpty {
                        TextField("Team Number", text: $draft.teamNumber)
                    } else {
                        Picker("Team", selection: $draft.teamNumber) {
                            ForEach(teams.sorted { $0.number < $1.number }) { team in
                                Text("\(team.number) - \(team.name)").tag(String(team.number))
                            }
                        }
                    }
                    TextField("Event", text: $draft.event)
                    Slider(value: $draft.score, in: 0...70, step: 1) {
                        Text("Score")
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("70")
                    }
                    Text("Score: \(Int(draft.score))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Observation") {
                    TextField("What happened in this match?", text: $draft.summary, axis: .vertical)
                        .lineLimit(4...8)
                }
            }
            .navigationTitle("Add Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                        .disabled(!draft.canSave)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

private struct TeamDetailPanel: View {
    let team: Team?

    var body: some View {
        SectionCard(title: "Team Details", subtitle: team == nil ? "Select a team to inspect." : "Strengths and scouting notes.") {
            if let team {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 14) {
                        NumberBadge(number: team.number)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(team.name)
                                .font(.title3.bold())
                            Text("\(team.region) - \(team.driveTrain)")
                                .foregroundStyle(.secondary)
                        }
                    }

                    ScoreBar(label: "Auto", value: team.autoScore, maximum: 20, tint: .blue)
                    ScoreBar(label: "Tele-Op", value: team.teleOpScore, maximum: 30, tint: .green)
                    ScoreBar(label: "Endgame", value: team.endgameScore, maximum: 15, tint: .orange)

                    Divider()

                    Text(team.notes.isEmpty ? "No notes yet." : team.notes)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            } else {
                EmptyStateView(symbolName: "person.crop.circle.badge.questionmark", title: "No team selected", message: "Choose a team from the list to view its scouting profile.")
            }
        }
    }
}

private struct SearchField: View {
    @Binding var text: String
    let prompt: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
            if !text.isEmpty {
                Button("Clear", systemImage: "xmark.circle.fill") {
                    text = ""
                }
                .labelStyle(.iconOnly)
                .foregroundStyle(.secondary)
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(.background, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.quaternary, lineWidth: 1)
        }
    }
}

private struct TeamListRow: View {
    let team: Team
    let isSelected: Bool
    let isCompared: Bool
    let onSelect: () -> Void
    let onCompare: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onSelect) {
                HStack(spacing: 14) {
                    NumberBadge(number: team.number)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(team.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        HStack {
                            Label(team.region, systemImage: "mappin.and.ellipse")
                            Label(team.driveTrain, systemImage: "gearshape.2")
                            Label(team.lastSeen, systemImage: "clock")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(team.overallScore)")
                    .font(.title3.bold())
                    .monospacedDigit()
                Text("Score")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Button("Compare", systemImage: isCompared ? "checkmark.circle.fill" : "plus.circle", action: onCompare)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .tint(isCompared ? .blue : .secondary)
                .accessibilityLabel(isCompared ? "Remove from comparison" : "Add to comparison")

            Button("Edit", systemImage: "pencil", action: onEdit)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)

            Button("Delete", systemImage: "trash", action: onDelete)
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
                .tint(.red)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(isSelected ? Color.accentColor.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct MatchNoteCard: View {
    let note: MatchNote
    let onDelete: () -> Void

    var body: some View {
        SectionCard(title: "\(note.teamNumber) - \(note.teamName)", subtitle: note.event) {
            Text(note.summary)
                .font(.body)
                .foregroundStyle(.secondary)

            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                    Text(note.date.formatted(.dateTime.month().day()))
                }
                Spacer()
                Label("\(note.score) points", systemImage: "sum")
                Button("Delete", systemImage: "trash", action: onDelete)
                    .labelStyle(.iconOnly)
                    .buttonStyle(.borderless)
                    .tint(.red)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
    }
}

private struct ComparisonRow: View {
    let team: Team

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(team.number) - \(team.name)")
                    .font(.headline)
                Spacer()
                Text("\(team.overallScore)")
                    .font(.headline.monospacedDigit())
            }

            ScoreBar(label: "Auto", value: team.autoScore, maximum: 20, tint: .blue)
            ScoreBar(label: "Tele-Op", value: team.teleOpScore, maximum: 30, tint: .green)
            ScoreBar(label: "Endgame", value: team.endgameScore, maximum: 15, tint: .orange)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct ScoreBar: View {
    let label: String
    let value: Int
    let maximum: Int
    let tint: Color

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 0) {
            GridRow {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 62, alignment: .leading)

                ProgressView(value: Double(value), total: Double(maximum))
                    .tint(tint)

                Text("\(value)")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 28, alignment: .trailing)
            }
        }
    }
}

private struct NumberBadge: View {
    let number: Int

    var body: some View {
        Text("\(number)")
            .font(.headline.monospacedDigit())
            .foregroundStyle(.white)
            .minimumScaleFactor(0.7)
            .lineLimit(1)
            .frame(width: 64, height: 48)
            .background(.blue.gradient, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct InsightRow: View {
    let symbolName: String
    let tint: Color
    let text: String

    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: symbolName)
                .foregroundStyle(tint)
        }
        .font(.body)
    }
}

private struct EmptyStateView: View {
    let symbolName: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbolName)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
}

private struct ChatMessage: Identifiable, Hashable {
    enum Role {
        case user
        case assistant
    }

    let id = UUID()
    let role: Role
    let text: String
}

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.role == .user {
                Spacer(minLength: 40)
            }

            Text(message.text)
                .font(.body)
                .padding(14)
                .foregroundStyle(message.role == .user ? .white : .primary)
                .background(message.role == .user ? Color.accentColor : Color.secondary.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            if message.role == .assistant {
                Spacer(minLength: 40)
            }
        }
    }
}

private struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    @ViewBuilder let content: () -> Content

    init(spacing: CGFloat, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.content = content
    }

    var body: some View {
        LazyVGrid(columns: adaptiveColumns(minimum: 96), alignment: .leading, spacing: spacing) {
            content()
        }
    }
}

private enum AppTheme {
    static var background: Color {
        #if os(iOS)
        Color(uiColor: .systemGroupedBackground)
        #elseif os(macOS)
        Color(nsColor: .windowBackgroundColor)
        #else
        Color(.systemBackground)
        #endif
    }
}

private func adaptiveColumns(minimum: CGFloat) -> [GridItem] {
    [GridItem(.adaptive(minimum: minimum), spacing: 16)]
}

#Preview {
    ContentView()
}
