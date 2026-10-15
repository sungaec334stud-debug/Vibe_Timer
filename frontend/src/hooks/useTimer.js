import { useState, useEffect, useRef, useCallback } from 'react';
import { audioService } from '../services/audio';
import { api } from '../services/api';

export const LAB_PHASES = [
  { id: 'plan', title: 'Plan', timeTag: '0–10 min', startSec: 0, endSec: 10 * 60, tip: 'Draft your prompt spec: Context, Goal & Constraints' },
  { id: 'build', title: 'Build', timeTag: '10–40 min', startSec: 10 * 60, endSec: 40 * 60, tip: 'Iterate with AI, commit often & feed back errors' },
  { id: 'audit', title: 'Audit', timeTag: '40–50 min', startSec: 40 * 60, endSec: 50 * 60, tip: 'Security check: OWASP Top 10 & slopsquatting' },
  { id: 'reflect', title: 'Reflect', timeTag: '50–60 min', startSec: 50 * 60, endSec: 60 * 60, tip: 'Class Rule: Explain every line before submitting' }
];

export const PRESETS = [
  { id: 'vibe_lab_60', label: '⚡ 60m Vibe Lab', minutes: 60 },
  { id: 'pomodoro_25', label: '🍅 25m Pomodoro', minutes: 25 },
  { id: 'deep_50', label: '🎯 50m Deep Work', minutes: 50 },
  { id: 'sprint_15', label: '🚀 15m Sprint', minutes: 15 },
  { id: 'custom', label: '⚙️ Custom', minutes: 45 }
];

export function useTimer(onToast) {
  const [currentPreset, setCurrentPreset] = useState('vibe_lab_60');
  const [totalDuration, setTotalDuration] = useState(60 * 60);
  const [remainingSeconds, setRemainingSeconds] = useState(60 * 60);
  const [isRunning, setIsRunning] = useState(false);
  const [currentPhaseIndex, setCurrentPhaseIndex] = useState(0);

  const lastTimeRef = useRef(null);

  const currentPhase = LAB_PHASES[currentPhaseIndex];

  // Set Preset
  const selectPreset = useCallback((presetId) => {
    setIsRunning(false);
    setCurrentPreset(presetId);
    let mins = 60;

    if (presetId === 'custom') {
      const input = window.prompt('Enter study duration in minutes:', '45');
      const parsed = parseInt(input, 10);
      mins = parsed && parsed > 0 ? parsed : 45;
    } else {
      const match = PRESETS.find(p => p.id === presetId);
      if (match) mins = match.minutes;
    }

    const dur = mins * 60;
    setTotalDuration(dur);
    setRemainingSeconds(dur);
    setCurrentPhaseIndex(0);

    if (onToast) onToast(`Timer set to ${mins} minutes`);
  }, [onToast]);

  // Toggle Start / Pause
  const toggle = useCallback(() => {
    setIsRunning(prev => {
      const next = !prev;
      if (next) {
        audioService.playChime();
        lastTimeRef.current = Date.now();
      } else {
        audioService.playClick();
      }
      return next;
    });
  }, []);

  // Reset
  const reset = useCallback(() => {
    setIsRunning(false);
    setRemainingSeconds(totalDuration);
    setCurrentPhaseIndex(0);
    audioService.playClick();
    if (onToast) onToast('Timer reset');
  }, [totalDuration, onToast]);

  // Skip Phase (for 60m lab)
  const skipPhase = useCallback(() => {
    if (currentPreset !== 'vibe_lab_60') return;
    if (currentPhaseIndex < LAB_PHASES.length - 1) {
      const nextIdx = currentPhaseIndex + 1;
      const nextPhase = LAB_PHASES[nextIdx];
      setCurrentPhaseIndex(nextIdx);
      setRemainingSeconds(totalDuration - nextPhase.startSec);
      audioService.playStageBell();
      if (onToast) onToast(`Skipped to ${nextPhase.title}`);
    }
  }, [currentPreset, currentPhaseIndex, totalDuration, onToast]);

  // Timer Tick Loop
  useEffect(() => {
    if (!isRunning) return;

    const interval = setInterval(() => {
      const now = Date.now();
      const elapsed = (now - (lastTimeRef.current || now)) / 1000;
      lastTimeRef.current = now;

      setRemainingSeconds(prev => {
        const next = prev - elapsed;
        if (next <= 0) {
          // Finished
          setIsRunning(false);
          audioService.playCompletionFanfare();
          if (onToast) onToast('🎉 Session Complete! Awesome vibe focus.');

          // Log session to backend
          api.logSession({
            mode: currentPreset,
            title: currentPreset === 'vibe_lab_60' ? '60-Minute Vibe Coding Lab' : `${Math.round(totalDuration / 60)}m Focus`,
            durationMinutes: Math.round(totalDuration / 60)
          });

          return 0;
        }

        // Check phase transitions in 60-min lab
        if (currentPreset === 'vibe_lab_60') {
          const elapsedSec = totalDuration - next;
          const idx = LAB_PHASES.findIndex(p => elapsedSec >= p.startSec && elapsedSec < p.endSec);
          if (idx !== -1 && idx !== currentPhaseIndex) {
            setCurrentPhaseIndex(idx);
            audioService.playStageBell();
            if (onToast) onToast(`Entering ${LAB_PHASES[idx].title}`);
          }
        }

        return next;
      });
    }, 250);

    return () => clearInterval(interval);
  }, [isRunning, currentPreset, totalDuration, currentPhaseIndex, onToast]);

  // Format Time display
  const totalSec = Math.max(0, Math.ceil(remainingSeconds));
  const mins = Math.floor(totalSec / 60);
  const secs = totalSec % 60;
  const timeFormatted = `${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;

  // Calculate circular progress (0 to 1)
  const progressFraction = (totalDuration - remainingSeconds) / totalDuration;

  return {
    timeFormatted,
    progressFraction,
    remainingSeconds,
    totalDuration,
    isRunning,
    currentPreset,
    currentPhase,
    currentPhaseIndex,
    toggle,
    reset,
    skipPhase,
    selectPreset
  };
}
