import React, { useState } from 'react';
import AppGrid from '../AppGrid';
import Notification from '../Notification';
import StatusBar from '../StatusBar';

export default function HomeScreen({ currentApp, setCurrentApp }) {
  const [notifications, setNotifications] = useState([]);

  return (
    <div className="home-screen">
      <StatusBar />
      <AppGrid onAppSelect={setCurrentApp} />
      {notifications.map((notif, idx) => (
        <Notification
          key={idx}
          data={notif}
          onDismiss={() => setNotifications(n => n.filter((_, i) => i !== idx))}
        />
      ))}
    </div>
  );
}
