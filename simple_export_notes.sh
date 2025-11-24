#!/bin/bash

OUTPUT_FILE="./output/simple_export_notes.txt"

# Create output directory if it doesn't exist
mkdir -p ./output

> "$OUTPUT_FILE"

echo "Checking recent notes for today's entries..."

# Get today's date components
TODAY_YEAR=$(date +%Y)
TODAY_MONTH=$(date +%m)
TODAY_DAY=$(date +%d)

# Track found notes
NOTE_COUNT=0
NOTES_TO_CHECK=50  # Only check the most recent 50 notes

# Check each note individually
for i in $(seq 1 $NOTES_TO_CHECK); do
    echo -n "Checking note $i of $NOTES_TO_CHECK..."

    # Get note modification date
    MOD_DATE=$(osascript -e "tell application \"Notes\" to modification date of note $i as string" 2>/dev/null)

    if [ -z "$MOD_DATE" ]; then
        echo " (skipped)"
        continue
    fi

    # Parse the date (format like "Friday, November 22, 2024 at 12:00:00 AM")
    if echo "$MOD_DATE" | grep -q "$(date +%B) $TODAY_DAY, $TODAY_YEAR"; then
        echo " (found today's note!)"
        NOTE_COUNT=$((NOTE_COUNT + 1))

        # Get note details
        TITLE=$(osascript -e "tell application \"Notes\" to name of note $i as string" 2>/dev/null)
        BODY=$(osascript -e "tell application \"Notes\" to body of note $i as string" 2>/dev/null)

        # Append to file
        {
            echo "=== Note $NOTE_COUNT ==="
            echo "Modified: $MOD_DATE"
            echo "Title: $TITLE"
            echo "---"
            echo "$BODY"
            echo ""
            echo ""
        } >> "$OUTPUT_FILE"
    else
        echo ""
    fi
done

if [ $NOTE_COUNT -eq 0 ]; then
    echo "No notes from today found in the most recent $NOTES_TO_CHECK notes"
    echo "No notes from today found" > "$OUTPUT_FILE"
else
    echo ""
    echo "Successfully exported $NOTE_COUNT note(s) from today to ./output/simple_export_notes.txt"
fi