#!/bin/bash

# Output file
OUTPUT_FILE="$HOME/todays_notes.txt"

echo "Fetching recent notes and filtering for today..."

# Get recent notes and filter for today
osascript <<'END_SCRIPT' > "$OUTPUT_FILE" 2>/dev/null
on run
    set todayDate to current date
    set todayStart to todayDate
    set hours of todayStart to 0
    set minutes of todayStart to 0
    set seconds of todayStart to 0

    tell application "Notes"
        -- Get all notes and sort by modification date (most recent first)
        set allNotesList to notes 1 through 200

        -- Collect today's notes
        set todaysNotesList to {}
        repeat with aNote in allNotesList
            try
                if modification date of aNote ≥ todayStart then
                    set end of todaysNotesList to aNote
                end if
            on error
                -- Skip any notes that cause errors
            end try
        end repeat

        if (count of todaysNotesList) = 0 then
            return "No notes found from today"
        end if

        -- Sort today's notes chronologically (oldest first)
        repeat with i from 1 to (count of todaysNotesList) - 1
            repeat with j from i + 1 to count of todaysNotesList
                if modification date of item i of todaysNotesList > modification date of item j of todaysNotesList then
                    set temp to item i of todaysNotesList
                    set item i of todaysNotesList to item j of todaysNotesList
                    set item j of todaysNotesList to temp
                end if
            end repeat
        end repeat

        -- Build output
        set output to ""
        set noteNum to 0

        repeat with aNote in todaysNotesList
            set noteNum to noteNum + 1

            try
                set noteTitle to name of aNote as string
                set noteBody to body of aNote as string
                set noteDate to modification date of aNote as string

                set output to output & "=== Note " & noteNum & " ===" & linefeed
                set output to output & "Modified: " & noteDate & linefeed
                set output to output & "Title: " & noteTitle & linefeed
                set output to output & "---" & linefeed
                set output to output & noteBody & linefeed & linefeed & linefeed
            on error
                -- Skip notes that can't be read
            end try
        end repeat

        if output = "" then
            return "No notes found from today in the most recent 200 notes"
        else
            return output
        end if
    end tell
end run
END_SCRIPT

# Count the notes
if grep -q "No notes found" "$OUTPUT_FILE" 2>/dev/null; then
    cat "$OUTPUT_FILE"
else
    NOTE_COUNT=$(grep -c "=== Note" "$OUTPUT_FILE" 2>/dev/null || echo "0")
    echo "Successfully exported $NOTE_COUNT note(s) from today to ~/todays_notes.txt"
    echo "(Checked the 200 most recent notes)"
fi