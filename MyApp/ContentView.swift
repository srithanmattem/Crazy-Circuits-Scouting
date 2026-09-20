import SwiftUI

struct ContentView: View {
    @State private var selectedSection: AppSection? = .dashboard
    @State private var searchText = ""
    @State private var teams = SampleData.teams
    @State private var matchNotes = SampleData.matchNotes
    @State private var selectedTeamID: Int? = 731
    @State private var selectedComparisonTeamIDs: Set<Int> = [731, 5795, 7105]

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selectedSection)
        } detail: {
            content
                .navigationTitle(selectedSection?.title ?? "Circuit Scout")
        }
    }

    @ViewBuilder
    private var content: some View {
        switch selectedSection ?? .dashboard {
        case .dashboard:
            DashboardView(
                teams: teams,
                notes: matchNotes,
                onStartScouting: { selectedSection = .scout },
                onCompare: { selectedSection = .compare }
            )
        case .scout:
            ScoutInputView(teams: $teams, notes: $matchNotes)
        case .teams:
            TeamDatabaseView(
                teams: $teams,
                searchText: $searchText,
                selectedTeamID: $selectedTeamID,
                selectedComparisonTeamIDs: $selectedComparisonTeamIDs
            )
        case .matches:
            MatchNotesView(teams: teams, notes: $matchNotes)
        case .compare:
            CompareTeamsView(teams: teams, selectedTeamIDs: $selectedComparisonTeamIDs)
        case .assistant:
            AssistantView(teams: teams, notes: matchNotes)
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
        case .assistant: "Assistant"
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
    var autoScore = 8.0
    var teleOpScore = 18.0
    var endgameScore = 8.0
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
    var teamNumber = "731"
    var event = "Qualifier"
    var summary = ""
    var score = 30.0

    var canSave: Bool {
        Int(teamNumber) != nil
            && !event.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

private enum SampleData {
    static let teams: [Team] = [
        Team(number: 731, name: "Wannabee Strange", region: "NorCal", driveTrain: "Mecanum", autoScore: 12, teleOpScore: 22, endgameScore: 8, lastSeen: "Today", notes: "Reliable park and quick reset after defense."),
        Team(number: 5795, name: "Back To The Drawing Board", region: "Georgia", driveTrain: "Swerve", autoScore: 10, teleOpScore: 25, endgameScore: 7, lastSeen: "Yesterday", notes: "Great driver control. Watch intake consistency."),
        Team(number: 6078, name: "Cut the Red Wire", region: "Texas", driveTrain: "Tank", autoScore: 9, teleOpScore: 19, endgameScore: 11, lastSeen: "Sep 18", notes: "Strong endgame decision-making."),
        Team(number: 7083, name: "TundraBots", region: "Minnesota", driveTrain: "Mecanum", autoScore: 14, teleOpScore: 18, endgameScore: 10, lastSeen: "Sep 17", notes: "Best autonomous sample path in the group."),
        Team(number: 7105, name: "SWIFT Intergalactic Space Llamas", region: "Washington", driveTrain: "Swerve", autoScore: 11, teleOpScore: 21, endgameScore: 12, lastSeen: "Sep 15", notes: "Flexible strategy, comfortable filling gaps.")
    ]

    static let matchNotes: [MatchNote] = [
        MatchNote(teamNumber: 731, teamName: "Wannabee Strange", event: "Qualifier 12", summary: "Consistent cycles, fast reset after defense, reliable parking.", score: 42, date: .now),
        MatchNote(teamNumber: 5795, teamName: "Back To The Drawing Board", event: "Qualifier 16", summary: "Strong tele-op driver control with occasional intake jams.", score: 44, date: .now.addingTimeInterval(-86_400)),
        MatchNote(teamNumber: 6078, teamName: "Cut the Red Wire", event: "Qualifier 18", summary: "Best autonomous path so far, needs a cleaner endgame approach.", score: 39, date: .now.addingTimeInterval(-172_800))
    ]
}

private struct SidebarView: View {
    @Binding var selection: AppSection?

    var body: some View {
        List(AppSection.allCases, selection: $selection) { section in
            NavigationLink(value: section) {
                Label(section.title, systemImage: section.symbolName)
            }
        }
        .navigationTitle("Circuit Scout")
        .safeAreaInset(edge: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Season")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Decode 2025-26")
                    .font(.headline)
                Label("Ready to scout", systemImage: "checkmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.green)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.thinMaterial)
        }
    }
}

private struct DashboardView: View {
    let teams: [Team]
    let notes: [MatchNote]
    let onStartScouting: () -> Void
    let onCompare: () -> Void

    private var sortedTeams: [Team] {
        teams.sorted { $0.overallScore > $1.overallScore }
    }

    var body: some View {
        ScrollView {
            PageContainer {
                PageHeader(
                    title: "Dashboard",
                    subtitle: "A calm command center for your next match.",
                    symbolName: "chart.bar.xaxis"
                ) {
                    HStack {
                        Button("Scout", systemImage: "square.and.pencil", action: onStartScouting)
                            .buttonStyle(.borderedProminent)
                        Button("Compare", systemImage: "arrow.left.arrow.right", action: onCompare)
                            .buttonStyle(.bordered)
                    }
                }

                LazyVGrid(columns: adaptiveColumns(minimum: 210), spacing: 16) {
                    MetricCard(title: "Teams Scouted", value: "\(teams.count)", symbolName: "person.3.fill", tint: .blue)
                    MetricCard(title: "Match Notes", value: "\(notes.count)", symbolName: "note.text", tint: .orange)
                    MetricCard(title: "Top Score", value: "\(sortedTeams.first?.overallScore ?? 0)", symbolName: "trophy.fill", tint: .yellow)
                    MetricCard(title: "Regions", value: "\(Set(teams.map(\.region)).count)", symbolName: "map.fill", tint: .green)
                }

                if let topTeam = sortedTeams.first {
                    HeroCard(team: topTeam)
                }

                LazyVGrid(columns: adaptiveColumns(minimum: 320), spacing: 16) {
                    SectionCard(title: "Top Teams", subtitle: "Ranked by combined auto, tele-op, and endgame performance.") {
                        VStack(spacing: 12) {
                            ForEach(Array(sortedTeams.prefix(4))) { team in
                                TeamRankRow(team: team)
                            }
                        }
                    }

                    SectionCard(title: "Recent Notes", subtitle: "Fast context for drive team conversations.") {
                        if notes.isEmpty {
                            EmptyStateView(symbolName: "note.text", title: "No notes yet", message: "Add notes after each match to build useful history.")
                        } else {
                            VStack(spacing: 12) {
                                ForEach(notes.prefix(3)) { note in
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
    @Binding var teams: [Team]
    @Binding var notes: [MatchNote]

    @State private var selectedTab: ScoutingTab = .teamInfo
    @State private var draft = TeamDraft(team: SampleData.teams[0])
    @State private var matchEvent = "Qualifier"
    @State private var didSave = false

    var body: some View {
        ScrollView {
            PageContainer {
                PageHeader(
                    title: "Scout a Team",
                    subtitle: "Work through one focused step at a time.",
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
            Text("The team database and match notes were updated.")
        }
    }

    private var selectedTabSubtitle: String {
        switch selectedTab {
        case .teamInfo: "Identify the team and robot setup."
        case .autonomous: "Capture autonomous reliability without extra clutter."
        case .teleOp: "Record driver-control performance and match context."
        case .endgame: "Finish with endgame scoring and drive-team notes."
        }
    }

    private func saveScoutingData() {
        guard let team = draft.team else {
            return
        }

        if let existingIndex = teams.firstIndex(where: { $0.id == team.id }) {
            teams[existingIndex] = team
        } else {
            teams.append(team)
        }

        let summary = draft.notes.isEmpty ? "Scouting data submitted for \(team.name)." : draft.notes
        notes.insert(
            MatchNote(
                teamNumber: team.number,
                teamName: team.name,
                event: matchEvent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Practice" : matchEvent,
                summary: summary,
                score: team.overallScore,
                date: .now
            ),
            at: 0
        )

        didSave = true
    }
}

private struct TeamDatabaseView: View {
    @Binding var teams: [Team]
    @Binding var searchText: String
    @Binding var selectedTeamID: Int?
    @Binding var selectedComparisonTeamIDs: Set<Int>

    @State private var isPresentingTeamEditor = false
    @State private var editingDraft = TeamDraft()
    @State private var editingOriginalID: Int?

    private var filteredTeams: [Team] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSearch.isEmpty else {
            return teams.sorted { $0.number < $1.number }
        }

        return teams.filter { team in
            team.name.localizedCaseInsensitiveContains(trimmedSearch)
                || String(team.number).contains(trimmedSearch)
                || team.region.localizedCaseInsensitiveContains(trimmedSearch)
        }
        .sorted { $0.number < $1.number }
    }

    private var selectedTeam: Team? {
        teams.first { $0.id == selectedTeamID }
    }

    var body: some View {
        ScrollView {
            PageContainer {
                PageHeader(
                    title: "Teams",
                    subtitle: "Search, edit, and prepare comparison lists.",
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
                            EmptyStateView(symbolName: "magnifyingglass", title: "No teams found", message: "Try a different search or add a new team.")
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
           let index = teams.firstIndex(where: { $0.id == originalID }) {
            teams[index] = team
            if selectedTeamID == originalID {
                selectedTeamID = team.id
            }
        } else if let existingIndex = teams.firstIndex(where: { $0.id == team.id }) {
            teams[existingIndex] = team
            selectedTeamID = team.id
        } else {
            teams.append(team)
            selectedTeamID = team.id
        }

        isPresentingTeamEditor = false
    }

    private func delete(_ team: Team) {
        teams.removeAll { $0.id == team.id }
        selectedComparisonTeamIDs.remove(team.id)

        if selectedTeamID == team.id {
            selectedTeamID = teams.first?.id
        }
    }
}

private struct MatchNotesView: View {
    let teams: [Team]
    @Binding var notes: [MatchNote]

    @State private var isAddingNote = false
    @State private var draft = NoteDraft()
    @State private var searchText = ""

    private var filteredNotes: [MatchNote] {
        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedSearch.isEmpty else {
            return notes
        }

        return notes.filter { note in
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
                    subtitle: "Keep short observations easy to review.",
                    symbolName: "note.text"
                ) {
                    Button("Add Note", systemImage: "plus") {
                        draft = NoteDraft(teamNumber: String(teams.first?.number ?? 731), event: "Qualifier", summary: "", score: 30)
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
                teams: teams,
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

        let teamName = teams.first { $0.number == teamNumber }?.name ?? "Team \(teamNumber)"
        notes.insert(
            MatchNote(
                teamNumber: teamNumber,
                teamName: teamName,
                event: draft.event.trimmingCharacters(in: .whitespacesAndNewlines),
                summary: draft.summary.trimmingCharacters(in: .whitespacesAndNewlines),
                score: Int(draft.score),
                date: .now
            ),
            at: 0
        )
        isAddingNote = false
    }

    private func delete(_ note: MatchNote) {
        notes.removeAll { $0.id == note.id }
    }
}

private struct CompareTeamsView: View {
    let teams: [Team]
    @Binding var selectedTeamIDs: Set<Int>

    private var selectedTeams: [Team] {
        teams
            .filter { selectedTeamIDs.contains($0.id) }
            .sorted { $0.overallScore > $1.overallScore }
    }

    var body: some View {
        ScrollView {
            PageContainer {
                PageHeader(
                    title: "Compare Teams",
                    subtitle: "Build a short list and compare strengths side by side.",
                    symbolName: "arrow.left.arrow.right"
                )

                SectionCard(title: "Selected Teams", subtitle: "Choose up to five teams for alliance planning.") {
                    FlowLayout(spacing: 8) {
                        ForEach(teams.sorted { $0.number < $1.number }) { team in
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
    let teams: [Team]
    let notes: [MatchNote]

    @State private var prompt = ""
    @State private var messages: [ChatMessage] = [
        ChatMessage(role: .assistant, text: "Ask me for the best overall team, strongest auto robot, best tele-op scorer, or a quick match-note summary.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                PageContainer {
                    PageHeader(
                        title: "Scouting Assistant",
                        subtitle: "Quick answers from the data already in the app.",
                        symbolName: "sparkles"
                    )

                    VStack(spacing: 14) {
                        ForEach(messages) { message in
                            ChatBubble(message: message)
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
                    .disabled(prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(.regularMaterial)
        }
        .background(AppTheme.background)
    }

    private func send() {
        let cleanPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanPrompt.isEmpty else {
            return
        }

        messages.append(ChatMessage(role: .user, text: cleanPrompt))
        messages.append(ChatMessage(role: .assistant, text: response(for: cleanPrompt)))
        prompt = ""
    }

    private func response(for prompt: String) -> String {
        let lowercased = prompt.lowercased()

        if lowercased.contains("auto"), let team = teams.max(by: { $0.autoScore < $1.autoScore }) {
            return "For autonomous, start with \(team.number) \(team.name). They have the strongest auto score at \(team.autoScore)."
        }

        if lowercased.contains("tele") || lowercased.contains("cycle"), let team = teams.max(by: { $0.teleOpScore < $1.teleOpScore }) {
            return "For tele-op scoring, \(team.number) \(team.name) is the best current signal with a tele-op score of \(team.teleOpScore)."
        }

        if lowercased.contains("end") || lowercased.contains("park"), let team = teams.max(by: { $0.endgameScore < $1.endgameScore }) {
            return "For endgame, \(team.number) \(team.name) looks strongest with an endgame score of \(team.endgameScore)."
        }

        if lowercased.contains("note") || lowercased.contains("summary") {
            let latest = notes.prefix(3).map { "\($0.teamNumber): \($0.summary)" }.joined(separator: "\n")
            return latest.isEmpty ? "No match notes have been added yet." : latest
        }

        if let team = teams.max(by: { $0.overallScore < $1.overallScore }) {
            return "Best overall right now is \(team.number) \(team.name) with \(team.overallScore) total points. Their key note: \(team.notes.isEmpty ? "add more scouting notes next match." : team.notes)"
        }

        return "Add teams and match notes first, then I can help rank and compare them."
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
                Text(team.notes)
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
                    Picker("Team", selection: $draft.teamNumber) {
                        ForEach(teams.sorted { $0.number < $1.number }) { team in
                            Text("\(team.number) - \(team.name)").tag(String(team.number))
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
