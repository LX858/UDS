import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';

export default function CallScreen() {
  const [duration, setDuration] = useState(0);

  useEffect(() => {
    const timer = setInterval(() => setDuration(d => d + 1), 1000);
    return () => clearInterval(timer);
  }, []);

  const formatDuration = (seconds) => {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  };

  return (
    <motion.div
      className="call-screen"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    >
      <div className="call-content">
        <h2>Contact</h2>
        <p className="call-duration">{formatDuration(duration)}</p>
        <div className="call-buttons">
          <button className="call-btn mute">Mute</button>
          <button className="call-btn speaker">Speaker</button>
          <button className="call-btn end">End Call</button>
        </div>
      </div>
    </motion.div>
  );
}
