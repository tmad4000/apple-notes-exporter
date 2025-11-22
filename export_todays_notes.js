#!/usr/bin/env osascript -l JavaScript

// Get today's date at midnight
const today = new Date();
today.setHours(0, 0, 0, 0);

// Access Notes app
const Notes = Application("Notes");
Notes.includeStandardAdditions = true;

// Get all notes
const allNotes = Notes.notes();
console.log(`Total notes: ${allNotes.length}`);

// Filter notes modified today
const todaysNotes = [];

for (let i = 0; i < allNotes.length; i++) {
    try {
        const note = allNotes[i];
        const modDate = note.modificationDate();

        // Check if modified today
        if (modDate >= today) {
            todaysNotes.push({
                title: note.name(),
                body: note.body(),
                modDate: modDate
            });
        }
    } catch (e) {
        // Skip notes that can't be accessed
        continue;
    }
}

console.log(`Found ${todaysNotes.length} notes from today`);

// Sort notes chronologically (oldest first)
todaysNotes.sort((a, b) => a.modDate - b.modDate);

// Build output text
let output = "";
todaysNotes.forEach((note, index) => {
    output += `=== Note ${index + 1} ===\n`;
    output += `Modified: ${note.modDate.toLocaleString()}\n`;
    output += `Title: ${note.title}\n`;
    output += `---\n`;
    output += note.body;
    output += `\n\n\n`;  // Double line break
});

// Write to file
const app = Application.currentApplication();
app.includeStandardAdditions = true;

const homePath = app.pathTo("home folder").toString();
const outputPath = `${homePath}/todays_notes.txt`;

// Write the file
const file = app.openForAccess(Path(outputPath), { writePermission: true });
app.setEof(file, { to: 0 });
app.write(output, { to: file, as: "text" });
app.closeAccess(file);

console.log(`Exported ${todaysNotes.length} note(s) to ~/todays_notes.txt`);