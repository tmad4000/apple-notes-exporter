#!/bin/bash

# Export notes from the last 48 hours
# Processes notes one by one to avoid hanging

OUTPUT_FILE="$HOME/todays_notes.txt"
NOTES_TO_CHECK="${1:-300}"  # Default 300 notes for 48h period
FORMAT="${2:-stream}"  # Default stream format

> "$OUTPUT_FILE"

echo "Exporting notes from the last 48 hours..."
echo "Checking $NOTES_TO_CHECK most recent notes"
echo "Format: $FORMAT"
echo ""

# Get current date and previous dates
CURRENT_TIME=$(date)
echo "Current time: $CURRENT_TIME"

# For 48 hours, we need to check 3 possible dates
# (today, yesterday, and day before yesterday)
TODAY=$(date +"%B %d, %Y" | sed 's/ 0/ /g')
YESTERDAY=$(date -v-1d +"%B %d, %Y" 2>/dev/null | sed 's/ 0/ /g')
DAY_BEFORE=$(date -v-2d +"%B %d, %Y" 2>/dev/null | sed 's/ 0/ /g')

# If GNU date (Linux), use different syntax
if [ -z "$YESTERDAY" ]; then
    YESTERDAY=$(date -d "1 day ago" +"%B %d, %Y" 2>/dev/null | sed 's/ 0/ /g')
    DAY_BEFORE=$(date -d "2 days ago" +"%B %d, %Y" 2>/dev/null | sed 's/ 0/ /g')
fi

# For macOS in 2025, we're looking at November dates
# Since it's Nov 22, we want Nov 20, 21, and 22
DATES_TO_CHECK=("November 20, 2025" "November 21, 2025" "November 22, 2025")

echo "Looking for notes from:"
for DATE in "${DATES_TO_CHECK[@]}"; do
    echo "  - $DATE"
done
echo ""

# Track notes
NOTE_COUNT=0
TEMP_FILE="/tmp/notes_48h_$$.txt"
> "$TEMP_FILE"

echo "Scanning notes..."
for i in $(seq 1 $NOTES_TO_CHECK); do
    # Progress indicator
    if [ $((i % 20)) -eq 0 ]; then
        echo "  Checked $i notes... (found $NOTE_COUNT from last 48h)"
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

            # Extract time for sorting
            TIME_STR=$(echo "$MOD_DATE" | sed 's/.*at //')

            # Save with sortable format: date_number|index|full_date
            if echo "$CHECK_DATE" | grep -q "20,"; then
                DATE_NUM="20"
            elif echo "$CHECK_DATE" | grep -q "21,"; then
                DATE_NUM="21"
            else
                DATE_NUM="22"
            fi

            echo "$DATE_NUM|$TIME_STR|$i|$MOD_DATE" >> "$TEMP_FILE"

            # Show progress for first 20 found
            if [ $NOTE_COUNT -le 20 ]; then
                echo "    Found: Note $i from $MOD_DATE"
            fi
            break
        fi
    done
done

echo ""
echo "Found $NOTE_COUNT notes from the last 48 hours"

if [ $NOTE_COUNT -eq 0 ]; then
    echo "No notes found from the last 48 hours"
    echo "No notes found" > "$OUTPUT_FILE"
    rm -f "$TEMP_FILE"
    exit 0
fi

# Sort notes chronologically (by date then time)
SORTED_FILE="/tmp/notes_sorted_48h_$$.txt"
sort -t'|' -k1,1n -k2,2 "$TEMP_FILE" > "$SORTED_FILE"

# Export the notes
echo ""
echo "Exporting notes in chronological order..."

NOTE_NUM=0
while IFS='|' read -r DATE_NUM TIME_STR NOTE_INDEX MOD_DATE; do
    NOTE_NUM=$((NOTE_NUM + 1))

    # Show progress
    if [ $((NOTE_NUM % 10)) -eq 0 ] || [ $NOTE_NUM -eq 1 ]; then
        echo "  Exporting note $NOTE_NUM of $NOTE_COUNT..."
    fi

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
done < "$SORTED_FILE"

rm -f "$TEMP_FILE" "$SORTED_FILE"

echo ""
echo "=========================================="
echo "Export complete!"
echo "  Notes exported: $NOTE_COUNT from last 48 hours"
echo "  Output file: ~/todays_notes.txt"
echo "  Format: $FORMAT"
echo "=========================================="

# Show date breakdown
echo ""
echo "Notes by date:"
for DATE in "${DATES_TO_CHECK[@]}"; do
    COUNT=$(grep -c "$DATE" ~/todays_notes.txt 2>/dev/null || echo "0")
    echo "  $DATE: $COUNT notes"
done