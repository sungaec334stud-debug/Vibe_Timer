import React from 'react';

export default function TimerControls({ 
  isRunning, 
  onToggle, 
  onReset, 
  onSkipPhase, 
  showSkipPhase 
}) {
  return (
    <div className="mobile-controls-row">
      <button 
        className="btn-mobile-primary"
        onClick={onToggle}
      >
        {isRunning ? (
          <>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
              <rect x="6" y="4" width="4" height="16" rx="1"></rect>
              <rect x="14" y="4" width="4" height="16" rx="1"></rect>
            </svg>
            Pause
          </>
        ) : (
          <>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
              <polygon points="5 3 19 12 5 21 5 3"></polygon>
            </svg>
            Start
          </>
        )}
      </button>

      {showSkipPhase && (
        <button 
          className="btn-mobile-secondary"
          onClick={onSkipPhase}
          title="Skip to next lab phase"
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
            <polygon points="5 4 15 12 5 20 5 4"></polygon>
            <line x1="19" y1="5" x2="19" y2="19"></line>
          </svg>
          Next
        </button>
      )}

      <button 
        className="btn-mobile-secondary"
        onClick={onReset}
        title="Reset timer"
      >
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
          <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"></path>
          <path d="M3 3v5h5"></path>
        </svg>
        Reset
      </button>
    </div>
  );
}
