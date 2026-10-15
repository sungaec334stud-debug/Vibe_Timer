import React, { useState } from 'react';

export default function CustomTimerModal({ isOpen, onConfirm, onCancel }) {
  const [minutes, setMinutes] = useState('25');
  const [seconds, setSeconds] = useState('0');
  const [error, setError] = useState('');

  if (!isOpen) return null;

  const handleConfirm = () => {
    setError('');
    const mins = parseInt(minutes, 10);
    const secs = parseInt(seconds, 10);

    if (isNaN(mins) || mins < 0) {
      setError('Please enter a valid number of minutes (0 or more).');
      return;
    }
    if (isNaN(secs) || secs < 0 || secs > 59) {
      setError('Seconds must be between 0 and 59.');
      return;
    }
    const totalSeconds = mins * 60 + secs;
    if (totalSeconds < 5) {
      setError('Total duration must be at least 5 seconds.');
      return;
    }
    if (totalSeconds > 8 * 3600) {
      setError('Maximum duration is 8 hours.');
      return;
    }

    onConfirm(totalSeconds);
  };

  const handleMinutesChange = (e) => {
    const val = e.target.value.replace(/[^0-9]/g, '');
    setMinutes(val);
    setError('');
  };

  const handleSecondsChange = (e) => {
    const val = e.target.value.replace(/[^0-9]/g, '');
    if (val === '' || parseInt(val, 10) <= 59) {
      setSeconds(val);
      setError('');
    }
  };

  return (
    <div style={styles.backdrop} onClick={onCancel}>
      <div style={styles.modal} onClick={e => e.stopPropagation()}>
        {/* Header */}
        <div style={styles.header}>
          <span style={styles.icon}>⏱️</span>
          <div>
            <h2 style={styles.title}>Custom Timer</h2>
            <p style={styles.subtitle}>Set your own study duration</p>
          </div>
        </div>

        {/* Inputs */}
        <div style={styles.inputsRow}>
          <div style={styles.inputGroup}>
            <label style={styles.label}>Minutes</label>
            <input
              type="number"
              inputMode="numeric"
              pattern="[0-9]*"
              min="0"
              max="480"
              value={minutes}
              onChange={handleMinutesChange}
              style={styles.input}
              autoFocus
              placeholder="25"
            />
            <span style={styles.inputSub}>0 – 480</span>
          </div>

          <div style={styles.colon}>:</div>

          <div style={styles.inputGroup}>
            <label style={styles.label}>Seconds</label>
            <input
              type="number"
              inputMode="numeric"
              pattern="[0-9]*"
              min="0"
              max="59"
              value={seconds}
              onChange={handleSecondsChange}
              style={styles.input}
              placeholder="0"
            />
            <span style={styles.inputSub}>0 – 59</span>
          </div>
        </div>

        {/* Quick preset buttons */}
        <div style={styles.quickRow}>
          {[
            { label: '5m', m: 5, s: 0 },
            { label: '10m', m: 10, s: 0 },
            { label: '15m', m: 15, s: 0 },
            { label: '30m', m: 30, s: 0 },
            { label: '45m', m: 45, s: 0 },
            { label: '90m', m: 90, s: 0 },
          ].map(p => (
            <button
              key={p.label}
              style={styles.quickChip}
              onClick={() => { setMinutes(String(p.m)); setSeconds(String(p.s)); setError(''); }}
            >
              {p.label}
            </button>
          ))}
        </div>

        {/* Preview */}
        <div style={styles.preview}>
          {(() => {
            const m = parseInt(minutes, 10) || 0;
            const s = parseInt(seconds, 10) || 0;
            const total = m * 60 + s;
            const dispM = Math.floor(total / 60);
            const dispS = total % 60;
            return total > 0
              ? `⏱ ${String(dispM).padStart(2, '0')}:${String(dispS).padStart(2, '0')} total`
              : 'Enter a duration above';
          })()}
        </div>

        {/* Error */}
        {error && (
          <div style={styles.error}>
            ⚠️ {error}
          </div>
        )}

        {/* Action Buttons */}
        <div style={styles.buttonsRow}>
          <button style={styles.cancelBtn} onClick={onCancel}>
            Cancel
          </button>
          <button style={styles.confirmBtn} onClick={handleConfirm}>
            Set Timer
          </button>
        </div>
      </div>
    </div>
  );
}

