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
- OpenAI-powered scouting assistant that reasons over the active season
- Responsive SwiftUI layout for Mac and iPad-style window sizes

## Project Structure

| Path | Purpose |
| --- | --- |
| `MyApp/MyApp.swift` | App entry point |
| `MyApp/ContentView.swift` | Main app UI, blank season state, and OpenAI assistant integration |
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

The app starts with a blank season and stores data in memory while it is running. Changes made while the app is open are reflected across the UI, but they are not persisted after relaunch. A future production version should add persistence with SwiftData, Core Data, a document format, or a backend.

## AI Assistant

The AI Assistant calls OpenAI's Responses API from the app after you enter an OpenAI API key. The key is stored locally in app storage. For a distributed team app, route AI calls through a backend so API keys are not placed on player or scout devices.

## Documentation

Start with [User Guide](docs/USER_GUIDE.md), then read [Developer Guide](docs/DEVELOPER_GUIDE.md) if you want to extend the app.
