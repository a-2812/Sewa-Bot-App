# SewaBot

SewaBot is an AI service orchestration app for Pakistan's informal services market. It helps users describe a home-service need in English, Urdu, or Roman Urdu, then routes the request through an agent pipeline that extracts intent, finds providers, ranks options, generates a quote, books the job, and schedules follow-up notifications.

This repository contains the Flutter frontend, the FastAPI backend, and the Python-based agent orchestration layer used for the Google Antigravity Hackathon 2026 challenge.

## Table of Contents

- [Project Overview](#project-overview)
- [System Architecture](#system-architecture)
- [Repository Structure](#repository-structure)
- [How Antigravity Is Used](#how-antigravity-is-used)
- [Agent Pipeline](#agent-pipeline)
- [APIs and Tools Used](#apis-and-tools-used)
- [Environment Configuration](#environment-configuration)
- [Local Development](#local-development)
- [Deployment](#deployment)
- [API Reference](#api-reference)
- [Data Model Overview](#data-model-overview)
- [Testing](#testing)
- [Assumptions](#assumptions)
- [Limitations](#limitations)
- [Team](#team)

## Project Overview

SewaBot targets a common coordination problem: users need trusted local service providers quickly, while informal workers need a lightweight channel for job discovery and booking.

The app currently supports service flows for:

- AC technicians
- Plumbers
- Electricians
- Math tutors
- Beauticians
- Carpenters

Core user capabilities:

- Text and voice request entry
- Multilingual intent extraction
- Provider discovery and ranking
- Quote generation
- Booking confirmation
- Booking status screens
- Dispute screen
- Agent reasoning trace screen

Core provider capabilities:

- Provider dashboard
- Incoming jobs view
- Active job view
- Earnings view
- Provider profile view

## System Architecture

SewaBot is built as a three-layer system:

```text
Flutter App
  - User and provider UI
  - Auth screens and role-based navigation
  - Voice input and text-to-speech support
  - Calls Agents API for AI workflow
  - Calls configured services using build-time URLs

        |
        | HTTP JSON
        v

Agents API - FastAPI, Python
  - IntentAgent
  - DiscoveryAgent
  - RankingAgent
  - QuoteAgent
  - BookingAgent
  - FollowupAgent
  - Session logging and trace export
  - Calls backend for bookings, notifications, and logs

        |
        | HTTP JSON
        v

Backend API - FastAPI, Python
  - Provider catalogue
  - Provider search
  - Booking creation and lookup
  - Disputes
  - Notification simulation
  - Agent log ingestion
  - Firestore persistence when credentials are configured

        |
        v

Firebase
  - Firebase Core/Auth configuration in Flutter
  - Firestore for backend persistence
  - Firebase Hosting for Flutter web deployment
```

### Runtime Flow

1. The user enters a request such as `Mujhe kal subah G-13 mein AC technician chahiye`.
2. Flutter sends the message to the Agents API.
3. `IntentAgent` extracts the service type, location, time preference, urgency, and language.
4. `DiscoveryAgent` finds matching providers.
5. `RankingAgent` scores providers by distance, rating, availability, and verification.
6. `QuoteAgent` calculates a transparent price estimate.
7. `BookingAgent` submits the booking through the backend.
8. `FollowupAgent` schedules simulated reminder/notification events.
9. The frontend displays the provider list, quote, booking confirmation, and agent trace.

## Repository Structure

```text
.
|-- lib/                             Flutter app source
|   |-- config/                      Runtime configuration and mock data
|   |-- models/                      Shared app models
|   |-- providers/                   Flutter Provider state objects
|   |-- screens/                     Auth, user, provider, and shared screens
|   |-- services/                    Agents, voice, and compatibility services
|   |-- theme/                       App themes
|   |-- widgets/                     Reusable UI widgets
|   |-- firebase_options.dart        Firebase client configuration
|   `-- main.dart                    Flutter entry point and routes
|
|-- Sewa-Bot-App-agents/
|   |-- agents/
|   |   |-- main_api.py              Agents FastAPI app
|   |   |-- orchestrator.py          Pipeline coordinator
|   |   |-- intent_agent.py          Multilingual intent extraction
|   |   |-- discovery_agent.py       Provider discovery
|   |   |-- ranking_agent.py         Provider scoring and explanation
|   |   |-- quote_agent.py           Quote calculation
|   |   |-- booking_agent.py         Booking execution
|   |   |-- followup_agent.py        Follow-up notification workflow
|   |   |-- session_logger.py        Per-session trace logging
|   |   |-- config.py                Agent environment configuration
|   |   `-- requirements.txt         Python dependencies
|   `-- reports/                     Project reports and design notes
|
|-- Sewa-Bot-App-backend/
|   |-- main.py                      Backend FastAPI app
|   |-- firebase_config.py           Firebase Admin configuration
|   |-- API_DOCS.md                  Backend API documentation
|   |-- admin.html                   Admin dashboard page
|   |-- data/                        Seed/fallback JSON data
|   `-- requirements.txt             Python dependencies
|
|-- android/                         Flutter Android project
|-- web/                             Flutter web project
|-- assets/                          Mock and animation assets
|-- test/                            Flutter tests
|-- firebase.json                    Firebase Hosting config
|-- firestore.rules                  Firestore security rules
|-- render.yaml                      Render deployment config
|-- pubspec.yaml                     Flutter dependencies
`-- README.md
```

## How Antigravity Is Used

This project was built for the Google Antigravity Hackathon challenge around agentic workflow orchestration. Antigravity is used as the guiding platform and development context for designing the agent workflow, demonstrating the multi-agent flow, and aligning the project with the challenge requirements.

In the current codebase, Antigravity is not a runtime SDK imported by the Flutter app or Python services. The runtime orchestration is implemented in the `Sewa-Bot-App-agents/agents` FastAPI service, where each workflow step is represented as a separate Python agent module. Antigravity's role is therefore:

- To frame the app as an agentic workflow orchestration project.
- To guide the decomposition of the service-booking journey into specialized agents.
- To support hackathon demonstration and project organization.
- To help explain and present the end-to-end agent flow through reports, trace screens, and the agent pipeline.

The production/runtime dependencies are Flutter, FastAPI, Firebase, Render, and Gemini rather than an Antigravity package inside the source code.

## Agent Pipeline

The agent layer exposes both step-by-step endpoints and backward-compatible combined endpoints.

```text
User request
  |
  v
IntentAgent
  - Detects language
  - Extracts service type, location, preferred time, urgency, and confidence
  - Produces a workplan and clarification question when needed
  |
  v
DiscoveryAgent
  - Normalizes service names
  - Searches the provider catalogue
  - Filters by service and location
  |
  v
RankingAgent
  - Ranks providers using weighted criteria
  - Uses distance, rating, availability, and verification
  - Can generate human-readable ranking explanations
  |
  v
QuoteAgent
  - Calculates base fee, urgency fee, complexity fee, and total quote
  - Returns a budget alternative where available
  |
  v
BookingAgent
  - Creates or simulates booking confirmation
  - Calls the backend booking endpoint when available
  |
  v
FollowupAgent
  - Schedules simulated notifications
  - Calls backend notification endpoint when available
```

Each agent records reasoning/output metadata into the session log. The frontend can fetch this trace for the reasoning trace screen.

## APIs and Tools Used

### Frontend

- Flutter: cross-platform mobile and web UI.
- Provider: app state management.
- HTTP package: REST API communication.
- Firebase Core: Firebase initialization.
- Firebase Auth: authentication dependency/configuration.
- Cloud Firestore package: included for Firestore support, although current app persistence is routed through the backend service.
- speech_to_text: user voice input.
- flutter_tts: text-to-speech responses.
- permission_handler: device permission handling.
- shared_preferences: local app preferences.
- url_launcher: external URL/phone/navigation style launch support.
- lottie, shimmer, google_fonts, flutter_rating_bar, timeline_tile: UI polish and visualization.

### Agents API

- FastAPI: API server for the agent workflow.
- Uvicorn: ASGI runtime.
- Pydantic: request validation.
- Gemini 2.5 Flash: multilingual intent/reasoning support where configured.
- Python requests/http tooling: backend calls.
- Local session logger: stores per-session agent traces and exports them to the frontend.

### Backend API

- FastAPI: REST API for providers, bookings, disputes, notifications, and logs.
- Firebase Admin / Firestore: persistent storage when service credentials are provided.
- JSON seed/fallback data: local provider, booking, and log data for development/demo fallback.
- Rate limiting and timeout middleware: development protection against excessive calls.

### Hosting and Deployment

- Firebase Hosting: Flutter web hosting.
- Render: backend and agents web services, configured in `render.yaml`.
- Android build tooling: APK generation through Flutter/Gradle.

## Environment Configuration

### Flutter Build Defines

The Flutter app reads API URLs from compile-time Dart defines in `lib/config/app_config.dart`.

| Define | Default | Purpose |
|---|---|---|
| `AGENTS_BASE_URL` | `https://sewabot-agents.onrender.com` | Base URL for the Agents API |
| `BACKEND_BASE_URL` | `https://sewabot-backend.onrender.com` | Base URL for the Backend API |
| `DEMO_MODE` | `false` | Uses mock responses when true |

Example:

```bash
flutter run \
  --dart-define=AGENTS_BASE_URL=http://localhost:8001 \
  --dart-define=BACKEND_BASE_URL=http://localhost:8000 \
  --dart-define=DEMO_MODE=false
```

### Backend Environment

The backend expects Firebase credentials for Firestore-backed persistence.

| Variable | Required | Purpose |
|---|---|---|
| `PORT` | No locally, yes on Render | Runtime port |
| `FIREBASE_CREDENTIALS_JSON` | Required for production Firestore | Full Firebase service account JSON as a string |
| `GOOGLE_APPLICATION_CREDENTIALS` | Optional local alternative | Path to a Firebase service account JSON file |
| `FIREBASE_PROJECT_ID` | Required for production Firestore | Firebase project ID |

### Agents Environment

| Variable | Required | Purpose |
|---|---|---|
| `PORT` | No locally, yes on Render | Runtime port |
| `GEMINI_API_KEY` | Required for Gemini-backed agent calls | Google AI Studio / Gemini API key |
| `BACKEND_BASE_URL` | Required for integrated booking flow | Backend API URL |
| `FIREBASE_CREDENTIALS_JSON` | Optional | Used if agents access Firebase directly |
| `FIREBASE_PROJECT_ID` | Optional | Firebase project ID |
| `TEST_MODE` | Optional | Allows tests to avoid live Gemini calls |

## Local Development

### Prerequisites

- Flutter 3.x or newer
- Dart SDK compatible with `>=3.0.0 <4.0.0`
- Python 3.10 or newer
- Firebase CLI for web deployment
- A Firebase project for real persistence/auth flows
- A Gemini API key for live agent reasoning

### 1. Install Flutter Dependencies

```bash
flutter pub get
```

### 2. Run Backend API

```bash
cd Sewa-Bot-App-backend
pip install -r requirements.txt
uvicorn main:app --reload --port 8000
```

Health check:

```text
http://localhost:8000/
```

### 3. Run Agents API

```bash
cd Sewa-Bot-App-agents/agents
pip install -r requirements.txt
uvicorn main_api:app --reload --port 8001
```

Health check:

```text
http://localhost:8001/
```

### 4. Run Flutter Web or Desktop

```bash
flutter run \
  --dart-define=AGENTS_BASE_URL=http://localhost:8001 \
  --dart-define=BACKEND_BASE_URL=http://localhost:8000 \
  --dart-define=DEMO_MODE=false
```

### 5. Run Flutter on Android Emulator

Android emulators cannot reach the host machine through `localhost`, so use `10.0.2.2`.

```bash
flutter run \
  --dart-define=AGENTS_BASE_URL=http://10.0.2.2:8001 \
  --dart-define=BACKEND_BASE_URL=http://10.0.2.2:8000 \
  --dart-define=DEMO_MODE=false
```

### 6. Run Flutter on a Physical Device

Use the local network IP address of the development machine.

```bash
flutter run \
  --dart-define=AGENTS_BASE_URL=http://192.168.x.x:8001 \
  --dart-define=BACKEND_BASE_URL=http://192.168.x.x:8000 \
  --dart-define=DEMO_MODE=false
```

## Deployment

### Render Services

`render.yaml` defines two Python web services:

- `sewabot-backend`
  - Root directory: `Sewa-Bot-App-backend`
  - Start command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
  - Health check: `/`

- `sewabot-agents`
  - Root directory: `Sewa-Bot-App-agents/agents`
  - Start command: `uvicorn main_api:app --host 0.0.0.0 --port $PORT`
  - Health check: `/`

Required Render secrets:

- `FIREBASE_CREDENTIALS_JSON`
- `FIREBASE_PROJECT_ID`
- `GEMINI_API_KEY` for the agents service
- `BACKEND_BASE_URL` for the agents service

### Firebase Hosting

Build the Flutter web app with production service URLs:

```bash
flutter build web \
  --dart-define=AGENTS_BASE_URL=https://sewabot-agents.onrender.com \
  --dart-define=BACKEND_BASE_URL=https://sewabot-backend.onrender.com \
  --dart-define=DEMO_MODE=false
```

Deploy:

```bash
firebase deploy --only hosting
```

### Android APK

```bash
flutter build apk --release \
  --dart-define=AGENTS_BASE_URL=https://sewabot-agents.onrender.com \
  --dart-define=BACKEND_BASE_URL=https://sewabot-backend.onrender.com \
  --dart-define=DEMO_MODE=false
```

## API Reference

### Agents API

Default local base URL:

```text
http://localhost:8001
```

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/` | Health check and service metadata |
| `POST` | `/extractIntent` | Runs IntentAgent on raw user text |
| `POST` | `/getProviders` | Runs DiscoveryAgent and RankingAgent |
| `POST` | `/getPriceQuote` | Runs QuoteAgent for a selected provider |
| `POST` | `/executeBooking` | Runs BookingAgent and FollowupAgent |
| `POST` | `/chat` | Combined intent, discovery, and ranking flow |
| `POST` | `/book` | Combined booking and follow-up flow |
| `GET` | `/agent-logs/{session_id}` | Returns the full trace for one session |
| `GET` | `/bookings/{booking_id}` | Utility booking lookup through agents layer |
| `GET` | `/providers` | Utility provider search through agents layer |

Example `POST /extractIntent` body:

```json
{
  "message": "I need a plumber today evening in F-8",
  "session_id": "optional-session-id"
}
```

Example response shape:

```json
{
  "session_id": "session-id",
  "intent": {
    "service_type": "Plumber",
    "location": "F-8",
    "preferred_time": "today evening",
    "urgency": "normal",
    "language_detected": "English",
    "confidence_score": 0.92
  },
  "workplan": [],
  "agent_log": []
}
```

### Backend API

Default local base URL:

```text
http://localhost:8000
```

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/` | Health check |
| `GET` | `/admin` | Admin dashboard HTML |
| `GET` | `/providers` | List providers with optional filters |
| `POST` | `/search` | Find providers by service/location/radius |
| `POST` | `/rank` | Rank providers using weighted score |
| `POST` | `/book` | Create a booking |
| `GET` | `/bookings` | List bookings |
| `GET` | `/bookings/{booking_id}` | Get booking details |
| `POST` | `/disputes` | File a dispute |
| `POST` | `/notify` | Simulate a notification |
| `POST` | `/agent-logs` | Store agent session logs |
| `GET` | `/agent-logs` | Retrieve recent agent logs |
| `GET` | `/agent-logs/{session_id}` | Retrieve logs for one session when supported |

See `Sewa-Bot-App-backend/API_DOCS.md` for detailed backend examples.

## Data Model Overview

### Provider

Providers include fields such as:

- Provider ID
- Name
- Service type
- Phone/contact details
- City and coordinates
- Rating
- Verification status
- Availability status
- Price estimate

### Intent

The agent intent object generally includes:

- `service_type`
- `location`
- `preferred_time`
- `urgency`
- `language_detected`
- `confidence_score`
- `clarification_needed`
- `clarification_question`

### Booking

Booking records generally include:

- `booking_id`
- Provider ID/name
- Customer name/phone
- Service type
- Time slot
- Location
- Status
- Receipt
- Created timestamp

### Agent Log

Agent logs include:

- Session ID
- Agent name
- Step/action
- Reasoning text
- Output summary
- Duration in milliseconds
- Status

## Testing

### Flutter Tests

```bash
flutter test
```

### Agents Tests

The agents folder contains pipeline tests. Use `TEST_MODE=true` to avoid depending on live Gemini calls where supported.

```bash
cd Sewa-Bot-App-agents/agents
pip install -r requirements.txt
$env:TEST_MODE="true"
pytest -v
```

On macOS/Linux:

```bash
cd Sewa-Bot-App-agents/agents
pip install -r requirements.txt
TEST_MODE=true pytest -v
```

## Assumptions

- Users are located in supported Pakistani cities/areas represented by the provider dataset.
- Service requests contain enough information to identify at least a service type and location.
- Gemini is available and configured for live multilingual intent extraction.
- Firestore credentials are available in deployed environments that require persistence.
- The backend is the source of truth for persisted bookings, disputes, provider search, and agent log storage.
- The frontend can fall back to mock/demo data when APIs are unreachable or `DEMO_MODE=true`.
- Notification behavior is simulated; actual WhatsApp/SMS provider integration is outside the current implementation.
- Provider availability is simplified and may be represented as a static boolean or fallback score.
- Render free-tier services may sleep, causing cold-start latency during demos.

## Limitations

- Antigravity is not currently imported as a runtime SDK in the source code; the app implements its own FastAPI agent orchestration layer.
- Authentication screens and Firebase Auth dependencies exist, but API-level authorization is not fully enforced across backend endpoints.
- Backend API documentation states the development API is currently unauthenticated.
- Notification sending is simulated and does not deliver real WhatsApp/SMS messages.
- Provider matching depends on seed/fallback provider data and may not cover all areas.
- Real-time provider acceptance/rejection is not fully implemented.
- Pricing is deterministic and demo-oriented; it is not a negotiated marketplace price.
- Voice recognition quality depends on device support, microphone permission, and available Urdu/Roman Urdu speech models.
- Some local flows depend on correct environment variables and service startup order.
- The app is optimized for hackathon demonstration and needs additional hardening before production use.

## Demo Prompts

Try these prompts in the chat screen:

- `Mujhe kal subah G-13 mein AC technician chahiye`
- `I need a plumber today evening in F-8`
- `DHA Lahore mein beautician chahiye`
- `Bijli ka masla hai, electrician chahiye abhi`

## Team

| Name | Role |
|---|---|
| Abdullah | AI agents and model workflow |
| Saad | Backend API and Firebase |
| Ans | Flutter frontend and deployment |

