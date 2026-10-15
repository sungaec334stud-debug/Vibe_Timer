/**
 * REST API Client for Mobile Study Timer
 */

const API_BASE = '/api';

export const api = {
  async getSessions() {
    try {
      const res = await fetch(`${API_BASE}/sessions`);
      if (!res.ok) throw new Error('Network error');
      return await res.json();
    } catch {
      const local = JSON.parse(localStorage.getItem('vibe_m_sessions') || '[]');
      return {
        success: true,
        sessions: local,
        stats: {
          totalMinutes: local.reduce((a, b) => a + (Number(b.durationMinutes) || 0), 0),
          totalSessions: local.length,
          lastSession: local[0] || null
        }
      };
    }
  },

  async logSession(data) {
    try {
      const res = await fetch(`${API_BASE}/sessions`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });
      if (!res.ok) throw new Error('Failed to save');
      return await res.json();
    } catch {
      const local = JSON.parse(localStorage.getItem('vibe_m_sessions') || '[]');
      const newSess = {
        id: 'sess_' + Date.now(),
        completedAt: new Date().toISOString(),
        ...data
      };
      local.unshift(newSess);
      localStorage.setItem('vibe_m_sessions', JSON.stringify(local));
      return { success: true, session: newSess };
    }
  },

  async getPrompts() {
    try {
      const res = await fetch(`${API_BASE}/prompts`);
      if (!res.ok) throw new Error('Network error');
      return await res.json();
    } catch {
      const local = JSON.parse(localStorage.getItem('vibe_m_prompts') || '[]');
      return { success: true, prompts: local };
    }
  },

  async logPrompt(data) {
    try {
      const res = await fetch(`${API_BASE}/prompts`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });
      if (!res.ok) throw new Error('Failed to save');
      return await res.json();
    } catch {
      const local = JSON.parse(localStorage.getItem('vibe_m_prompts') || '[]');
      const newPrompt = {
        id: 'p_' + Date.now(),
        timestamp: new Date().toISOString(),
        ...data
      };
      local.unshift(newPrompt);
      localStorage.setItem('vibe_m_prompts', JSON.stringify(local));
      return { success: true, prompt: newPrompt };
    }
  },

  async getStats() {
    try {
      const res = await fetch(`${API_BASE}/stats`);
      if (!res.ok) throw new Error('Network error');
      return await res.json();
    } catch {
      const localSessions = JSON.parse(localStorage.getItem('vibe_m_sessions') || '[]');
      const localPrompts = JSON.parse(localStorage.getItem('vibe_m_prompts') || '[]');
      return {
        success: true,
        stats: {
          totalMinutes: localSessions.reduce((a, b) => a + (Number(b.durationMinutes) || 0), 0),
          totalSessions: localSessions.length,
          totalPrompts: localPrompts.length
        }
      };
    }
  }
};
