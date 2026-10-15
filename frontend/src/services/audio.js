/**
 * Web Audio API synthesized sounds for mobile study timer
 */

class MobileAudioService {
  constructor() {
    this.ctx = null;
    this.muted = localStorage.getItem('vibe_mobile_muted') === 'true';
  }

  init() {
    if (!this.ctx) {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (AudioCtx) this.ctx = new AudioCtx();
    }
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  }

  isMuted() {
    return this.muted;
  }

  toggleMute() {
    this.muted = !this.muted;
    localStorage.setItem('vibe_mobile_muted', this.muted);
    return this.muted;
  }

  playChime() {
    if (this.muted) return;
    this.init();
    if (!this.ctx) return;

    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(528, now); // Solfeggio 528Hz

    gain.gain.setValueAtTime(0.001, now);
    gain.gain.exponentialRampToValueAtTime(0.28, now + 0.04);
    gain.gain.exponentialRampToValueAtTime(0.0001, now + 2.0);

    osc.connect(gain);
    gain.connect(this.ctx.destination);

    osc.start(now);
    osc.stop(now + 2.1);
  }

  playStageBell() {
    if (this.muted) return;
    this.init();
    if (!this.ctx) return;

    const playTone = (freq, time, dur) => {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      osc.type = 'triangle';
      osc.frequency.setValueAtTime(freq, time);

      gain.gain.setValueAtTime(0.001, time);
      gain.gain.exponentialRampToValueAtTime(0.22, time + 0.03);
      gain.gain.exponentialRampToValueAtTime(0.0001, time + dur);

      osc.connect(gain);
      gain.connect(this.ctx.destination);
      osc.start(time);
      osc.stop(time + dur + 0.1);
    };

    const now = this.ctx.currentTime;
    playTone(659.25, now, 0.7);        // E5
    playTone(880.00, now + 0.22, 1.2); // A5
  }

  playCompletionFanfare() {
    if (this.muted) return;
    this.init();
    if (!this.ctx) return;

    const notes = [523.25, 659.25, 783.99, 1046.50];
    const now = this.ctx.currentTime;

    notes.forEach((freq, idx) => {
      const osc = this.ctx.createOscillator();
      const gain = this.ctx.createGain();
      const noteTime = now + (idx * 0.16);

      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, noteTime);

      gain.gain.setValueAtTime(0.001, noteTime);
      gain.gain.exponentialRampToValueAtTime(0.25, noteTime + 0.04);
      gain.gain.exponentialRampToValueAtTime(0.0001, noteTime + 1.1);

      osc.connect(gain);
      gain.connect(this.ctx.destination);

      osc.start(noteTime);
      osc.stop(noteTime + 1.2);
    });
  }

  playClick() {
    if (this.muted) return;
    this.init();
    if (!this.ctx) return;

    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'triangle';
    osc.frequency.setValueAtTime(400, now);
    osc.frequency.exponentialRampToValueAtTime(100, now + 0.03);

    gain.gain.setValueAtTime(0.06, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.03);

    osc.connect(gain);
    gain.connect(this.ctx.destination);

    osc.start(now);
    osc.stop(now + 0.04);
  }
}

export const audioService = new MobileAudioService();
