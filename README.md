# Circuit Scout

Circuit Scout is a SwiftUI scouting app for FTC teams. It gives drive teams and strategy leads a simple place to enter scouting data, review team performance, compare alliance options, and summarize match notes.

## What It Includes

- Native Apple-style sidebar navigation
- Dashboard with team, note, score, and region metrics
- Guided scouting form for team info, autonomous, tele-op, and endgame
- Searchable team database with add, edit, delete, and comparison controls
- Match notes with quick add and delete flows
- Team comparison view with category score bars and strategy insights
- Lightweight local scouting assistant that answers from in-app data
- Responsive SwiftUI layout for Mac and iPad-style window sizes

## Project Structure

| Path | Purpose |
| --- | --- |
| `MyApp/MyApp.swift` | App entry point |
| `MyApp/ContentView.swift` | Main app UI, sample data, and local state |
| `MyApp/Assets.xcassets` | App asset catalog |
| `docs/USER_GUIDE.md` | How to use the app |
| `docs/DEVELOPER_GUIDE.md` | How the code is organized |
| `docs/FEATURES.md` | Feature reference |
| `docs/PRIVACY_AND_DATA.md` | Data and privacy notes |

## Requirements

- Xcode
- SwiftUI
- Apple platform target supported by the generated Xcode project

## Run the App

1. Open `Untitled Project.xcodeproj` in Xcode.
2. Select the `MyApp` scheme.
3. Choose a simulator, device, or Mac run destination.
4. Press Run.

## Current Data Model

The app currently uses in-memory sample data. Changes made while the app is running are reflected across the UI, but they are not persisted after relaunch. A future production version should add persistence with SwiftData, Core Data, a document format, or a backend.

## Documentation

Start with [User Guide](docs/USER_GUIDE.md), then read [Developer Guide](docs/DEVELOPER_GUIDE.md) if you want to extend the app.

