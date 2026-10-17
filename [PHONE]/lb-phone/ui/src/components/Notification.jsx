import React, { useEffect } from 'react';
import { motion } from 'framer-motion';

export default function Notification({ data, onDismiss }) {
  useEffect(() => {
    const timer = setTimeout(onDismiss, 5000);
    return () => clearTimeout(timer);
  }, [onDismiss]);

  return (
    <motion.div
      className="notification"
      initial={{ x: 300, opacity: 0 }}
      animate={{ x: 0, opacity: 1 }}
      exit={{ x: 300, opacity: 0 }}
    >
      <div className="notification-content">
        <h4>{data.title}</h4>
        <p>{data.message}</p>
      </div>
    </motion.div>
  );
}
