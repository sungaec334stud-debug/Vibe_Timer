# SYSTEM PROMPT: Vibe Coding Study & Lab Companion Mobile Web App

## 1. Context & Objective

Act as a Principal Full-Stack Engineer and AI Pedagogical Designer. Using the concepts from the "Vibe Coding" lecture (Andrej Karpathy, Feb 2025), build a modular, production-ready Study Timer and Lab Companion web application optimized for mobile viewports.

The application must operationalize the core philosophies taught in the lecture, specifically:

- Slide 15: The 60-Minute Vibe Coding Lab (Phase 1: Plan 0–10m, Phase 2: Build 10–40m, Phase 3: Audit 40–50m, Phase 4: Reflect 50–60m).
- Slide 14: The Class Rule ("You must be able to explain every line of code").
- Slide 13: Responsible Vibe Coding (Security review, OWASP hygiene, anti-slopsquatting).

---

## 2. Architectural & Directory Separation

Do not write monolithic files. Organize the project into distinct layers within a dedicated root folder (`vibe-study-timer-mobile/`):

1. `/backend`:
   - Lightweight Node.js/Express REST API.
   - Endpoints for session logging (`/api/sessions`), iteration prompt logs (`/api/prompts`), and telemetry statistics (`/api/stats`).
   - Atomic JSON persistence (`db.js`).

2. `/frontend`:
   - React SPA bootstrapped with Vite.
   - Modular component hierarchy:
     - `MobileFrame.jsx`: Hardware chassis wrapper with status bar and notch.
     - `TimerDial.jsx`: SVG circular countdown progress indicator.
     - `LabRoadmap.jsx`: 4-stage visual timeline tracker.
     - `CustomTimerModal.jsx`: In-app duration modal with minutes/seconds input and validation.
     - `QuickPromptSheet.jsx`: Slide-up drawer for logging prompt iterations and runtime errors.
     - `ClassRuleCard.jsx` & `SessionStats.jsx`: Educational guardrails and analytics.
   - Custom Hooks (`useTimer.js`): State machine handling countdown, presets, and phase scheduling.
   - Services (`audio.js`, `api.js`): Synthetic Web Audio API audio chimes and typed API client.

3. `/styles`:
   - Dedicated CSS modules/sheets (`variables.css`, `mobile.css`, `timer.css`, `components.css`).
   - Modern OLED dark-mode palette (#0a0716, violet glow, glassmorphism, responsive typography).

---

## 3. Functional Requirements & Edge-Case Handling

1. **Timer Engine**: High-precision countdown loop resilient to tab throttling, with pause, resume, reset, and phase-skipping.
2. **Custom Time Modal**:
   - Discrete numeric inputs for **Minutes** (0–480) and **Seconds** (0–59).
   - Real-time client-side validation (blocks non-digits, negatives, and durations < 5s or > 8h).
   - Zero reliance on disruptive native browser dialogs (`window.prompt` or `alert`).
3. **Auditory Feedback**: Non-blocking Web Audio API synthesis for start, tick, phase transitions, and completion fanfare.
4. **Network Resilience**: Vite server configured with host broadcast (`--host`) for local Wi-Fi cross-device testing.

---

## 4. Deliverables

- Fully compilable repository with zero lint/build errors.
- Clean `.gitignore` and comprehensive `README.md` containing run commands and network emulation instructions.

```

---
```
