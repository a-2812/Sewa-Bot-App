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
flutter pub get
flutter run
```

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
