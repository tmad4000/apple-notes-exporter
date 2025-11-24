#!/bin/bash

# Simple reliable script to export notes from the last 24 hours
# Processes notes one by one to avoid hanging

OUTPUT_FILE="./output/last_24h_simple_notes.txt"
NOTES_TO_CHECK="${1:-100}"  # Default 100, can specify more
FORMAT="${2:-stream}"  # Default stream format

# Create output directory if it doesn't exist
mkdir -p ./output

> "$OUTPUT_FILE"

echo "Exporting notes from the last 24 hours..."
echo "Checking $NOTES_TO_CHECK most recent notes"
echo "Format: $FORMAT"
echo ""

# Get current time and 24 hours ago
CURRENT_TIME=$(date +"%B %d, %Y at %H:%M")
echo "Current time: $(date)"

# We'll check for both November 21 and November 22, 2025
# since we're right around midnight
DATES_TO_CHECK=("November 21, 2025" "November 22, 2025")

# Track notes
NOTE_COUNT=0
TEMP_FILE="/tmp/notes_24h_$$.txt"
> "$TEMP_FILE"

echo "Scanning notes..."
for i in $(seq 1 $NOTES_TO_CHECK); do
    # Progress indicator
    if [ $((i % 10)) -eq 0 ]; then
        echo "  Checked $i notes... (found $NOTE_COUNT from last 24h)"
    fi

    # Get note date
    MOD_DATE=$(osascript -e "tell application \"Notes\" to modification date of note $i as string" 2>/dev/null)

    if [ -z "$MOD_DATE" ]; then
        continue
    fi

    # Check if it's from our target dates
    for CHECK_DATE in "${DATES_TO_CHECK[@]}"; do
        if echo "$MOD_DATE" | grep -q "$CHECK_DATE"; then
            NOTE_COUNT=$((NOTE_COUNT + 1))
            echo "$i|$MOD_DATE" >> "$TEMP_FILE"
            echo "    Found: Note $i from $MOD_DATE"
            break
        fi
    done
done

echo ""
echo "Found $NOTE_COUNT notes from the last 24 hours"

if [ $NOTE_COUNT -eq 0 ]; then
    echo "No notes found from the last 24 hours"
    echo "No notes found" > "$OUTPUT_FILE"
    rm -f "$TEMP_FILE"
    exit 0
fi

# Export the notes
echo ""
echo "Exporting notes..."

NOTE_NUM=0
while IFS='|' read -r NOTE_INDEX MOD_DATE; do
    NOTE_NUM=$((NOTE_NUM + 1))
    echo "  Exporting note $NOTE_NUM of $NOTE_COUNT..."

    # Get note content
    if [[ "$FORMAT" == "stream" ]] || [[ "$FORMAT" == "plain" ]]; then
        BODY=$(osascript -e "tell application \"Notes\" to plaintext of note $NOTE_INDEX as string" 2>/dev/null)
    else
        BODY=$(osascript -e "tell application \"Notes\" to body of note $NOTE_INDEX as string" 2>/dev/null)
    fi

    # Write based on format
    if [[ "$FORMAT" == "stream" ]]; then
        if [ $NOTE_NUM -gt 1 ]; then
            echo "---" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        fi
        echo "$BODY" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    else
        TITLE=$(osascript -e "tell application \"Notes\" to name of note $NOTE_INDEX as string" 2>/dev/null)
        {
            echo "=== Note $NOTE_NUM ==="
            echo "Modified: $MOD_DATE"
            echo "Title: $TITLE"
            echo "---"
            echo "$BODY"
            echo ""
            echo ""
        } >> "$OUTPUT_FILE"
    fi
done < "$TEMP_FILE"

rm -f "$TEMP_FILE"

echo ""
echo "=========================================="
echo "Export complete!"
echo "  Notes exported: $NOTE_COUNT"
echo "  Output file: ./output/last_24h_simple_notes.txt"
echo "=========================================="