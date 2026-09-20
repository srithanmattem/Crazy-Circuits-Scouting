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

In this version, data is stored only in app memory. It is not written to disk by the app and is not uploaded anywhere.

## Network Usage

The current app does not make network requests.

## Assistant Behavior

The AI Assistant calls OpenAI's Responses API after the user enters an OpenAI API key in the app. It sends the active season name, game/year fields, teams, match notes, and the user's question to OpenAI.

The API key is stored locally in app storage. Do not ship a shared team app with a hard-coded API key. For production, proxy AI requests through a backend you control.

## Production Considerations

Before using this for real team operations, consider adding:

- Persistent local storage
- Import/export
- Team data backup
- Permission controls for shared devices
- Clear data reset controls
- Privacy review if syncing to a server
