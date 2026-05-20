<<<<<<< HEAD
# SewaBot: AI Service Orchestrator

## Challenge Overview
**AI Service Orchestrator for Pakistan's informal economy.**
SewaBot automates the end-to-end lifecycle of a service request for the informal economy (plumbers, electricians, tutors, beauticians, etc.). It addresses the inefficiencies of informal bookings by providing an intelligent, multilingual orchestrator that handles intent parsing, provider matching, quoting, booking, and automated follow-ups.

## Architecture
The platform is built on a scalable, decoupled architecture:
**Flutter mobile app** -> **Antigravity agents/orchestrator** -> **FastAPI backend** -> **Firestore/local JSON**

- **Frontend:** Flutter mobile app providing a conversational interface and live AI reasoning traces.
- **Agents API (Port 8001):** The core orchestration layer executing the multi-agent pipeline.
- **FastAPI Backend (Port 8000):** Persistence layer, handling database operations, searching, and notifications.

## How Google Antigravity is Used
Google Antigravity serves as the **core orchestration layer** for the SewaBot platform. It drives the multi-agent workflow by managing:
- Planning, reasoning, tool calls, action execution, and trace logs.
- Coordination of the 5-step specialized agent pipeline:
  1. **IntentAgent**: Multilingual parsing of user requests (Urdu, Roman Urdu, English).
  2. **DiscoveryAgent**: Context-aware spatial search for local providers.
  3. **RankingAgent**: Multi-variable provider scoring (distance, rating, verification, availability).
  4. **BookingAgent**: Confirms scheduling and generates backend payloads.
  5. **FollowupAgent**: Orchestrates post-booking simulated WhatsApp/SMS notifications and feedback checks.

## APIs & Tools Used
- **Gemini 2.5 Flash:** Powers multilingual intent parsing, reasoning, and natural language generation.
- **FastAPI Backend:** Handles data persistence and simulated external webhooks.
- **Mock Provider Dataset:** Rich local data simulating real-world service professionals.
- **Firestore or Local JSON Fallback:** Ensures reliable demo execution offline.
- **Simulated WhatsApp/SMS Notifications:** Emulates communication channels.

## Setup Instructions

### 1. Backend API
```bash
cd Sewa-Bot-App-backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

### 2. Agents API
```bash
cd Sewa-Bot-App-agents/agents
pip install -r requirements.txt
# Create a .env file and add your Gemini API key: GEMINI_API_KEY=your_key_here
uvicorn main_api:app --reload --port 8001
```

### 3. Flutter App
```bash
=======
# SewaBot — AI Service Orchestrator for Pakistan's Informal Economy

**Google Antigravity Hackathon 2026 | Challenge 2**

SewaBot connects users with local service providers (plumbers, electricians, AC technicians, tutors, beauticians, carpenters) using a 5-agent AI pipeline powered by Gemini 2.5 Flash.

---

## Project Structure

```
repo/
├── lib/                  # Flutter mobile app (Ans)
├── agents/               # Python AI agents — port 8001 (Miraan)
├── data/                 # Provider dataset — 40 providers
├── main.py               # FastAPI backend — port 8000 (Saad)
├── firebase_config.py    # Firestore connection
└── requirements.txt      # Backend Python dependencies
```

---

## Prerequisites

Make sure these are installed on your machine before starting:

| Tool | Version | Download |
|---|---|---|
| Flutter | 3.x+ | https://flutter.dev/docs/get-started/install |
| Python | 3.10+ | https://python.org/downloads |
| Android Studio | Latest | https://developer.android.com/studio |
| Git | Any | https://git-scm.com |

---

## Step 1 — Clone the Repo

```bash
git clone https://github.com/a-2812/Sewa-Bot-App.git
cd Sewa-Bot-App
```

---

## Step 2 — Run the Backend (Saad's FastAPI — port 8000)

```bash
# From repo root (make sure you're on the backend branch or main)
pip install -r requirements.txt
```

You need a `firebase-key.json` file in the repo root. **Get this from Saad privately** — never commit it.

```bash
uvicorn main:app --reload --port 8000
```

Verify it's running: open http://localhost:8000 in your browser — you should see `{"status": "ok"}`.

---

## Step 3 — Run the Agents (Miraan's AI pipeline — port 8001)

```bash
cd agents

# Create and activate a virtual environment
python -m venv venv

# Windows
venv\Scripts\activate

# Mac/Linux
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt
```

Create your `.env` file:

```bash
# Windows
copy .env.example .env

# Mac/Linux
cp .env.example .env
```

Open `.env` and add your Gemini API key:

