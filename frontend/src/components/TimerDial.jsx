import React from 'react';

export default function TimerDial({ 
  timeFormatted, 
  progressFraction, 
  isRunning, 
  currentPreset, 
  currentPhase 
}) {
  const RADIUS = 115;
  const CIRCUMFERENCE = 2 * Math.PI * RADIUS; // ~722.566
  const strokeOffset = CIRCUMFERENCE * (1 - progressFraction);

  let stageLabel = 'Focus Session';
  let stageTip = 'Stay in the flow state.';

  if (currentPreset === 'vibe_lab_60' && currentPhase) {
    stageLabel = `PHASE: ${currentPhase.title.toUpperCase()} (${currentPhase.timeTag})`;
    stageTip = currentPhase.tip;
  } else if (currentPreset === 'pomodoro_25') {
    stageLabel = 'Pomodoro Focus (25m)';
    stageTip = 'Work on one task with zero distractions.';
  } else if (currentPreset === 'deep_50') {
    stageLabel = 'Deep Work (50m)';
    stageTip = 'Deep cognitive immersion and code writing.';
  } else if (currentPreset === 'sprint_15') {
    stageLabel = 'Review Sprint (15m)';
    stageTip = 'Audit diffs and test app behavior.';
  }

  return (
    <div className="mobile-timer-dial">
      <svg className="dial-svg" viewBox="0 0 270 270">
        <defs>
          <linearGradient id="mobileTimerGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <stop offset="0%" stopColor="#8b5cf6" />
            <stop offset="60%" stopColor="#a78bfa" />
            <stop offset="100%" stopColor="#06b6d4" />
          </linearGradient>
        </defs>

        {/* Background Track */}
        <circle 
          className="dial-bg-ring" 
          cx="135" 
          cy="135" 
          r={RADIUS} 
        />

        {/* Animated Progress Ring */}
        <circle 
          className={`dial-progress-ring ${isRunning ? 'is-running-glow' : ''}`}
          cx="135" 
          cy="135" 
          r={RADIUS}
          style={{
            strokeDasharray: CIRCUMFERENCE,
            strokeDashoffset: strokeOffset
          }}
        />
      </svg>

      <div className="dial-inner-content">
        <div className="dial-digits">{timeFormatted}</div>
        <div className="dial-stage-badge">
          {stageLabel}
        </div>
        <div className="dial-guidance-tip">
          {stageTip}
        </div>
      </div>
    </div>
  );
}
