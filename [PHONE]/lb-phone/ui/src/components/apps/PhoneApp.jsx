import React, { useState } from 'react';

export default function PhoneApp() {
  const [contacts, setContacts] = useState([]);
  const [recentCalls, setRecentCalls] = useState([]);
  const [view, setView] = useState('contacts');

  return (
    <div className="phone-app">
      <div className="app-header">
        <h2>Phone</h2>
      </div>
      <div className="app-tabs">
        <button className={view === 'contacts' ? 'active' : ''} onClick={() => setView('contacts')}>
          Contacts
        </button>
        <button className={view === 'recents' ? 'active' : ''} onClick={() => setView('recents')}>
          Recents
        </button>
      </div>
      <div className="app-content">
        {view === 'contacts' && (
          <div className="contacts-list">
            {contacts.length === 0 && <p>No contacts</p>}
            {contacts.map((contact) => (
              <div key={contact.id} className="contact-item">
                <span>{contact.name}</span>
                <span>{contact.number}</span>
              </div>
            ))}
          </div>
        )}
        {view === 'recents' && (
          <div className="recents-list">
            {recentCalls.length === 0 && <p>No recent calls</p>}
            {recentCalls.map((call) => (
              <div key={call.id} className="recent-item">
                <span>{call.name || call.number}</span>
                <span className="time">{new Date(call.timestamp).toLocaleTimeString()}</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
