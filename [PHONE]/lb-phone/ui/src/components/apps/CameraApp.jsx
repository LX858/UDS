import React, { useState } from 'react';

export default function CameraApp() {
  const [photoMode, setPhotoMode] = useState(true);
  const [cameraFacing, setCameraFacing] = useState('back');

  return (
    <div className="camera-app">
      <div className="camera-display">
        <div className="camera-placeholder">Camera View</div>
      </div>
      <div className="camera-controls">
        <div className="mode-buttons">
          <button className={photoMode ? 'active' : ''} onClick={() => setPhotoMode(true)}>
            Photo
          </button>
          <button className={!photoMode ? 'active' : ''} onClick={() => setPhotoMode(false)}>
            Video
          </button>
        </div>
        <div className="camera-actions">
          <button className="camera-button" title="Capture">📷</button>
          <button className="flip-button" onClick={() => setCameraFacing(cameraFacing === 'back' ? 'front' : 'back')}>
            🔄
          </button>
          <button className="flash-button" title="Flash">⚡</button>
        </div>
      </div>
    </div>
  );
}
