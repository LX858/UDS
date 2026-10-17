import React, { useState, useEffect } from 'react';
import { AnimatePresence, motion } from 'framer-motion';
import Phone from './components/Phone';
import './App.css';

const IS_DEV = import.meta.env.DEV;

export default function App() {
  const [isVisible, setIsVisible] = useState(IS_DEV);
  const [phoneData, setPhoneData] = useState(IS_DEV ? {} : null);
  const [config, setConfig] = useState(IS_DEV ? {} : null);

  useEffect(() => {
    const handler = (event) => {
      if (event.data?.action === 'setPhoneData') {
        setPhoneData(event.data.data);
      } else if (event.data?.action === 'setConfig') {
        setConfig(event.data.data);
      } else if (event.data?.action === 'openPhone') {
        setIsVisible(true);
      } else if (event.data?.action === 'closePhone') {
        setIsVisible(false);
      }
    };
    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  if (!phoneData || !config) {
    return <div style={{ display: 'none' }} />;
  }

  return (
    <div className="app-container">
      <div className="aurora" />
      <AnimatePresence>
        {isVisible && (
          <Phone phoneData={phoneData} config={config} />
        )}
      </AnimatePresence>
    </div>
  );
}
