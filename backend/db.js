const fs = require('fs');
const path = require('path');

const DATA_DIR = path.join(__dirname, 'data');
const DB_FILE = path.join(DATA_DIR, 'store.json');

if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR, { recursive: true });
}

const defaultData = {
  sessions: [
    {
      id: "sess_1",
      mode: "vibe_lab_60",
      title: "60-Min Vibe Lab Demo",
      durationMinutes: 60,
      completedAt: new Date(Date.now() - 3600000 * 2).toISOString(),
      notes: "Completed Plan, Build, Audit, and Reflect stages"
    }
  ],
  prompts: [
    {
      id: "prompt_1",
      phase: "plan",
      text: "Build a single-page study timer for mobile with 60-min lab stages",
      outcome: "Generated React mobile scaffold",
      timestamp: new Date(Date.now() - 3600000).toISOString()
    }
  ]
};

function readDb() {
  try {
    if (!fs.existsSync(DB_FILE)) {
      fs.writeFileSync(DB_FILE, JSON.stringify(defaultData, null, 2), 'utf-8');
      return defaultData;
    }
    return JSON.parse(fs.readFileSync(DB_FILE, 'utf-8'));
  } catch (err) {
    console.error('Error reading db:', err);
    return defaultData;
  }
}

function writeDb(data) {
  try {
    fs.writeFileSync(DB_FILE, JSON.stringify(data, null, 2), 'utf-8');
    return true;
  } catch (err) {
    console.error('Error writing db:', err);
    return false;
  }
}

module.exports = {
  getSessions() {
    return readDb().sessions || [];
  },

  addSession(session) {
    const data = readDb();
    const newSession = {
      id: 'sess_' + Date.now(),
      completedAt: new Date().toISOString(),
      ...session
    };
    data.sessions = [newSession, ...(data.sessions || [])];
    writeDb(data);
    return newSession;
  },

  getPrompts() {
    return readDb().prompts || [];
  },

  addPrompt(prompt) {
    const data = readDb();
    const newPrompt = {
      id: 'p_' + Date.now(),
      timestamp: new Date().toISOString(),
      ...prompt
    };
    data.prompts = [newPrompt, ...(data.prompts || [])];
    writeDb(data);
    return newPrompt;
  },

  getStats() {
    const sessions = readDb().sessions || [];
    const prompts = readDb().prompts || [];
    const totalMinutes = sessions.reduce((acc, curr) => acc + (Number(curr.durationMinutes) || 0), 0);
    return {
      totalMinutes,
      totalSessions: sessions.length,
      totalPrompts: prompts.length,
      lastSession: sessions[0] || null
    };
  }
};
