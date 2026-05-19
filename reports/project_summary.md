# SewaBot — Project Build Status

## Hackathon: Google Antigravity | Challenge 2: AI Service Orchestrator
## Team: Miraan (Agents) | Saad (Backend) | Ans (Frontend)
## Last Updated: 2026-05-19

---

## Build Status by Layer

### Backend (Saad) — `backend` branch — ✅ COMPLETE

| Component | Status | Notes |
|---|---|---|
| FastAPI app (`main.py`) | ✅ Done | v2.0.0, running on port 8000 |
| `GET /providers` | ✅ Done | Filter by service + city + verified_only |
| `POST /search` | ✅ Done | Haversine distance, radius search |
| `POST /rank` | ✅ Done | Weighted scoring: distance(40%), rating(35%), availability(15%), verified(10%) |
| `POST /book` | ✅ Done | Firestore write, generates `BK-{10hex}` ID |
| `GET /bookings/{id}` | ✅ Done | Fetch booking by ID |
| `GET /bookings` | ✅ Done | Filter by status |
| `POST /notify` | ✅ Done | Simulated WhatsApp, saves to `data/notifications.json` |
| `GET /agent-logs` | ✅ Done | Returns recent reasoning logs |
| `GET /admin` | ✅ Done | HTML dashboard |
| Rate limiting | ✅ Done | 10 req/min per IP |
| Timeout middleware | ✅ Done | 2-second timeout |
| Firebase Firestore | ✅ Done | Real connection via `firebase-key.json` |
| 40 providers data | ✅ Done | p001-p040, all 6 service types, Islamabad + Lahore |
| API documentation | ✅ Done | `API_DOCS.md` fully written |

**Provider Distribution (40 total):**
- AC Technician: 7 providers
- Plumber: 6 providers
- Electrician: 7 providers
- Math Tutor: 6 providers
- Beautician: 7 providers
- Carpenter: 7 providers

---

### Frontend (Ans) — `frontend_branch` — ✅ COMPLETE (UI)

| Component | Status | Notes |
|---|---|---|
| Flutter app structure | ✅ Done | `khidmat_ai`, proper Provider pattern |
| Dev index screen | ✅ Done | Navigation hub for development |
| Splash screen | ✅ Done | |
| Chat screen | ✅ Done | Text + Voice mode, intent card display |
| Providers screen | ✅ Done | Ranked list with score breakdown |
| Quote screen | ✅ Done | Price breakdown display |
| Booking screen | ✅ Done | Booking form |
| Status screen | ✅ Done | Booking status |
| Auth screens | ✅ Done | Login, signup, forgot password, email verification |
| Provider screens | ✅ Done | Home, incoming jobs, active job, earnings, profile |
| Agent flow screen | ✅ Done | Multi-step agent visualization |
| Trace screen | ✅ Done | Real-time reasoning traces viewer |
| Voice input | ✅ Done | `speech_to_text` + `flutter_tts` |
| AgentService.dart | ✅ Done | Calls backend API (currently in demoMode=true) |
| FirestoreService.dart | ✅ Done | Bookings, traces, disputes |
| MockData.dart | ✅ Done | Full demo data for all 5 agent steps |
| Theme | ✅ Done | AppTheme with user/provider variants |
| **Integration with agents** | ⚠️ Pending | Set `baseUrl` and `demoMode=false` |

---

### Agents Layer (Miraan) — `agents` branch — ✅ COMPLETE

| Component | Status | Notes |
|---|---|---|
| `main_api.py` | ✅ Done | FastAPI on port 8001, 5 endpoints |
| `intent_agent.py` | ✅ Done | Gemini 2.5 Flash, multilingual, returns `{intent, workplan, agent_trace}` |
| `discovery_agent.py` | ✅ Done | Reads Saad's providers.json, Haversine filter, service normalization |
| `ranking_agent.py` | ✅ Done | Weighted scoring, Gemini `why_chosen` text, full provider schema |
| `quote_agent.py` | ✅ Done | Pricing formula: base + complexity% + urgency% |
| `booking_agent.py` | ✅ Done | Calls Saad's `/book`, fallback to local JSON |
| `followup_agent.py` | ✅ Done | 6 notifications, calls Saad's `/notify` |
| `orchestrator.py` | ✅ Done | Routes all 5 endpoints, session logging |
| `session_logger.py` | ✅ Done | Full per-session agent trace log |
| `config.py` | ✅ Done | Env var loading |
| `.env.example` | ✅ Done | GEMINI_API_KEY template |
| `requirements.txt` | ✅ Done | All dependencies including requests |
| `.gitignore` | ✅ Done | Excludes .env, credentials, pycache |

---

## Hackathon Scoring Checklist

| Criterion | Weight | Status |
|---|---|---|
| Google Antigravity platform used | 25% | ⚠️ Pending — need to run via Antigravity |
| Gemini 2.5 Flash integrated | Part of score | ✅ Intent Agent + Ranking Agent use Gemini |
| Multi-agent pipeline demonstrated | Part of score | ✅ 5 agents, full trace logging |
| Real-world problem solved | Part of score | ✅ Pakistan informal economy |
| Technical implementation quality | Part of score | ✅ Full-stack: Flutter + FastAPI + Firestore |
| Demo quality | Part of score | ⚠️ Need to run integration demo |

---

## Integration Checklist (Before Demo)

- [ ] Get Gemini API key → add to `agents/.env`
- [ ] Saad runs backend: `cd repo_root && uvicorn main:app --reload --port 8000`
- [ ] Miraan runs agents: `cd agents && uvicorn main_api:app --reload --port 8001`
- [ ] Ans changes in `lib/services/agent_service.dart`:
  - `static const String baseUrl = 'http://localhost:8001';`
  - `static bool demoMode = false;`
- [ ] Test full flow: type request → see intent card → see ranked providers → get quote → book
- [ ] Verify booking appears in Firestore console
- [ ] Verify agent traces appear in logs/

---

## Three-Layer Architecture

```
Flutter App (Ans, port N/A)
      │  POST /extractIntent, /getProviders, /getPriceQuote, /executeBooking
      ▼
Agents API (Miraan — port 8001)
  ├── intent_agent       → Gemini 2.5 Flash (multilingual parsing)
  ├── discovery_agent    → reads data/providers.json (Saad's 40 providers)
  ├── ranking_agent      → weighted score + Gemini why_chosen text
  ├── quote_agent        → deterministic pricing formula
  ├── booking_agent      → calls Saad's POST /book
  └── followup_agent     → calls Saad's POST /notify
      │  POST /book, POST /notify
      ▼
Backend API (Saad — port 8000)
  └── Firebase Firestore (bookings collection, real persistence)
```

---

## Known Issues / Risks

| Issue | Severity | Mitigation |
|---|---|---|
| `demoMode=true` in Ans's code | HIGH | Must flip to `false` and set baseUrl before demo |
| Gemini API key not set | HIGH | Add to `agents/.env` before running |
| providers.json path: `../data/providers.json` | MEDIUM | Fallback paths in discovery_agent.py cover 3 locations |
| Saad's backend must be running for booking | MEDIUM | Fallback to local JSON if unavailable |
| No `available_slots` in Saad's providers.json | LOW | Availability score set to fixed 15pts — all providers treated as available |
