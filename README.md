# 📱 Vibe Study Timer — Mobile React App

> **"Building software by describing what you want — and knowing when to look under the hood."**  
> A dedicated mobile study timer built in **React**, structured directly around the **60-Minute Vibe Coding Lab** (Slide 15) and lessons from Andrej Karpathy's lecture.

---

## 🌟 Highlights & Features

- **Mobile First / Native Mobile UI:** Designed for phone viewports with mobile status bar, dynamic island, touch-friendly dial, and smooth animations.
- **60-Minute Vibe Coding Lab Timer (Slide 15):** Tracks the 4 structured phases of vibe-coding:
  - `0–10 min` **Phase 1: Plan** — Formulate prompt anatomy (Context, Goal, Constraints, Example, Done when).
  - `10–40 min` **Phase 2: Build** — Fast AI iterations, frequent Git commits, and feeding runtime errors back.
  - `40–50 min` **Phase 3: Audit** — Security checks against OWASP Top 10 flaws and slopsquatting.
  - `50–60 min` **Phase 4: Reflect** — Complete reflection and defend your code.
- **Study Presets:** Includes 60m Vibe Lab, 25m Pomodoro, 50m Deep Work, 15m Sprint, and Custom time.
- **Quick Prompt & Error Logger:** Slide-up bottom sheet allowing you to log prompt iterations or paste error tracebacks on the fly.
- **Class Rule Banner (Slide 14):** *"You may vibe code. You may not submit code you can't explain."*
- **Web Audio API Chimes:** Pure client-side synthetic Tibetan bowl tones and double bell stage transition alerts.
- **Mobile Viewport Switcher:** Easily toggle between Phone Device frame mode and flat mobile mode.

---

## 🗂️ Clean Separation of Components & Functions

```
vibe-study-timer-mobile/
├── package.json
├── README.md
│
├── backend/                       # BACKEND (Node.js API)
│   ├── server.js                  # Lightweight HTTP API server (Port 3001)
│   └── db.js                      # Persistent JSON storage for sessions & prompts
│
└── frontend/                      # FRONTEND (React + Vite)
    ├── vite.config.js             # Vite configuration with port 5173 & API proxy
    ├── index.html                 # Mobile-optimized HTML
    └── src/
        ├── main.jsx               # React entry point
        ├── App.jsx                # Main mobile application orchestrator
        │
        ├── styles/                # CSS DESIGN SYSTEM
        │   ├── variables.css      # OLED theme tokens & typography
        │   ├── mobile.css         # Phone chassis, status bar & layout
        │   ├── timer.css          # Circular SVG dial & controls
        │   └── components.css     # Roadmap, bottom sheet & cards
        │
        ├── services/              # FUNCTIONAL SERVICES
        │   ├── audio.js           # Web Audio API chime synthesis
        │   └── api.js             # REST API client
        │
        ├── hooks/                 # REACT CUSTOM HOOKS
        │   └── useTimer.js        # Countdown, phase tracker & preset logic
        │
        └── components/            # MODULAR REACT COMPONENTS
            ├── MobileFrame.jsx    # Phone frame, dynamic island & clock
            ├── TimerDial.jsx      # SVG circular progress ring & digits
            ├── TimerControls.jsx  # Play/Pause, Next Phase & Reset
            ├── PresetSelector.jsx # Horizontal preset chips
            ├── LabRoadmap.jsx     # 4-stage 60m lab tracker
            ├── ClassRuleCard.jsx  # Slide 14 class rule banner
            ├── QuickPromptSheet.jsx # Slide-up prompt/error log drawer
            └── SessionStats.jsx   # Focus minutes & sessions summary
```

---

## 🚀 Running the App

### 1. Start the Backend API (Port 3001)
```bash
node backend/server.js
```

### 2. Start the Frontend React Dev Server (Port 5173)
```bash
cd frontend
npm run dev
```

Open your browser at:
👉 **[http://localhost:5173](http://localhost:5173)**  
*(As shown in Slide 1: `[ok] running at localhost:5173`)*
