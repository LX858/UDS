import React, { useState, useEffect } from 'react';
import '../styles/status-bar.css';

export default function StatusBar() {
  const [time, setTime] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  const hours = time.getHours().toString().padStart(2, '0');
  const minutes = time.getMinutes().toString().padStart(2, '0');

  return (
    <div className="status-bar">
      <div className="status-left">
        <span>{hours}:{minutes}</span>
      </div>
      <div className="status-right">
        <div className="status-signal">
          <span /><span /><span /><span />
        </div>
        <svg width="16" height="12" viewBox="0 0 16 12" fill="none">
          <path d="M8 2.4C9.8 2.4 11.4 3.1 12.6 4.2L14 2.8C12.4 1.1 10.3 0 8 0C5.7 0 3.6 1.1 2 2.8L3.4 4.2C4.6 3.1 6.2 2.4 8 2.4Z" fill="white" opacity="0.9"/>
          <path d="M8 5.2C9.1 5.2 10.1 5.6 10.8 6.4L12.2 5C11.1 3.9 9.6 3.2 8 3.2C6.4 3.2 4.9 3.9 3.8 5L5.2 6.4C5.9 5.6 6.9 5.2 8 5.2Z" fill="white" opacity="0.9"/>
          <circle cx="8" cy="9" r="1.5" fill="white"/>
        </svg>
        <div className="battery-body">
          <div className="battery-fill" />
        </div>
      </div>
    </div>
  );
}
