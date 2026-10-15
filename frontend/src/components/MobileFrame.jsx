import React, { useState, useEffect } from 'react';

export default function MobileFrame({ children, soundMuted, onToggleSound, onOpenPromptSheet }) {
  const [currentTime, setCurrentTime] = useState('9:41');
  const [flatMode, setFlatMode] = useState(false);

  useEffect(() => {
    const update = () => {
      const now = new Date();
      const hrs = now.getHours();
      const mins = String(now.getMinutes()).padStart(2, '0');
      setCurrentTime(`${hrs}:${mins}`);
    };
    update();
    const interval = setInterval(update, 30000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="mobile-simulator-wrapper">
      {/* Top Desktop Toolbar */}
      <div className="simulator-toolbar">
        <div className="toolbar-brand">
          <span>📱</span>
          <span>VIBE MOBILE</span>
        </div>
        <button 
          className="toolbar-toggle-btn"
          onClick={() => setFlatMode(prev => !prev)}
          title="Toggle phone chassis styling"
        >
          {flatMode ? 'Show Phone Frame' : 'Full Mobile Mode'}
        </button>
      </div>

      {/* Mobile Device Chassis */}
      <div className={`mobile-device ${flatMode ? 'flat-mode' : ''}`}>
        {/* Status Bar */}
        <div className="mobile-status-bar">
          <span className="status-time">{currentTime}</span>
          <div className="dynamic-island">
            <div className="island-camera"></div>
            <div className="island-sensor"></div>
          </div>
          <div className="status-icons">
            <span>5G</span>
            <span>📶</span>
            <span>🔋</span>
          </div>
        </div>

        {/* Mobile App Header */}
        <header className="mobile-header">
          <div className="app-title-group">
            <span className="app-badge">&gt;_ APPLICATION DEV</span>
            <h1 className="app-heading">Vibe Timer</h1>
          </div>
          <div style={{ display: 'flex', gap: '0.4rem' }}>
            <button 
              className="header-action-btn"
              onClick={onToggleSound}
              title={soundMuted ? 'Unmute Sound' : 'Mute Sound'}
            >
              {soundMuted ? '🔇' : '🔊'}
            </button>
            <button 
              className="header-action-btn"
              onClick={onOpenPromptSheet}
              title="Quick Log Prompt / Error"
            >
              ✍️
            </button>
          </div>
        </header>

        {/* Main Scrollable Content */}
        <div className="mobile-content">
          {children}
        </div>

        {/* Bottom Home Indicator */}
        <div className="mobile-home-bar">
          <div className="home-indicator-pill"></div>
        </div>
      </div>
    </div>
  );
}