const styles = {
  backdrop: {
    position: 'fixed',
    inset: 0,
    background: 'rgba(0, 0, 0, 0.75)',
    backdropFilter: 'blur(6px)',
    WebkitBackdropFilter: 'blur(6px)',
    zIndex: 200,
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    padding: '1.5rem',
    animation: 'fadeInBackdrop 0.2s ease',
  },
  modal: {
    background: 'linear-gradient(145deg, #1a1135 0%, #0e0922 100%)',
    border: '1px solid rgba(139, 92, 246, 0.5)',
    borderRadius: '24px',
    padding: '1.75rem 1.5rem',
    width: '100%',
    maxWidth: '340px',
    boxShadow: '0 20px 60px rgba(0,0,0,0.8), 0 0 40px rgba(139, 92, 246, 0.25)',
    animation: 'slideUpModal 0.3s cubic-bezier(0.16, 1, 0.3, 1)',
  },
  header: {
    display: 'flex',
    alignItems: 'center',
    gap: '0.75rem',
    marginBottom: '1.25rem',
  },
  icon: {
    fontSize: '2rem',
  },
  title: {
    fontFamily: "'Outfit', sans-serif",
    fontSize: '1.2rem',
    fontWeight: 800,
    color: '#ffffff',
    margin: 0,
  },
  subtitle: {
    fontSize: '0.78rem',
    color: '#94a3b8',
    margin: 0,
    marginTop: '0.1rem',
  },
  inputsRow: {
    display: 'flex',
    alignItems: 'center',
    justifyContent: 'center',
    gap: '0.5rem',
    marginBottom: '1.1rem',
  },
  inputGroup: {
    display: 'flex',
    flexDirection: 'column',
    alignItems: 'center',
    gap: '0.3rem',
    flex: 1,
  },
  label: {
    fontSize: '0.72rem',
    fontWeight: 700,
    color: '#a78bfa',
    textTransform: 'uppercase',
    letterSpacing: '0.06em',
  },
  input: {
    width: '100%',
    background: 'rgba(10, 7, 22, 0.9)',
    border: '2px solid rgba(139, 92, 246, 0.4)',
    borderRadius: '12px',
    padding: '0.85rem 0.5rem',
    color: '#ffffff',
    fontFamily: "'JetBrains Mono', monospace",
    fontSize: '2rem',
    fontWeight: 800,
    textAlign: 'center',
    outline: 'none',
    transition: 'border-color 0.2s ease',
    WebkitAppearance: 'none',
    MozAppearance: 'textfield',
  },
  inputSub: {
    fontSize: '0.65rem',
    color: '#64748b',
  },
  colon: {
    fontFamily: "'JetBrains Mono', monospace",
    fontSize: '2rem',
    fontWeight: 800,
    color: '#a78bfa',
    marginTop: '1rem',
    userSelect: 'none',
  },
  quickRow: {
    display: 'flex',
    gap: '0.4rem',
    flexWrap: 'wrap',
    justifyContent: 'center',
    marginBottom: '1rem',
  },
  quickChip: {
    background: 'rgba(139, 92, 246, 0.12)',
    border: '1px solid rgba(139, 92, 246, 0.3)',
    color: '#a78bfa',
    fontSize: '0.8rem',
    fontWeight: 600,
    padding: '0.3rem 0.65rem',
    borderRadius: '9999px',
    cursor: 'pointer',
    transition: 'all 0.15s ease',
  },
  preview: {
    textAlign: 'center',
    fontFamily: "'JetBrains Mono', monospace",
    fontSize: '0.85rem',
    color: '#06b6d4',
    background: 'rgba(6, 182, 212, 0.08)',
    border: '1px solid rgba(6, 182, 212, 0.2)',
    borderRadius: '10px',
    padding: '0.5rem',
    marginBottom: '0.85rem',
  },
  error: {
    background: 'rgba(239, 68, 68, 0.1)',
    border: '1px solid rgba(239, 68, 68, 0.35)',
    color: '#fca5a5',
    fontSize: '0.8rem',
    padding: '0.6rem 0.75rem',
    borderRadius: '10px',
    marginBottom: '0.85rem',
  },
  buttonsRow: {
    display: 'flex',
    gap: '0.75rem',
  },
  cancelBtn: {
    flex: 1,
    background: 'rgba(255,255,255,0.05)',
    border: '1px solid rgba(255,255,255,0.1)',
    color: '#94a3b8',
    fontSize: '0.95rem',
    fontWeight: 600,
    padding: '0.85rem',
    borderRadius: '14px',
    cursor: 'pointer',
  },
  confirmBtn: {
    flex: 2,
    background: 'linear-gradient(135deg, #8b5cf6 0%, #7033ea 100%)',
    border: '1px solid rgba(255,255,255,0.2)',
    color: '#ffffff',
    fontSize: '0.95rem',
    fontWeight: 700,
    padding: '0.85rem',
    borderRadius: '14px',
    cursor: 'pointer',
    boxShadow: '0 4px 15px rgba(139, 92, 246, 0.4)',
  },
};
