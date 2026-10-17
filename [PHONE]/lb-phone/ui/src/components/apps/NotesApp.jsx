import React, { useState } from 'react';

export default function NotesApp() {
  const [notes, setNotes] = useState([]);
  const [selectedNote, setSelectedNote] = useState(null);
  const [titleInput, setTitleInput] = useState('');
  const [contentInput, setContentInput] = useState('');

  const handleCreateNote = () => {
    if (!titleInput.trim()) return;
    const newNote = {
      id: Date.now(),
      title: titleInput,
      content: contentInput,
      timestamp: new Date(),
    };
    setNotes([...notes, newNote]);
    setTitleInput('');
    setContentInput('');
    setSelectedNote(null);
  };

  const handleDeleteNote = (id) => {
    setNotes(notes.filter((note) => note.id !== id));
    setSelectedNote(null);
  };

  return (
    <div className="notes-app">
      <div className="app-header">
        <h2>Notes</h2>
        <button onClick={() => setSelectedNote(null)}>+ New</button>
      </div>
      <div className="notes-content">
        {!selectedNote ? (
          <>
            <div className="new-note">
              <input
                type="text"
                placeholder="Title"
                value={titleInput}
                onChange={(e) => setTitleInput(e.target.value)}
              />
              <textarea
                placeholder="Start typing..."
                value={contentInput}
                onChange={(e) => setContentInput(e.target.value)}
              />
              <button onClick={handleCreateNote}>Create Note</button>
            </div>
            <div className="notes-list">
              {notes.map((note) => (
                <div key={note.id} className="note-item" onClick={() => setSelectedNote(note)}>
                  <h4>{note.title}</h4>
                  <p>{note.content.substring(0, 100)}...</p>
                  <small>{note.timestamp.toLocaleDateString()}</small>
                </div>
              ))}
            </div>
          </>
        ) : (
          <div className="note-detail">
            <h2>{selectedNote.title}</h2>
            <p>{selectedNote.content}</p>
            <button onClick={() => handleDeleteNote(selectedNote.id)}>Delete</button>
            <button onClick={() => setSelectedNote(null)}>Back</button>
          </div>
        )}
      </div>
    </div>
  );
}
