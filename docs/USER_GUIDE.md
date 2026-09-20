# Circuit Scout User Guide

This guide explains how to use Circuit Scout during team scouting and match planning.

## Navigation

Use the sidebar to move between the main areas of the app:

| Section | Use It For |
| --- | --- |
| Dashboard | Review the current scouting snapshot |
| Scout | Add or update scouting data for a team |
| Teams | Search, edit, compare, or delete teams |
| Match Notes | Record observations from matches |
| Compare | Compare selected teams side by side |
| AI Assistant | Ask OpenAI-powered questions about the current season |

## Seasons

The season controls are at the bottom of the sidebar.

You can:

- Rename the current season
- Add a game name
- Add a year
- Create a new blank season
- Switch between seasons
- Delete a season when more than one exists

New seasons start blank. They do not include sample teams or sample notes.

## Dashboard

The dashboard gives you a fast overview before a match. It shows:

- Number of teams scouted
- Number of match notes
- Highest overall score
- Number of regions represented
- Current top alliance signal
- Top teams list
- Recent notes

Use `Scout` to enter new data. Use `Compare` to jump directly into alliance planning.

## Scout a Team

The Scout screen is divided into four steps:

| Step | What To Enter |
| --- | --- |
| Team | Team number, team name, region, and drive train |
| Auto | Autonomous score |
| Tele-Op | Tele-op score and match event |
| Endgame | Endgame score and drive-team notes |

The live summary updates as you enter values. When the required fields are complete, select `Submit Scouting Data`.

Submitting data will:

- Add a new team if the team number is new
- Update the existing team if the team number already exists
- Add a match note using the scouting summary

Use `Reset` to clear the form and start over.

## Team Database

The Teams screen lets you manage the roster of scouted teams.

You can:

- Search by team number, name, or region
- Select a team to view details
- Add a team
- Edit a team
- Delete a team
- Add or remove a team from the comparison list

The detail panel shows category scores and notes for the selected team.

## Match Notes

Use Match Notes for short observations that the whole team can scan quickly.

You can:

- Search notes
- Add a note for a specific team
- Record event name, score, and observation text
- Delete old or incorrect notes

Good notes are short and actionable. For example:

- `Fast cycles but intake jammed twice under defense.`
- `Strong auto path from left starting position.`
- `Reliable endgame park with 15 seconds remaining.`

## Compare Teams

The Compare screen helps choose alliance partners.

1. Select up to five teams.
2. Review category bars for autonomous, tele-op, and endgame.
3. Read the suggested captain's notes for best auto, tele-op, and endgame options.

Use this screen before alliance selection or while planning match strategy.

## Assistant

The AI Assistant uses OpenAI to answer questions from the current season's teams and match notes.

Before using it:

1. Open `AI Assistant`.
2. Paste your OpenAI API key into `OpenAI API Key`.
3. Leave the model field as-is, or enter another model your OpenAI account can use.

Try asking:

- `Who is best overall?`
- `Who is strongest in auto?`
- `Best tele-op scorer?`
- `Endgame or parking recommendation?`
- `Summarize notes`

The assistant sends the active season's scouting data to OpenAI with your question. For a production team app, use a backend service instead of putting an API key directly on shared devices.

## Data Persistence

This version stores data in memory while the app is open. If you close and relaunch the app, it returns to a blank season. Add persistent storage before using it as a production scouting record.
