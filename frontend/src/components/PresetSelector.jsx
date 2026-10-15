import React from 'react';
import { PRESETS } from '../hooks/useTimer';

export default function PresetSelector({ currentPreset, onSelectPreset }) {
  return (
    <div className="preset-scroll-container">
      {PRESETS.map(preset => {
        const isActive = currentPreset === preset.id;
        return (
          <button
            key={preset.id}
            className={`mobile-preset-chip ${isActive ? 'active' : ''}`}
            onClick={() => onSelectPreset(preset.id)}
          >
            {preset.label}
          </button>
        );
      })}
    </div>
  );
}