```
GEMINI_API_KEY=your_gemini_api_key_here
```

**Get the Gemini API key from:** https://aistudio.google.com/apikey (free, takes 1 minute)

Start the agents server:

```bash
uvicorn main_api:app --reload --port 8001
```

Verify: open http://localhost:8001 — you should see `{"status": "ok", "service": "SewaBot Agents API"}`.

---

## Step 4 — Run the Flutter App

Connect your Android phone via USB with USB debugging enabled, or start an Android emulator.

```bash
# From repo root
>>>>>>> 49b58a3ac1be9f554a2191cbd8e144c726e313b3
flutter pub get
flutter run
```

<<<<<<< HEAD
## Demo Input Examples
Try these prompts in the chat interface to see the agent pipeline in action:
- *"Mujhe kal subah G-13 mein AC technician chahiye"*
- *"I need a plumber today evening in F-8"*
- *"DHA Lahore mein beautician chahiye"*
- *"Bijli ka masla hai, electrician chahiye"*

## Evaluation Mapping
This project addresses the core evaluation criteria of the challenge:
- **Google Antigravity:** Powers the core orchestration layer.
- **Agentic Reasoning:** Implements a robust 5-agent pipeline handling distinct cognitive tasks.
- **Matching Quality:** Utilizes a weighted ranking formula (distance, rating, slots).
- **Action Simulation:** Fully simulates booking execution and multi-channel notifications.
- **Technical Implementation:** Cohesive integration of Flutter + FastAPI + Python-based Agents.
- **UX:** Polished, mobile-first, multilingual flow with real-time AI tracing.

## Assumptions and Limitations
- **Notifications are simulated:** WhatsApp/SMS messages are logged in the backend but not dispatched to real networks.
- **Provider data is mock/local:** Provider data is mocked unless real external APIs are added.
- **Location matching:** Spatial searches use predefined coordinate mappings rather than live GPS.
- **Payment is not implemented:** Pricing quotes are for estimation purposes only.
=======
> **First build takes 5-10 minutes** — Gradle downloads Android dependencies. Subsequent builds are much faster.

The app will launch on your device showing the SewaBot dev index screen.

### Connecting the App to Your Local Agents

By default the app runs in **demo mode** (mock data, no real API calls). To connect it to your running agents:

Open `lib/services/agent_service.dart` and change:

```dart
static const String baseUrl = 'http://localhost:8001';
static bool demoMode = false;
```

If running on a **physical phone** (not emulator), replace `localhost` with your computer's local IP address:

```dart
static const String baseUrl = 'http://192.168.x.x:8001';
```

Find your IP: run `ipconfig` (Windows) or `ifconfig` (Mac/Linux) and look for your WiFi IPv4 address. Your phone and computer must be on the same WiFi network.

---

## Common Issues & Fixes

**`Could not connect to Kotlin compile daemon`**
Your Kotlin version is outdated. In `android/settings.gradle.kts` change:
```
id("org.jetbrains.kotlin.android") version "2.1.0" apply false
```
Then run `flutter clean && flutter run`.

**`Gradle daemon out of memory`**
In `android/gradle.properties` set:
```
org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=512m
```

**`firebase-key.json not found`**
Get this file from Saad. Place it in the repo root next to `main.py`.

**`GEMINI_API_KEY not set`**
Create `agents/.env` from `agents/.env.example` and add your key from https://aistudio.google.com/apikey.

**App shows blank screen or crashes on launch**
Run `flutter clean && flutter pub get && flutter run` to rebuild from scratch.

**`speech_to_text` or `flutter_tts` compile errors**
Make sure `pubspec.yaml` has:
```yaml
speech_to_text: ^7.0.0
flutter_tts: ^4.0.0
```
Then run `flutter pub get`.

**Phone not detected**
- Enable USB Debugging on your phone: Settings → Developer Options → USB Debugging
- Try a different USB cable (data cable, not charge-only)
- Run `adb devices` to verify connection

---

## Team

| Name | Role | Branch |
|---|---|---|
| Miraan | AI Agents / Models | `agents` |
| Saad | Backend API + Firebase | `backend` |
| Ans | Flutter Mobile App | `frontend_branch` |

---

## Tech Stack

- **Flutter** — cross-platform mobile app
- **FastAPI** — Python backend REST API
- **Firebase Firestore** — booking persistence
- **Gemini 2.5 Flash** — multilingual intent parsing + provider ranking
- **Google Antigravity** — AI orchestration platform
>>>>>>> 49b58a3ac1be9f554a2191cbd8e144c726e313b3
