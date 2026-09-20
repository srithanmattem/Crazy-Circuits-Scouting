# Developer Guide

This guide explains the current implementation and where to extend it.

## Architecture

The app is implemented in SwiftUI with local `@State` in `ContentView`.

Current core types:

| Type | Purpose |
| --- | --- |
| `ContentView` | Owns app navigation and top-level state |
| `AppSection` | Sidebar destinations |
| `ScoutingTab` | Steps in the scouting form |
| `Season` | Active season metadata, teams, and notes |
| `Team` | Scouted team model |
| `MatchNote` | Match observation model |
| `TeamDraft` | Editable team form state |
| `NoteDraft` | Editable note form state |
| `Base44SyncClient` | Automatic sync and assistant backend client |
| `ScoutingAIClient` | Assistant coordinator with Base44-first behavior |

The UI is split into small SwiftUI views:

- `DashboardView`
- `ScoutInputView`
- `TeamDatabaseView`
- `MatchNotesView`
- `CompareTeamsView`
- `AssistantView`
- Shared components such as `SectionCard`, `MetricCard`, `ScoreBar`, and `SearchField`

## State Flow

`ContentView` owns:

- `seasons`
- `activeSeasonID`
- `selectedSection`
- `selectedTeamID`
- `selectedComparisonTeamIDs`

Child views receive bindings when they need to mutate data:

- `SidebarView` creates, switches, renames, and deletes seasons
- `ScoutInputView` updates teams and notes inside the active season
- `TeamDatabaseView` adds, edits, deletes, and selects teams inside the active season
- `MatchNotesView` adds and deletes notes inside the active season
- `CompareTeamsView` edits the comparison selection for the active season

## Adding Persistence

The current app uses in-memory data. Good next options:

| Option | When To Use |
| --- | --- |
| SwiftData | Best for local app storage with model objects |
| Core Data | Best for older targets or advanced storage needs |
| Document-based storage | Best for sharing scouting files between devices |
| Cloud backend | Best for multi-device team syncing |

When adding persistence, keep `ContentView` as the navigation owner and move data operations into a model or store type.

## Base44 Sync

`Base44SyncClient` is the single connection point for the website backend.

Configured paths:

- `POST /seasons`
- `POST /teams`
- `POST /match-notes`
- `POST /assistant`

The `baseURL` constant is intentionally blank until the Base44 endpoint is ready. With a blank URL, sync calls skip quietly and the assistant uses a local data-based response.

## Suggested Next Model Layer

Create a dedicated store such as:

```swift
@Observable
final class ScoutingStore {
    var teams: [Team] = []
    var matchNotes: [MatchNote] = []

    func save(team: Team) { }
    func delete(teamID: Int) { }
    func add(note: MatchNote) { }
}
```

Then pass the store through the environment or directly into feature views.

## UI Guidelines Used

The app favors native SwiftUI controls:

- `NavigationSplitView` for sidebar navigation
- `Form` in sheets for add/edit flows
- `Picker` with segmented style for guided steps
- `Stepper`, `Slider`, `Toggle`, `TextField`, and `ProgressView`
- SF Symbols for recognizable actions
- System materials and semantic colors

## Validation

Before publishing changes:

1. Run Xcode diagnostics for `ContentView.swift`.
2. Build the project.
3. Exercise each screen:
   - Add scouting data
   - Edit a team
   - Delete a team
   - Add a match note
   - Compare teams
   - Ask assistant questions

## Known Limitations

- Data is not persisted after app restart.
- The Base44 backend URL still needs to be connected.
- The assistant uses a local fallback until the Base44 assistant endpoint is configured.
- There are no automated tests yet.
- The project currently keeps all UI in one Swift file for simplicity.
