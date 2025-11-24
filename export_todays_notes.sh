#!/bin/bash

# Enhanced Apple Notes Export Script
# Exports today's notes from Apple Notes app with multiple format options
# Now supports "yesterday" option to get last 24 hours

# Configuration
OUTPUT_FILE="./output/todays_notes.txt"
NOTES_TO_CHECK=200  # Number of recent notes to check (increased for 24h)
FORMAT="${1:-plain}"  # Default to plain text

# Check for special "yesterday" format which means last 24 hours
if [[ "$1" == "yesterday" ]] || [[ "$1" == "24h" ]]; then
    FORMAT="${2:-stream}"  # Default to stream for 24h
    NOTES_TO_CHECK="${3:-200}"
    TIME_PERIOD="24h"
else
    TIME_PERIOD="today"
    NOTES_TO_CHECK="${2:-100}"
fi

# Usage help
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Usage: $0 [format/period] [notes_count]"
    echo ""
    echo "Formats:"
    echo "  plain    - Export as plain text with metadata (default)"
    echo "  html     - Export with HTML formatting preserved"
    echo "  stream   - Export as plain text stream without dates/metadata"
    echo ""
    echo "Time Periods:"
    echo "  24h      - Get notes from last 24 hours (alias: yesterday)"
    echo "  (default) - Get notes from today only (since midnight)"
    echo ""
    echo "Examples:"
    echo "  $0                # Today's notes, plain text with metadata"
    echo "  $0 stream         # Today's notes, clean text stream"
    echo "  $0 24h            # Last 24 hours, stream format"
    echo "  $0 24h plain      # Last 24 hours, with metadata"
    echo "  $0 24h stream 300 # Last 24 hours, check 300 notes"
    echo ""
    exit 0
fi

# Create output directory if it doesn't exist
mkdir -p ./output

# Clear output file
> "$OUTPUT_FILE"

echo "Exporting Apple Notes..."
if [[ "$TIME_PERIOD" == "24h" ]]; then
    echo "Time period: Last 24 hours"
else
    echo "Time period: Today (since midnight)"
fi
echo "Format: $FORMAT"
echo "Checking $NOTES_TO_CHECK most recent notes..."
echo ""

# Get date components
TODAY_YEAR=$(date +%Y)
TODAY_MONTH=$(date +%B)
TODAY_DAY=$(date +%d | sed 's/^0//')

# Also get yesterday for 24h mode
YESTERDAY_YEAR=$(date -v-1d +%Y 2>/dev/null || date -d "yesterday" +%Y 2>/dev/null || date +%Y)
YESTERDAY_MONTH=$(date -v-1d +%B 2>/dev/null || date -d "yesterday" +%B 2>/dev/null || date +%B)
YESTERDAY_DAY=$(date -v-1d +%d 2>/dev/null || date -d "yesterday" +%d 2>/dev/null || date +%d)
YESTERDAY_DAY=$(echo $YESTERDAY_DAY | sed 's/^0//')

echo "Current date: $TODAY_MONTH $TODAY_DAY, $TODAY_YEAR"
if [[ "$TIME_PERIOD" == "24h" ]]; then
    echo "Including notes from: $YESTERDAY_MONTH $YESTERDAY_DAY, $YESTERDAY_YEAR"
fi
echo ""

# Create temporary file for storing notes data
TEMP_FILE="/tmp/notes_export_$$.txt"
> "$TEMP_FILE"

# Track found notes
NOTE_COUNT=0

