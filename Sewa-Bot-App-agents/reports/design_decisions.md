# SewaBot — Design Decisions & Architecture Choices

## Version: 0.2.0 | Date: 2026-05-19

---

## 1. Tech Stack Decisions

| Layer | Choice | Reason |
|---|---|---|
| Orchestration | Google Antigravity + Gemini 2.5 Flash | Mandatory for hackathon (25% of score) |
| Mobile | Flutter | Cross-platform, fast UI, single codebase for Android/iOS |
| Backend | FastAPI (Python, port 8000) | Lightweight, async-ready, auto-generates OpenAPI docs |
| Agents Layer | FastAPI (Python, port 8001) | Separate service, calls backend and Gemini |
| Database | Firebase Firestore (real via `firebase-key.json`) | Free tier, real-time, bookings persisted |
| Distance | Haversine formula (no Maps API required) | Works offline, no API key needed for MVP |
| Notifications | `/notify` endpoint (simulated WhatsApp) | Demonstrated via Saad's backend + local fallback |

---

## 2. Three-Layer Architecture

```
Flutter App (Ans)
      │  POST /extractIntent, /getProviders, /getPriceQuote, /executeBooking
      ▼
Agents API (Miraan — port 8001)
  ├── intent_agent.py      → Gemini 2.5 Flash (multilingual parsing)
  ├── discovery_agent.py   → reads data/providers.json (Saad's 40 providers)
  ├── ranking_agent.py     → weighted score + Gemini why_chosen text
  ├── quote_agent.py       → deterministic pricing formula
  ├── booking_agent.py     → calls Saad's POST /book
  └── followup_agent.py   → calls Saad's POST /notify
      │  POST /book, POST /notify
      ▼
Backend API (Saad — port 8000)
  ├── /providers, /search, /rank, /book, /bookings, /notify
  └── Firebase Firestore (bookings collection)
```

---

## 3. Agent Architecture Decisions

### Why 5 Separate Agents
- Each agent is independently testable and has a dedicated reasoning trace
- Judges can see each reasoning step separately (required for scoring)
- Failures are isolated — booking agent failing doesn't corrupt intent data
- Maps directly to hackathon "multi-step reasoning" requirement

### Why Gemini Only Where Needed
- **Intent Agent:** Uses Gemini — multilingual parsing is genuinely hard; LLM handles code-switching (Roman Urdu + English)
- **Discovery Agent:** No Gemini — pure data filter + Haversine distance calculation
- **Ranking Agent:** Uses Gemini for `why_chosen` and `why_over_rank_2` text only — scoring itself is deterministic Python
- **Quote Agent:** No Gemini — deterministic pricing formula (base + complexity% + urgency%)
- **Booking Agent:** No Gemini — HTTP call to Saad's /book endpoint
- **Follow-up Agent:** No Gemini — time scheduling and template messages
- This keeps API costs low and latency predictable

### Scoring Formula (aligned with Saad's backend)
```
Total Score = Distance(40%) + Rating(35%) + Availability(15%) + Verified(10%)
```
- Distance: max 40pts, decreases by 4pts per km (capped at 0)
- Rating: (rating/5.0) × 35
- Availability: 15pts (all providers assumed available; no slot data in providers.json)
- Verified: 10pts if verified, proportional otherwise

---

## 4. Integration Design: Agents ↔ Frontend

Ans's `AgentService.dart` calls these endpoints on MY agents server (port 8001):

| Frontend Method | Endpoint | Agents Flow |
|---|---|---|
| `extractIntent()` | `POST /extractIntent` | `intent_agent.run()` |
| `getProviders()` | `POST /getProviders` | `discovery_agent` → `ranking_agent` |
| `getPriceQuote()` | `POST /getPriceQuote` | `quote_agent.run()` |
| `executeBooking()` | `POST /executeBooking` | `booking_agent` → `followup_agent` |
| `submitDispute()` | `POST /submitDispute` | Log + return confirmation |

**To activate (change in `lib/services/agent_service.dart`):**
```dart
static const String baseUrl = 'http://localhost:8001';  // My agents
static bool demoMode = false;  // Switch off mock data
```

---

## 5. Integration Design: Agents ↔ Backend (Saad)

- **Provider data:** Agents read `../data/providers.json` directly (shared repo file). Fallback path order: `../data/`, `data/`, `../repo_temp/data/`
- **Booking creation:** `POST http://localhost:8000/book` — if unavailable, falls back to writing `agents/data/bookings.json`
- **Notifications:** `POST http://localhost:8000/notify` — if unavailable, writes `agents/data/scheduled_notifications.json`
- **Agent logs:** Agents write to `logs/` directory; Saad's backend has separate `/agent-logs` endpoint

---

## 6. Response Schema Design

### Why Custom Response Schemas (not Saad's directly)

Saad's `/rank` returns: `{id, name, distance_km, score, score_breakdown}`

Frontend's `MockData` expects: `{rank, provider_id, provider_name, area, distance_km, rating, is_verified, total_score, score_breakdown, why_chosen, why_over_rank_2, agent_trace}`

My ranking agent bridges this gap — enriches Saad's raw data with AI-generated explanations and proper field mapping. The agents layer IS the transformation and reasoning layer.

---

## 7. Branch Strategy

| Branch | Owner | Contents |
|---|---|---|
| `main` | All | Final merged submission only |
| `backend` | Saad | FastAPI endpoints, Firebase, 40 providers data |
| `frontend_branch` | Ans | Flutter app, all screens, AgentService.dart |
| `agents` | Miraan | 5 agents, orchestrator, quote_agent, main_api, session_logger |

**Integration required for demo:**
1. Saad runs `uvicorn main:app --port 8000`
2. Miraan runs `uvicorn main_api:app --port 8001`
3. Ans sets `baseUrl = 'http://localhost:8001'` and `demoMode = false`

---

## 8. Decisions Resolved

- [x] Real Firebase used by Saad (not local JSON for backend)
- [x] Voice input implemented by Ans (speech_to_text + flutter_tts)
- [x] Pure Haversine for distance (no Maps API needed)
- [x] Notification simulation via Saad's `/notify` endpoint
- [x] Agents run as separate FastAPI service (not merged into backend)

## 9. Decisions Still Pending

- [ ] Google Maps visual map in providers screen
- [ ] Whether to demo with real Gemini calls or use mock mode for hackathon presentation
- [ ] Whether to merge all branches before submission deadline
