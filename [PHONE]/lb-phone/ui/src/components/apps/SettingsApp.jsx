import React, { useState } from 'react';

export default function SettingsApp() {
  const [settings, setSettings] = useState({
    brightness: 100,
    theme: 'light',
    notifications: true,
    sound: true,
    doNotDisturb: false,
  });

  const handleSettingChange = (setting, value) => {
    setSettings({ ...settings, [setting]: value });
  };

  return (
    <div className="settings-app">
      <div className="app-header">
        <h2>Settings</h2>
      </div>
      <div className="settings-content">
        <div className="setting-item">
          <label>Brightness</label>
          <input
            type="range"
            min="0"
            max="100"
            value={settings.brightness}
            onChange={(e) => handleSettingChange('brightness', e.target.value)}
          />
        </div>
        <div className="setting-item">
          <label>Theme</label>
          <select value={settings.theme} onChange={(e) => handleSettingChange('theme', e.target.value)}>
            <option>Light</option>
            <option>Dark</option>
            <option>Auto</option>
          </select>
        </div>
        <div className="setting-item">
          <label>Notifications</label>
          <input
            type="checkbox"
            checked={settings.notifications}
            onChange={(e) => handleSettingChange('notifications', e.target.checked)}
          />
        </div>
        <div className="setting-item">
          <label>Sound</label>
          <input
            type="checkbox"
            checked={settings.sound}
            onChange={(e) => handleSettingChange('sound', e.target.checked)}
          />
        </div>
        <div className="setting-item">
          <label>Do Not Disturb</label>
          <input
            type="checkbox"
            checked={settings.doNotDisturb}
            onChange={(e) => handleSettingChange('doNotDisturb', e.target.checked)}
          />
        </div>
      </div>
    </div>
  );
}
