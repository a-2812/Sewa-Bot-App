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
flutter pub get
flutter run
```

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
