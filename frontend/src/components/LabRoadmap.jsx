import React from 'react';
import { LAB_PHASES } from '../hooks/useTimer';

export default function LabRoadmap({ currentPhaseIndex, isLabActive }) {
  if (!isLabActive) return null;

  return (
    <div className="mobile-card">
      <div className="mobile-card-header">
        <h2 className="mobile-card-title">
          <span>⚡</span>
          <span>60-Min Vibe Lab Roadmap</span>
        </h2>
        <span style={{ fontSize: '0.7rem', color: 'var(--accent-purple-light)', fontFamily: 'var(--font-mono)' }}>
          SLIDE 15
        </span>
      </div>

      <div className="mobile-roadmap">
        {LAB_PHASES.map((phase, idx) => {
          const isActive = idx === currentPhaseIndex;
          const isCompleted = idx < currentPhaseIndex;

          return (
            <div 
              key={phase.id} 
              className={`roadmap-step ${isActive ? 'active' : ''} ${isCompleted ? 'completed' : ''}`}
            >
              <div className="step-badge">
                {isCompleted ? '✓' : `0${idx + 1}`}
              </div>
              <div className="step-details">
                <div className="step-top-line">
                  <span className="step-name">{phase.title}</span>
                  <span className="step-duration">{phase.timeTag}</span>
                </div>
                <div className="step-summary">{phase.tip}</div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
