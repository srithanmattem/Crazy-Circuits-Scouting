# Circuit Scout

Circuit Scout is a SwiftUI scouting app for FTC teams. It gives drive teams and strategy leads a simple place to enter scouting data, review team performance, compare alliance options, and summarize match notes.

## What It Includes

- Native Apple-style sidebar navigation
- Dashboard with team, note, score, and region metrics
- Guided scouting form for team info, autonomous, tele-op, and endgame
- Searchable team database with add, edit, delete, and comparison controls
- Match notes with quick add and delete flows
- Team comparison view with category score bars and strategy insights
- Season picker with blank new seasons
- AI scouting assistant designed to run through a team Base44 backend, with on-device AI fallback where supported and no API keys on scout devices
- Automatic Base44 sync foundation for seasons, teams, and match notes
- Responsive SwiftUI layout for Mac and iPad-style window sizes

## Project Structure

| Path | Purpose |
| --- | --- |
| `MyApp/MyApp.swift` | App entry point |
| `MyApp/ContentView.swift` | Main app UI, blank season state, Base44 sync, and assistant integration |
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

The app starts with a blank season and stores data in memory while it is running. Changes made while the app is open are reflected across the UI. The code also includes a Base44 sync client so seasons, teams, and match notes can automatically sync to the existing website once the backend endpoint is added.

## AI Assistant

The AI Assistant does not ask scouts for API keys. It is wired to call a Base44 backend assistant endpoint, so the website can safely own the AI provider key. If the backend is not connected, the app tries Apple on-device AI on supported devices, then falls back to a local data-based scouting summary instead of failing.

## Documentation

Start with [User Guide](docs/USER_GUIDE.md), then read [Developer Guide](docs/DEVELOPER_GUIDE.md) if you want to extend the app.
