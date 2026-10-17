import React, { useState } from 'react';

export default function MessagesApp() {
  const [conversations, setConversations] = useState([]);
  const [selectedConversation, setSelectedConversation] = useState(null);
  const [messageInput, setMessageInput] = useState('');

  const handleSendMessage = () => {
    if (!messageInput.trim()) return;
    // Send message logic
    setMessageInput('');
  };

  return (
    <div className="messages-app">
      <div className="app-header">
        <h2>Messages</h2>
      </div>
      <div className="messages-content">
        {!selectedConversation ? (
          <div className="conversations-list">
            {conversations.length === 0 && <p>No conversations</p>}
            {conversations.map((conv) => (
              <div key={conv.id} className="conversation-item" onClick={() => setSelectedConversation(conv)}>
                <span className="name">{conv.name}</span>
                <span className="preview">{conv.lastMessage}</span>
              </div>
            ))}
          </div>
        ) : (
          <div className="conversation-view">
            <div className="conversation-header">
              <h3>{selectedConversation.name}</h3>
              <button onClick={() => setSelectedConversation(null)}>Back</button>
            </div>
            <div className="messages-list">
              {selectedConversation.messages?.map((msg) => (
                <div key={msg.id} className={`message ${msg.sent ? 'sent' : 'received'}`}>
                  {msg.content}
                </div>
              ))}
            </div>
            <div className="message-input">
              <input
                type="text"
                placeholder="Type a message..."
                value={messageInput}
                onChange={(e) => setMessageInput(e.target.value)}
                onKeyPress={(e) => e.key === 'Enter' && handleSendMessage()}
              />
              <button onClick={handleSendMessage}>Send</button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
