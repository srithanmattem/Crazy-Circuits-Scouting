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

The Assistant is local and rule-based. It answers from the teams and match notes currently loaded in the app. It does not send prompts or scouting data to an external service.

## Production Considerations

Before using this for real team operations, consider adding:

- Persistent local storage
- Import/export
- Team data backup
- Permission controls for shared devices
- Clear data reset controls
- Privacy review if syncing to a server

