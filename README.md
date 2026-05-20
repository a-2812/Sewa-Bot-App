# SewaBot — AI Service Orchestrator for Pakistan's Informal Economy

**Google Antigravity Hackathon 2026 | Challenge 2**

SewaBot connects users with local service providers (plumbers, electricians, AC technicians, tutors, beauticians, carpenters) using a 6-agent AI pipeline powered by Gemini 2.5 Flash.

---

## Project Structure

```
repo/
├── lib/                          # Flutter mobile/web app
│   ├── config/app_config.dart    # Env-configurable URLs (--dart-define)
│   ├── screens/                  # All screens (auth, user, provider, shared)
│   ├── services/agent_service.dart
│   └── providers/app_state.dart
├── Sewa-Bot-App-agents/agents/   # Python AI agents — port 8001
│   ├── main_api.py               # FastAPI agents API
│   ├── orchestrator.py           # Pipeline coordinator
│   ├── intent_agent.py           # Multilingual intent extraction
│   ├── discovery_agent.py        # Provider search
│   ├── ranking_agent.py          # Multi-factor scoring
│   ├── quote_agent.py            # Price calculation
│   ├── booking_agent.py          # Booking execution
│   ├── followup_agent.py         # Post-booking notifications
│   ├── test_sewabot_pipeline.py  # pytest test suite
│   └── .env.example              # Environment variable template
├── Sewa-Bot-App-backend/         # FastAPI backend — port 8000
│   ├── main.py                   # REST API (providers, bookings, disputes)
│   ├── firebase_config.py        # Multi-source Firebase credentials
│   └── .env.example              # Environment variable template
├── render.yaml                   # Render.com deployment (both services)
├── firebase.json                 # Firebase Hosting config (Flutter web)
└── .firebaserc                   # Firebase project association
```

---

## Agent Pipeline

```
User Input (Urdu / Roman Urdu / English)
        │
        ▼
  1. IntentAgent       — extracts service, location, time, urgency
        │
        ▼
  2. DiscoveryAgent    — finds matching providers from database
        │
        ▼
  3. RankingAgent      — scores by distance, rating, availability
        │
        ▼
  4. QuoteAgent        — deterministic price calculation
        │
        ▼
  5. BookingAgent      — confirms booking, generates receipt
        │
        ▼
  6. FollowupAgent     — schedules WhatsApp/SMS notifications
```

---

## Environment Variables

### Backend (`Sewa-Bot-App-backend/.env.example`)

| Variable | Required | Description |
|---|---|---|
| `PORT` | Auto (Render) | Server port — Render injects this |
| `FIREBASE_CREDENTIALS_JSON` | Yes (prod) | Full JSON string of Firebase service account |
| `GOOGLE_APPLICATION_CREDENTIALS` | Alt | Path to service account file (local dev) |
| `FIREBASE_PROJECT_ID` | Yes | Firebase project ID |

### Agents (`Sewa-Bot-App-agents/agents/.env.example`)

| Variable | Required | Description |
|---|---|---|
| `GEMINI_API_KEY` | Yes | From https://aistudio.google.com/apikey |
| `BACKEND_BASE_URL` | Yes | URL of the backend service |
| `FIREBASE_CREDENTIALS_JSON` | Optional | Same as backend (if agents access Firestore directly) |
| `TEST_MODE` | CI only | Set `true` to skip Gemini calls in tests |

### Flutter App (`--dart-define` at build time)

| Define | Default | Description |
|---|---|---|
| `AGENTS_BASE_URL` | `https://sewabot-agents.onrender.com` | Agents API URL |
| `BACKEND_BASE_URL` | `https://sewabot-backend.onrender.com` | Backend API URL |
| `DEMO_MODE` | `false` | Use mock data without API |

---

## Deployment Guide

### 1. Deploy Backend to Render

