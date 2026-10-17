import React, { useState } from 'react';
import { motion } from 'framer-motion';

export default function LockScreen({ onUnlock }) {
  const [time, setTime] = useState(new Date());

  React.useEffect(() => {
    const timer = setInterval(() => setTime(new Date()), 1000);
    return () => clearInterval(timer);
  }, []);

  const hours = time.getHours().toString().padStart(2, '0');
  const minutes = time.getMinutes().toString().padStart(2, '0');
  const dateStr = time.toLocaleDateString('en-US', {
    weekday: 'long', month: 'long', day: 'numeric',
  });

  return (
    <motion.div
      className="lock-screen"
      onClick={onUnlock}
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    >
      <div className="lock-content">
        <h1>{hours}:{minutes}</h1>
        <p>{dateStr}</p>
      </div>

      <div className="lock-actions">
        <div className="lock-action-btn">🔦</div>
        <div className="lock-action-btn">📷</div>
      </div>

      <div className="lock-unlock-hint">Swipe up to unlock</div>
    </motion.div>
  );
}
