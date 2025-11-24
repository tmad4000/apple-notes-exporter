#!/bin/bash

# Output file
OUTPUT_FILE="./output/batch_notes.txt"
TEMP_FILE="/tmp/notes_temp_$$.txt"

# Create output directory if it doesn't exist
mkdir -p ./output

# Clear output file
> "$OUTPUT_FILE"

# Get today's date in a format we can compare
TODAY=$(date +%Y-%m-%d)

echo "Fetching notes from Apple Notes..."

# First, get a list of note IDs that were modified today
# This is much faster than iterating through all notes
osascript <<'END_SCRIPT' > "$TEMP_FILE" 2>/dev/null
on run
    set todayDate to current date
    set todayStart to todayDate
    set hours of todayStart to 0
    set minutes of todayStart to 0
    set seconds of todayStart to 0

    tell application "Notes"
        set todaysNotes to every note whose modification date ≥ todayStart

        if (count of todaysNotes) = 0 then
            return "NO_NOTES_TODAY"
        end if

        -- Sort notes by modification date (simple bubble sort)
        repeat with i from 1 to (count of todaysNotes) - 1
            repeat with j from i + 1 to count of todaysNotes
                if modification date of item i of todaysNotes > modification date of item j of todaysNotes then
                    set temp to item i of todaysNotes
                    set item i of todaysNotes to item j of todaysNotes
                    set item j of todaysNotes to temp
                end if
            end repeat
        end repeat

        set output to ""
        set noteNum to 0

        repeat with aNote in todaysNotes
            set noteNum to noteNum + 1
            set noteTitle to name of aNote as string
            set noteBody to body of aNote as string
            set noteDate to modification date of aNote as string

            set output to output & "=== Note " & noteNum & " ===" & linefeed
            set output to output & "Modified: " & noteDate & linefeed
            set output to output & "Title: " & noteTitle & linefeed
            set output to output & "---" & linefeed
            set output to output & noteBody & linefeed & linefeed & linefeed
        end repeat

        return output
    end tell
end run
END_SCRIPT

# Check if we got any notes
if grep -q "NO_NOTES_TODAY" "$TEMP_FILE" 2>/dev/null; then
    echo "No notes found from today"
    echo "No notes found from today" > "$OUTPUT_FILE"
else
    # Move the temp file to the output file
    mv "$TEMP_FILE" "$OUTPUT_FILE"

    # Count the notes
    NOTE_COUNT=$(grep -c "=== Note" "$OUTPUT_FILE" 2>/dev/null || echo "0")
    echo "Successfully exported $NOTE_COUNT note(s) from today to ./output/batch_notes.txt"
fi

# Clean up
rm -f "$TEMP_FILE"