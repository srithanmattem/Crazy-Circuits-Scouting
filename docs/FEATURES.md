# Feature Reference

## Dashboard

The dashboard summarizes the scouting database and highlights the current top team.

Implemented:

- Metrics cards
- Top alliance signal
- Top teams list
- Recent notes list
- Quick actions for Scout and Compare

## Scouting Form

The scouting flow is designed to reduce learning curve by showing one category at a time.

Implemented:

- Team identity fields
- Drive train picker
- Autonomous score stepper
- Tele-op score stepper
- Event field
- Endgame score stepper
- Drive-team notes
- Live summary
- Submit and reset actions

## Team Database

The team database supports common management tasks.

Implemented:

- Search
- Add team
- Edit team
- Delete team
- Select team
- Detail panel
- Add or remove from comparison list

## Match Notes

Match notes support short observations tied to teams.

Implemented:

- Search notes
- Add note sheet
- Delete note
- Score and date display

## Team Comparison

Comparison helps strategy leads quickly identify role fits.

Implemented:

- Select up to five teams
- Score bars for auto, tele-op, and endgame
- Best auto, tele-op, and endgame insights

## Assistant

The assistant answers scouting questions from the current season's data. It is designed to call the team Base44 backend so API keys stay off scout devices.

Implemented:

- No-login, no-key chat interface
- Current-season context packaging
- Base44 assistant request
- Local data-based fallback while the backend is not connected
- Chat-style question and answer flow

## Seasons

Season management lets each year or game start from a clean slate.

Implemented:

- Create new blank season
- Rename season
- Edit game name and year
- Switch active season
- Delete active season when another season exists
