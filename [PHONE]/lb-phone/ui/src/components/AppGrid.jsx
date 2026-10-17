import React from 'react';
import { motion } from 'framer-motion';
import '../styles/app-grid.css';

const APPS = [
  { id: 'phone',      name: 'Phone',      icon: '📞' },
  { id: 'messages',   name: 'Messages',   icon: '💬' },
  { id: 'camera',     name: 'Camera',     icon: '📷' },
  { id: 'photos',     name: 'Photos',     icon: '🖼️' },
  { id: 'settings',   name: 'Settings',   icon: '⚙️' },
  { id: 'calendar',   name: 'Calendar',   icon: '📅' },
  { id: 'notes',      name: 'Notes',      icon: '📝' },
  { id: 'calculator', name: 'Calculator', icon: '🧮' },
];

const DOCK_APPS = [
  { id: 'phone',    icon: '📞' },
  { id: 'messages', icon: '💬' },
  { id: 'photos',   icon: '🖼️' },
  { id: 'safari',   icon: '🧭' },
];

export default function AppGrid({ onAppSelect }) {
  return (
    <>
      <div className="app-grid">
        {APPS.map((app) => (
          <motion.div
            key={app.id}
            className="app-icon"
            data-app={app.id}
            onClick={() => onAppSelect(app.id)}
            whileTap={{ scale: 0.88 }}
          >
            <div className="icon-wrapper">{app.icon}</div>
            <span>{app.name}</span>
          </motion.div>
        ))}
      </div>

      <div className="app-dock">
        <div className="dock-inner">
          {DOCK_APPS.map((app) => (
            <motion.div
              key={app.id}
              className="dock-icon"
              onClick={() => onAppSelect(app.id)}
              whileTap={{ scale: 0.88 }}
            >
              {app.icon}
            </motion.div>
          ))}
        </div>
      </div>
    </>
  );
}
