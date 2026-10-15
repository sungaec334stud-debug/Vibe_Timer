import React, { useState, useEffect, useCallback } from 'react';
import './styles/variables.css';
import './styles/mobile.css';
import './styles/timer.css';
import './styles/components.css';

import MobileFrame from './components/MobileFrame';
import PresetSelector from './components/PresetSelector';
import TimerDial from './components/TimerDial';
import TimerControls from './components/TimerControls';
import LabRoadmap from './components/LabRoadmap';
import ClassRuleCard from './components/ClassRuleCard';
import SessionStats from './components/SessionStats';
import QuickPromptSheet from './components/QuickPromptSheet';

import { useTimer } from './hooks/useTimer';
import { audioService } from './services/audio';
import { api } from './services/api';

export default function App() {
  const [toastMessage, setToastMessage] = useState(null);
  const [soundMuted, setSoundMuted] = useState(audioService.isMuted());
  const [isPromptSheetOpen, setIsPromptSheetOpen] = useState(false);
  const [prompts, setPrompts] = useState([]);
  const [stats, setStats] = useState({ totalMinutes: 0, totalSessions: 0, totalPrompts: 0 });

  const showToast = useCallback((msg) => {
    setToastMessage(msg);
    setTimeout(() => {
      setToastMessage(null);
    }, 2800);
  }, []);

  const {
    timeFormatted,
    progressFraction,
    isRunning,
    currentPreset,
    currentPhase,
    currentPhaseIndex,
    toggle,
    reset,
    skipPhase,
    selectPreset
  } = useTimer(showToast);

  // Sync document title with active time
  useEffect(() => {
    document.title = `(${timeFormatted}) Vibe Timer`;
  }, [timeFormatted]);

  // Load initial stats & prompts
  const refreshData = useCallback(async () => {
    try {
      const [statsRes, promptsRes] = await Promise.all([
        api.getStats(),
        api.getPrompts()
      ]);
      if (statsRes?.stats) setStats(statsRes.stats);
      if (promptsRes?.prompts) setPrompts(promptsRes.prompts);
    } catch (err) {
      console.warn('Initial data load failed:', err);
    }
  }, []);

  useEffect(() => {
    refreshData();
  }, [refreshData]);

  const handleToggleSound = () => {
    const next = audioService.toggleMute();
    setSoundMuted(next);
    showToast(next ? 'Sound Muted' : 'Audio Chime Enabled');
  };

  const handlePromptAdded = (newPrompt) => {
    setPrompts(prev => [newPrompt, ...prev]);
    setStats(prev => ({
      ...prev,
      totalPrompts: (prev.totalPrompts || 0) + 1
    }));
  };

  const isLabActive = currentPreset === 'vibe_lab_60';

  return (
    <MobileFrame 
      soundMuted={soundMuted}
      onToggleSound={handleToggleSound}
      onOpenPromptSheet={() => setIsPromptSheetOpen(true)}
    >
      {/* Toast popup */}
      {toastMessage && (
        <div className="mobile-toast">
          ⚡ {toastMessage}
        </div>
      )}

      {/* Preset Scroll Selector */}
      <PresetSelector 
        currentPreset={currentPreset}
        onSelectPreset={selectPreset}
      />

      {/* Main Circular SVG Timer Dial */}
      <div className="timer-section">
        <TimerDial 
          timeFormatted={timeFormatted}
          progressFraction={progressFraction}
          isRunning={isRunning}
          currentPreset={currentPreset}
          currentPhase={currentPhase}
        />

        {/* Action Controls */}
        <TimerControls 
          isRunning={isRunning}
          onToggle={toggle}
          onReset={reset}
          onSkipPhase={skipPhase}
          showSkipPhase={isLabActive}
        />
      </div>

      {/* 60m Lab Roadmap (Only shown during Vibe Lab mode) */}
      <LabRoadmap 
        currentPhaseIndex={currentPhaseIndex}
        isLabActive={isLabActive}
      />

      {/* Class Rule Card (Slide 14) */}
      <ClassRuleCard />

      {/* Bottom Study Metrics Summary */}
      <SessionStats stats={stats} />

      {/* Slide-Up Bottom Drawer for Prompts / Error Feedback */}
      <QuickPromptSheet 
        isOpen={isPromptSheetOpen}
        onClose={() => setIsPromptSheetOpen(false)}
        currentPhaseId={currentPhase?.id}
        prompts={prompts}
        onPromptAdded={handlePromptAdded}
        onToast={showToast}
      />
    </MobileFrame>
  );
}
