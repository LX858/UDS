import React, { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import HomeScreen from './screens/HomeScreen';
import LockScreen from './screens/LockScreen';
import CallScreen from './screens/CallScreen';
import '../styles/phone.css';

export default function Phone({ phoneData, config }) {
  const [isUnlocked, setIsUnlocked] = useState(false);
  const [currentApp, setCurrentApp] = useState(null);
  const [inCall, setInCall] = useState(false);

  return (
    <motion.div
      className="phone-frame"
      initial={{ scale: 0.8, opacity: 0 }}
      animate={{ scale: 1, opacity: 1 }}
      exit={{ scale: 0.8, opacity: 0 }}
      transition={{ duration: 0.3 }}
    >
      <div className="phone-screen">
        {inCall ? (
          <CallScreen />
        ) : !isUnlocked ? (
          <LockScreen onUnlock={() => setIsUnlocked(true)} />
        ) : (
          <HomeScreen currentApp={currentApp} setCurrentApp={setCurrentApp} />
        )}
      </div>
    </motion.div>
  );
}
