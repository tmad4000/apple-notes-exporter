#!/bin/bash

# Export Apple Notes from the last 24 hours
# More flexible than "today" - gets exactly 24 hours back from current time

# Configuration
OUTPUT_FILE="./output/last_24h_notes.txt"
NOTES_TO_CHECK="${2:-200}"  # Default check 200 notes for 24h period
FORMAT="${1:-stream}"  # Default to stream format for cleaner output

# Usage help
if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
    echo "Usage: $0 [format] [notes_count]"
    echo ""
    echo "Exports notes from the last 24 hours (not just today)"
    echo ""
    echo "Formats:"
    echo "  stream   - Clean text stream without metadata (default)"
    echo "  plain    - Plain text with metadata"
    echo "  html     - HTML formatting preserved"
    echo ""
    echo "Arguments:"
    echo "  format       - Export format (default: stream)"
    echo "  notes_count  - Number of recent notes to check (default: 200)"
    echo ""
    echo "Examples:"
    echo "  $0                # Stream format, last 24 hours"
    echo "  $0 plain          # Plain text with metadata"
    echo "  $0 stream 500     # Check 500 notes for last 24h"
    echo ""
    exit 0
fi

# Create output directory if it doesn't exist
mkdir -p ./output

# Clear output file
> "$OUTPUT_FILE"

echo "Exporting Apple Notes from the last 24 hours..."
echo "Format: $FORMAT"
echo "Checking $NOTES_TO_CHECK most recent notes..."
echo ""

# Get timestamp for 24 hours ago
CURRENT_EPOCH=$(date +%s)
YESTERDAY_EPOCH=$((CURRENT_EPOCH - 86400))  # 86400 seconds = 24 hours

# For display purposes
echo "Current time: $(date)"
echo "Getting notes since: $(date -r $YESTERDAY_EPOCH)"
echo ""

# Create temporary file for storing notes data
TEMP_FILE="/tmp/notes_24h_$$.txt"
> "$TEMP_FILE"

# Track found notes
NOTE_COUNT=0
CHECKED=0

echo "Scanning for notes from last 24 hours..."

# AppleScript to get notes from last 24 hours
osascript <<EOF > "$TEMP_FILE" 2>/dev/null
on run
    -- Calculate 24 hours ago
    set twentyFourHoursAgo to (current date) - (24 * hours)

    tell application "Notes"
        set recentNotes to {}
        set noteIndex to 0

        -- Check recent notes
        repeat with i from 1 to $NOTES_TO_CHECK
            try
                set theNote to note i
                set modDate to modification date of theNote

                if modDate ≥ twentyFourHoursAgo then
                    -- Get note info
                    set noteTitle to name of theNote as string
                    set noteModStr to modDate as string

                    -- Create record: index|date|title
                    set noteRecord to (i as string) & "|" & noteModStr & "|" & noteTitle

                    -- Output the record
                    log noteRecord
                end if
            on error
                -- Skip problematic notes
            end try
        end repeat
    end tell
end run
EOF

# Count how many notes we found
NOTE_COUNT=$(cat "$TEMP_FILE" | wc -l | tr -d ' ')

echo "Found $NOTE_COUNT note(s) from the last 24 hours"

if [ $NOTE_COUNT -eq 0 ]; then
    echo "No notes found from the last 24 hours in the most recent $NOTES_TO_CHECK notes"
    echo "No notes from the last 24 hours found" > "$OUTPUT_FILE"
    rm -f "$TEMP_FILE"
    exit 0
fi

# Sort notes by date (chronologically)
SORTED_FILE="/tmp/notes_sorted_24h_$$.txt"
sort -t'|' -k2 "$TEMP_FILE" > "$SORTED_FILE"

# Second pass: export sorted notes
echo ""
echo "Exporting notes in chronological order..."

NOTE_NUM=0
while IFS='|' read -r NOTE_INDEX MOD_DATE TITLE; do
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
echo "  Notes exported: $NOTE_COUNT from last 24 hours"
echo "  Format: $FORMAT"
echo "  Output file: ./output/last_24h_notes.txt"
echo "=========================================="