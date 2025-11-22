#!/usr/bin/osascript

-- Get today's date at midnight
set todayMidnight to (current date)
set hours of todayMidnight to 0
set minutes of todayMidnight to 0
set seconds of todayMidnight to 0

-- Initialize output string
set outputText to ""
set noteCount to 0

tell application "Notes"
	-- Get all notes
	set allNotes to every note

	-- Filter notes from today and collect their data
	set todaysNotes to {}
	repeat with aNote in allNotes
		set noteModDate to modification date of aNote
		if noteModDate ≥ todayMidnight then
			set noteTitle to name of aNote as string
			set noteBody to body of aNote as string
			set noteInfo to {modDate:noteModDate, title:noteTitle, content:noteBody}
			set end of todaysNotes to noteInfo
		end if
	end repeat

	-- Sort notes by modification date (oldest first)
	set sortedNotes to my sortNotesByDate(todaysNotes)

	-- Build output text
	repeat with noteRecord in sortedNotes
		set noteCount to noteCount + 1

		-- Add note header with timestamp
		set noteDate to modDate of noteRecord
		set dateString to (noteDate as string)
		set outputText to outputText & "=== Note " & noteCount & " ===" & linefeed
		set outputText to outputText & "Modified: " & dateString & linefeed
		set outputText to outputText & "Title: " & (title of noteRecord) & linefeed
		set outputText to outputText & "---" & linefeed
		set outputText to outputText & (content of noteRecord) & linefeed & linefeed & linefeed
	end repeat
end tell

-- Sort function
on sortNotesByDate(notesList)
	set sortedList to notesList
	set listLength to count of sortedList

	repeat with i from 1 to listLength - 1
		repeat with j from i + 1 to listLength
			if (modDate of item i of sortedList) > (modDate of item j of sortedList) then
				set temp to item i of sortedList
				set item i of sortedList to item j of sortedList
				set item j of sortedList to temp
			end if
		end repeat
	end repeat

	return sortedList
end sortNotesByDate

-- Write to file
set outputFile to (POSIX path of (path to home folder)) & "todays_notes.txt"

try
	set fileRef to open for access POSIX file outputFile with write permission
	set eof fileRef to 0
	write outputText to fileRef as «class utf8»
	close access fileRef

	if noteCount = 0 then
		return "No notes found from today. Check ~/todays_notes.txt (file will be empty)"
	else
		return "Successfully exported " & noteCount & " note(s) from today to ~/todays_notes.txt"
	end if
on error errMsg
	try
		close access fileRef
	end try
	return "Error: " & errMsg
end try