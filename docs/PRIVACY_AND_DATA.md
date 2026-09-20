# Privacy and Data Notes

Circuit Scout currently stores all data in memory while the app is running.

## What Data Is Used

The app works with scouting data such as:

- Team numbers
- Team names
- Regions
- Robot drive train information
- Category scores
- Match notes
- Event labels

## Where Data Is Stored

In this version, data is stored in app memory while the app is running. The app also includes a Base44 sync client so the same data can be uploaded to the team website once the backend endpoint is configured.

## Network Usage

The app is prepared to send seasons, teams, match notes, and assistant questions to the team's Base44 backend. If the backend URL is blank, sync quietly skips and the app continues working locally.

## Assistant Behavior

The AI Assistant does not ask users for API keys and does not store an AI key in the app. It sends the active season name, game/year fields, teams, match notes, and the user's question to a Base44 assistant endpoint when connected. The website backend should own any private AI provider key.

If the assistant endpoint is not configured, the app tries Apple on-device AI on supported devices. If that is unavailable, it returns a local data-based scouting summary instead.

## Production Considerations

Before using this for real team operations, consider adding:

- Persistent local storage
- Import/export
- Team data backup
- Permission controls for shared devices
- Clear data reset controls
- Privacy review if syncing to a server