1. Go to [render.com](https://render.com) → New → Web Service
2. Connect your GitHub repo
3. Render auto-detects `render.yaml` and creates both services
4. In **sewabot-backend** → Environment tab, add:
   - `FIREBASE_CREDENTIALS_JSON` → paste the entire `firebase-key.json` content as one line
   - `FIREBASE_PROJECT_ID` → your project ID
5. In **sewabot-agents** → Environment tab, add:
   - `GEMINI_API_KEY` → your Gemini API key
   - `BACKEND_BASE_URL` → `https://sewabot-backend.onrender.com`
   - `FIREBASE_CREDENTIALS_JSON` → same as backend

Note your Render URLs:
- Backend: `https://sewabot-backend.onrender.com`
- Agents: `https://sewabot-agents.onrender.com`

### 2. Deploy Flutter to Firebase Hosting (Web)

```bash
# Install Firebase CLI (once)
npm install -g firebase-tools
firebase login

# Edit .firebaserc — set your Firebase project ID
# Then build and deploy:
flutter build web \
  --dart-define=AGENTS_BASE_URL=https://sewabot-agents.onrender.com \
  --dart-define=BACKEND_BASE_URL=https://sewabot-backend.onrender.com \
  --dart-define=DEMO_MODE=false

firebase deploy --only hosting
```

### 3. Build Flutter APK (Android)

```bash
flutter build apk --release \
  --dart-define=AGENTS_BASE_URL=https://sewabot-agents.onrender.com \
  --dart-define=BACKEND_BASE_URL=https://sewabot-backend.onrender.com \
  --dart-define=DEMO_MODE=false
```

---

## Local Development

### Prerequisites

| Tool | Version |
|---|---|
| Flutter | 3.x+ |
| Python | 3.10+ |
| Firebase CLI | Latest |

### 1. Run Backend

```bash
cd Sewa-Bot-App-backend
pip install -r requirements.txt
cp .env.example .env
# Edit .env: add GOOGLE_APPLICATION_CREDENTIALS=./firebase-key.json
uvicorn main:app --reload --port 8000
# Verify: http://localhost:8000
```

### 2. Run Agents

```bash
cd Sewa-Bot-App-agents/agents
pip install -r requirements.txt
cp .env.example .env
# Edit .env: add GEMINI_API_KEY=your_key_here
# Edit .env: set BACKEND_BASE_URL=http://localhost:8000
uvicorn main_api:app --reload --port 8001
# Verify: http://localhost:8001
```

### 3. Run Flutter (Web / Desktop)

```bash
# From repo root
flutter pub get
flutter run \
  --dart-define=AGENTS_BASE_URL=http://localhost:8001 \
  --dart-define=BACKEND_BASE_URL=http://localhost:8000
```

### 4. Run Flutter (Android Emulator)

```bash
# Use 10.0.2.2 instead of localhost for Android emulator
flutter run \
  --dart-define=AGENTS_BASE_URL=http://10.0.2.2:8001 \
  --dart-define=BACKEND_BASE_URL=http://10.0.2.2:8000
```

### 5. Run Flutter (Physical Device on LAN)

```bash
# Replace 192.168.x.x with your machine's local IP (run ipconfig)
flutter run \
  --dart-define=AGENTS_BASE_URL=http://192.168.x.x:8001 \
  --dart-define=BACKEND_BASE_URL=http://192.168.x.x:8000
```

---

## Running Tests

```bash
cd Sewa-Bot-App-agents/agents
pip install pytest
TEST_MODE=true pytest test_sewabot_pipeline.py -v
```

Expected: all 13 tests pass without a Gemini API key or network.

---

## Demo Prompts

Try these in the Chat screen:

- *"Mujhe kal subah G-13 mein AC technician chahiye"*
- *"I need a plumber today evening in F-8"*
- *"DHA Lahore mein beautician chahiye"*
- *"Bijli ka masla hai, electrician chahiye abhi"*

---

## API Reference

### Backend (port 8000 / Render)

| Method | Path | Description |
|---|---|---|
| GET | `/` | Health check |
| GET | `/providers` | List all providers |
| POST | `/search` | Search by service + location |
| POST | `/book` | Create a booking |
| GET | `/bookings` | List all bookings |
| GET | `/bookings/{id}` | Get booking details |
| POST | `/disputes` | File a dispute |
| POST | `/notify` | Simulate WhatsApp notification |
| POST | `/agent-logs` | Push agent session log |
| GET | `/agent-logs/{session_id}` | Get session trace |

### Agents (port 8001 / Render)

| Method | Path | Description |
|---|---|---|
| GET | `/` | Health check |
| POST | `/extractIntent` | Step 1: IntentAgent |
| POST | `/getProviders` | Step 2: DiscoveryAgent + RankingAgent |
| POST | `/getPriceQuote` | Step 3: QuoteAgent |
| POST | `/executeBooking` | Step 4: BookingAgent + FollowupAgent |
| POST | `/chat` | Combined: Steps 1–3 |
| POST | `/book` | Combined: Steps 4–5 |
| GET | `/agent-logs/{session_id}` | Get session trace |

---

## Tech Stack

- **Flutter** — cross-platform mobile/web app
- **FastAPI** — Python REST APIs (backend + agents)
- **Gemini 2.5 Flash** — multilingual intent parsing + reasoning
- **Firebase Firestore** — booking + dispute persistence
- **Firebase Hosting** — Flutter web deployment
- **Render** — backend + agents hosting
- **Google Antigravity** — AI orchestration platform

---

## Team

| Name | Role |
|---|---|
| Miraan | AI Agents / Models |
| Saad | Backend API + Firebase |
| Ans | Flutter Mobile App |
