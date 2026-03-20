# EventReader

EventReader is a SwiftUI iPhone app for importing `.ics` calendar files and browsing the parsed events in a simple list.

## What it does

- Imports an ICS file with the system file picker
- Parses `VEVENT` entries and extracts `SUMMARY` and `DTSTART`
- Converts event start times into `Date` values
- Sorts events by start time
- Saves the last imported calendar locally and reloads it on launch
- Lets you jump to the next upcoming event
- Lets you create a Reminders entry from an event

## Current UI

- Top bar with the imported calendar name and an `Import` button
- Event list showing title and formatted start time
- Floating button that scrolls to the next upcoming event and briefly highlights it
- Reminder confirmation flow for the selected event

## Project layout

- `EventReader/EventReaderApp.swift`: app entry point
- `EventReader/ContentView.swift`: main screen and import flow
- `EventReader/Event.swift`: event model, date parsing, and local save/load
- `EventReader/ICSParser.swift`: ICS unfolding and event extraction
- `EventReader/ButtonFunc.swift`: button style, haptics, and Reminders integration
- `EventReader/event.ics`: sample ICS file
- `EventReader/Formula_1.ics`: larger Formula 1 sample calendar

## Notes

- The parser is intentionally narrow. It currently ignores most ICS fields such as `DTEND`, `LOCATION`, recurrence rules, and timezone parameters.
- Imported data is stored as `events.json` in the app’s documents directory.
- The project target is iOS and includes a Reminders usage description in the app configuration.