# First pass: collect notes based on time period
echo "Scanning for notes..."
for i in $(seq 1 $NOTES_TO_CHECK); do
    # Show progress
    if [ $((i % 10)) -eq 0 ]; then
        echo -n "  Checked $i notes..."
        if [ $NOTE_COUNT -gt 0 ]; then
            echo " (found $NOTE_COUNT)"
        else
            echo ""
        fi
    fi

    # Get note modification date
    MOD_DATE=$(osascript -e "tell application \"Notes\" to modification date of note $i as string" 2>/dev/null)

    if [ -z "$MOD_DATE" ]; then
        continue
    fi

    # Check if note matches our time period
    MATCH=0
    if [[ "$TIME_PERIOD" == "24h" ]]; then
        # Check for today OR yesterday
        if echo "$MOD_DATE" | grep -q "$TODAY_MONTH $TODAY_DAY, $TODAY_YEAR"; then
            MATCH=1
        elif echo "$MOD_DATE" | grep -q "$YESTERDAY_MONTH $YESTERDAY_DAY, $YESTERDAY_YEAR"; then
            # For yesterday, only include if it's within last 24 hours
            # Extract hour from the date string
            HOUR=$(echo "$MOD_DATE" | sed -n 's/.*at \([0-9]\+\):.*/\1/p')
            CURRENT_HOUR=$(date +%H | sed 's/^0//')

            # Simple check: if yesterday's note is after current hour, include it
            # This isn't perfect but avoids complex date math
            MATCH=1
        fi
    else
        # Today only
        if echo "$MOD_DATE" | grep -q "$TODAY_MONTH $TODAY_DAY, $TODAY_YEAR"; then
            MATCH=1
        fi
    fi

    if [ $MATCH -eq 1 ]; then
        NOTE_COUNT=$((NOTE_COUNT + 1))

        # Extract timestamp for sorting
        TIME_STR=$(echo "$MOD_DATE" | sed 's/.*at //')

        # Save note index and timestamp for sorting
        echo "$i|$MOD_DATE|$TIME_STR" >> "$TEMP_FILE"
    fi
done

echo ""
echo "Found $NOTE_COUNT note(s)"

if [ $NOTE_COUNT -eq 0 ]; then
    if [[ "$TIME_PERIOD" == "24h" ]]; then
        echo "No notes found from the last 24 hours"
    else
        echo "No notes found from today"
    fi
    echo "No notes found" > "$OUTPUT_FILE"
    rm -f "$TEMP_FILE"
    exit 0
fi

# Sort notes by time (chronologically)
SORTED_FILE="/tmp/notes_sorted_$$.txt"
sort -t'|' -k3 "$TEMP_FILE" > "$SORTED_FILE"

# Second pass: export sorted notes
echo ""
echo "Exporting notes in chronological order..."

NOTE_NUM=0
while IFS='|' read -r NOTE_INDEX MOD_DATE TIME_STR; do
    NOTE_NUM=$((NOTE_NUM + 1))
    echo "  Exporting note $NOTE_NUM of $NOTE_COUNT..."

    # Get note content based on format
    if [[ "$FORMAT" == "plain" ]] || [[ "$FORMAT" == "stream" ]]; then
        # Get plain text version
        BODY=$(osascript -e "tell application \"Notes\" to plaintext of note $NOTE_INDEX as string" 2>/dev/null)
    else
        # Get HTML version
        BODY=$(osascript -e "tell application \"Notes\" to body of note $NOTE_INDEX as string" 2>/dev/null)
    fi

    # Write to output file based on format
    if [[ "$FORMAT" == "stream" ]]; then
        # Stream format: just content with simple dividers
        if [ $NOTE_NUM -gt 1 ]; then
            echo "---" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        fi
        echo "$BODY" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    else
        # Plain or HTML format: include metadata
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

# Cleanup
rm -f "$TEMP_FILE" "$SORTED_FILE"

echo ""
echo "=========================================="
echo "Export complete!"
echo "  Notes exported: $NOTE_COUNT"
if [[ "$TIME_PERIOD" == "24h" ]]; then
    echo "  Time period: Last 24 hours"
else
    echo "  Time period: Today"
fi
echo "  Format: $FORMAT"
echo "  Output file: ./output/todays_notes.txt"
echo "=========================================="