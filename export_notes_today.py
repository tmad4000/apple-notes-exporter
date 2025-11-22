#!/usr/bin/env python3

import subprocess
import json
from datetime import datetime, date
import sys

def run_applescript(script):
    """Run an AppleScript and return the result"""
    try:
        result = subprocess.run(
            ['osascript', '-e', script],
            capture_output=True,
            text=True,
            timeout=10
        )
        if result.returncode != 0:
            print(f"Error: {result.stderr}", file=sys.stderr)
            return None
        return result.stdout.strip()
    except subprocess.TimeoutExpired:
        print("Error: Script timed out", file=sys.stderr)
        return None
    except Exception as e:
        print(f"Error running AppleScript: {e}", file=sys.stderr)
        return None

def get_notes_count():
    """Get the total number of notes"""
    script = 'tell application "Notes" to count notes'
    result = run_applescript(script)
    return int(result) if result and result.isdigit() else 0

def get_note_info(note_index):
    """Get information about a specific note by index"""
    script = f'''
    tell application "Notes"
        set theNote to note {note_index}
        set noteTitle to name of theNote
        set noteBody to body of theNote
        set noteModDate to modification date of theNote

        -- Format the date as a string we can parse
        set dateStr to (year of noteModDate as string) & "-" & ¬
            (month of noteModDate as integer as string) & "-" & ¬
            (day of noteModDate as string) & " " & ¬
            (hours of noteModDate as string) & ":" & ¬
            (minutes of noteModDate as string) & ":" & ¬
            (seconds of noteModDate as string)

        return noteTitle & "|||" & dateStr & "|||END_DATE|||"
    end tell
    '''

    result = run_applescript(script)
    if not result:
        return None

    # Parse the result
    parts = result.split('|||')
    if len(parts) >= 2:
        title = parts[0]
        date_str = parts[1].replace('END_DATE', '').strip()

        # Now get the body separately (to avoid delimiter issues)
        body_script = f'''
        tell application "Notes"
            set theNote to note {note_index}
            return body of theNote as string
        end tell
        '''
        body = run_applescript(body_script)

        return {
            'title': title,
            'date_str': date_str,
            'body': body if body else ''
        }

    return None

def parse_date(date_str):
    """Parse the date string from AppleScript"""
    try:
        # Try to parse the date string
        parts = date_str.split()
        if len(parts) >= 2:
            date_part = parts[0]
            time_part = parts[1] if len(parts) > 1 else "0:0:0"

            date_parts = date_part.split('-')
            time_parts = time_part.split(':')

            year = int(date_parts[0])
            month = int(date_parts[1])
            day = int(date_parts[2])
            hour = int(time_parts[0]) if len(time_parts) > 0 else 0
            minute = int(time_parts[1]) if len(time_parts) > 1 else 0
            second = int(time_parts[2]) if len(time_parts) > 2 else 0

            return datetime(year, month, day, hour, minute, second)
    except Exception as e:
        print(f"Error parsing date '{date_str}': {e}", file=sys.stderr)
        return None

def main():
    print("Fetching notes from Apple Notes...")

    # Get total number of notes
    total_notes = get_notes_count()
    if total_notes == 0:
        print("No notes found in Apple Notes")
        return

    print(f"Found {total_notes} total notes. Checking for today's notes...")

    # Get today's date
    today = date.today()
    todays_notes = []

    # Check each note
    for i in range(1, total_notes + 1):
        note_info = get_note_info(i)
        if note_info:
            note_date = parse_date(note_info['date_str'])
            if note_date and note_date.date() == today:
                todays_notes.append({
                    'title': note_info['title'],
                    'body': note_info['body'],
                    'datetime': note_date
                })
                print(f"  Found note from today: {note_info['title']}")

    if not todays_notes:
        print("No notes found from today")
        with open('todays_notes.txt', 'w') as f:
            f.write("No notes found from today\n")
        return

    # Sort notes chronologically (oldest first)
    todays_notes.sort(key=lambda x: x['datetime'])

    print(f"\nExporting {len(todays_notes)} note(s) from today...")

    # Write to file
    with open('todays_notes.txt', 'w', encoding='utf-8') as f:
        for i, note in enumerate(todays_notes, 1):
            f.write(f"=== Note {i} ===\n")
            f.write(f"Modified: {note['datetime'].strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"Title: {note['title']}\n")
            f.write("---\n")
            f.write(note['body'])
            f.write("\n\n\n")  # Double line break (three newlines total)

    print(f"Successfully exported {len(todays_notes)} note(s) to todays_notes.txt")

if __name__ == "__main__":
    main()