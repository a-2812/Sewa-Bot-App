# SewaBot — Version History

---

## v0.1.0 — 2026-05-19

### Added
- Full agents layer skeleton: `intent_agent.py`, `discovery_agent.py`, `ranking_agent.py`, `booking_agent.py`, `followup_agent.py`
- `orchestrator.py` — chains all 5 agents, manages session lifecycle
- `session_logger.py` — AgentSession class for full agent trace logging
- `config.py` — environment variable management
- `requirements.txt` — Python dependencies
- `.env.example` — API key template
- `.gitignore` — excludes credentials, caches, local data files
- `reports/` folder — design decisions, project summary, version history
- `Resources/claude/SewaBot_Agent_Architecture_for_Antigravity.md` — complete architecture reference

### Decisions Made
- Branching strategy: `agents` branch for this layer, same pattern as `backend` and `ui`
- Local JSON files simulate Firebase writes for MVP (swap-ready for real Firestore)
- Haversine formula for distance (no Maps API key required)
- Gemini used only in Intent Agent and Ranking Agent reasoning text

### Pending
- `mock_providers.json` (40 providers)
- Backend + UI branch analysis and integration
- End-to-end testing

---

## Upcoming

### v0.2.0 — Next
- Add `mock_providers.json` with 40 providers
- Integrate with Saad's backend (FastAPI endpoints)
- Test all 3 demo scenarios end-to-end

### v0.3.0 — Pre-submission
- Connect Flutter UI to live backend
- Lock 3 demo scenarios
- Generate and export agent trace logs
- Final README + architecture diagram
