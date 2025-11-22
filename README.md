# Apple Notes Export Scripts

A collection of scripts to export Apple Notes from macOS, with special focus on exporting today's notes in chronological order.

## Main Script: export_todays_notes.sh

The primary script for exporting today's notes with multiple format options including plain text, HTML, and stream modes.

### Usage

```bash
# Export as plain text with metadata (default)
./export_todays_notes.sh

# Export as clean text stream without metadata
./export_todays_notes.sh stream

# Export with HTML formatting preserved
./export_todays_notes.sh html

# Export stream format, check 200 recent notes
./export_todays_notes.sh stream 200

# Show help
./export_todays_notes.sh --help
```

### Features

- **Plain text export (default)**: Strips HTML tags for clean text with metadata
- **Stream mode**: Clean text stream with just content and simple dividers (no dates/metadata)
- **HTML export option**: Preserves original formatting from Notes app
- **Chronological sorting**: Notes are sorted from oldest to newest
- **Progress indication**: Shows scanning and export progress
- **Configurable scope**: Specify how many recent notes to check

### Output Formats

#### Plain Format (default)
Includes all metadata with clean text:
```
=== Note 1 ===
Modified: Friday, November 21, 2024 at 9:01:15 PM
Title: Meeting Notes
---
[Note content here]


```

#### Stream Format
Just the content with simple dividers:
```
[First note content]

---

[Second note content]

---

[Third note content]
```

#### HTML Format
Preserves all HTML formatting from the Notes app.

Notes are separated by double line breaks (three newlines total).

## Additional Scripts

### simple_export_notes.sh
- Original working version that exports the most recent 50 notes
- Always exports with HTML formatting
- Simple progress indication

### export_recent_notes.sh
- Attempts to export the 200 most recent notes
- Uses AppleScript for batch processing
- May be slower with large note collections

### export_notes_batch.sh
- Batch processing version using AppleScript date filtering
- Can be slow with large note databases

### export_notes_today.py
- Python implementation with individual note processing
- More control over error handling

### export_todays_notes.applescript
- Pure AppleScript implementation
- Direct Notes app integration

### export_todays_notes.js
- JavaScript for Automation (JXA) version
- Modern syntax alternative to AppleScript

## Requirements

- macOS with Apple Notes app
- Terminal access
- Permission for Terminal to access Notes (will be prompted on first run)

## Installation

1. Clone or download these scripts to your preferred location
2. Make scripts executable:
   ```bash
   chmod +x *.sh
   ```

## Permissions

On first run, macOS will prompt you to grant Terminal permission to access Notes. You must approve this for the scripts to work.

## Troubleshooting

### Scripts hang or timeout
- The Notes app may be showing a permission dialog
- Try running a simple test: `osascript -e 'tell application "Notes" to count notes'`
- If you have many notes (thousands), processing may take time

### No notes found
- Check that you have notes modified today
- Increase the number of recent notes to check: `./export_todays_notes.sh plain 200`

### HTML tags in output
- Use the plain text format: `./export_todays_notes.sh plain`
- This will strip HTML tags and provide clean text

### Performance issues
- Use `simple_export_notes.sh` for faster execution with fewer notes
- Reduce the number of notes to check

## Output Location

All scripts export to: `~/todays_notes.txt`

## License

These scripts are provided as-is for personal use.

## Notes

- The scripts check notes in reverse chronological order (most recent first)
- Only notes modified on the current day are exported
- The AppleScript date format is: "Friday, November 21, 2024 at 9:01:15 PM"
- HTML content from Notes includes div tags and formatting