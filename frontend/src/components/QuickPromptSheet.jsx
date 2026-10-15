import React, { useState } from 'react';
import { api } from '../services/api';

export default function QuickPromptSheet({ isOpen, onClose, currentPhaseId, prompts, onPromptAdded, onToast }) {
  const [promptText, setPromptText] = useState('');
  const [outcome, setOutcome] = useState('');
  const [phase, setPhase] = useState(currentPhaseId || 'build');

  if (!isOpen) return null;

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!promptText.trim()) {
      if (onToast) onToast('Please enter prompt text first');
      return;
    }

    try {
      const res = await api.logPrompt({
        phase,
        text: promptText.trim(),
        outcome: outcome.trim()
      });

      if (res && res.success) {
        onPromptAdded(res.prompt);
        setPromptText('');
        setOutcome('');
        if (onToast) onToast('Prompt logged to session!');
      }
    } catch {
      if (onToast) onToast('Failed to save prompt');
    }
  };

  return (
    <div className="sheet-backdrop" onClick={onClose}>
      <div className="sheet-container" onClick={e => e.stopPropagation()}>
        <div className="sheet-drag-handle"></div>

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h2 style={{ fontSize: '1rem', fontWeight: 700, color: '#fff' }}>
            ✍️ Quick Prompt & Error Log
          </h2>
          <button 
            onClick={onClose}
            style={{ background: 'transparent', border: 'none', color: 'var(--text-muted)', fontSize: '1.2rem', cursor: 'pointer' }}
          >
            ✕
          </button>
        </div>

        <p style={{ fontSize: '0.75rem', color: 'var(--text-muted)' }}>
          Record prompts or paste error tracebacks to feed back to AI (Slide 9 Demo pattern).
        </p>

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '0.65rem' }}>
          <select 
            className="mobile-input" 
            value={phase} 
            onChange={e => setPhase(e.target.value)}
          >
            <option value="plan">Phase 1: Plan</option>
            <option value="build">Phase 2: Build (Code / Error)</option>
            <option value="audit">Phase 3: Audit (Security)</option>
            <option value="reflect">Phase 4: Reflect</option>
          </select>

          <textarea
            className="mobile-textarea"
            placeholder="Enter the prompt or paste error traceback here..."
            value={promptText}
            onChange={e => setPromptText(e.target.value)}
          />

          <input
            type="text"
            className="mobile-input"
            placeholder="Outcome (e.g. AI fixed 500 error / created database)"
            value={outcome}
            onChange={e => setOutcome(e.target.value)}
          />

          <button 
            type="submit" 
            className="btn-mobile-primary"
            style={{ width: '100%', maxWidth: 'none', padding: '0.7rem' }}
          >
            + Record Prompt Iteration
          </button>
        </form>

        {/* Existing Prompts list */}
        {prompts && prompts.length > 0 && (
          <div style={{ marginTop: '0.5rem', maxHeight: '160px', overflowY: 'auto' }}>
            <div style={{ fontSize: '0.75rem', fontWeight: 700, color: 'var(--accent-purple-light)', marginBottom: '0.35rem' }}>
              Logged This Session ({prompts.length}):
            </div>
            {prompts.map((p, idx) => (
              <div 
                key={p.id || idx}
                style={{ 
                  background: 'rgba(255,255,255,0.03)', 
                  border: '1px solid rgba(255,255,255,0.05)',
                  padding: '0.5rem',
                  borderRadius: 'var(--radius-sm)',
                  marginBottom: '0.4rem',
                  fontSize: '0.75rem'
                }}
              >
                <div style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--accent-cyan)', fontWeight: 600 }}>
                  <span>#{idx + 1} [{p.phase?.toUpperCase()}]</span>
                  <span style={{ color: 'var(--text-dim)', fontSize: '0.65rem' }}>
                    {new Date(p.timestamp).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                  </span>
                </div>
                <div style={{ fontFamily: 'var(--font-mono)', color: '#e2e8f0', marginTop: '0.2rem' }}>
                  {p.text}
                </div>
                {p.outcome && (
                  <div style={{ color: 'var(--color-success)', marginTop: '0.15rem' }}>
                    ↳ {p.outcome}
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
