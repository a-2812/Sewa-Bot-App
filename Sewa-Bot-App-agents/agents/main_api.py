"""
SewaBot Agents API — port from $PORT env var (Render) or 8001 (local)
================================
Exposes the full agentic pipeline as REST endpoints.

Primary endpoints:
  POST /extractIntent     — IntentAgent
  POST /getProviders      — DiscoveryAgent + RankingAgent
  POST /getPriceQuote     — QuoteAgent
  POST /executeBooking    — BookingAgent + FollowupAgent

Backward-compatible:
  POST /chat              — Intent + Discovery + Ranking (single call)
  POST /book              — Booking + Followup (single call)

Utility:
  GET  /agent-logs/{session_id}
  GET  /bookings/{booking_id}
  GET  /providers
  GET  /
"""
import os
import threading
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List, Any, Dict

import orchestrator
import intent_agent
import discovery_agent
import ranking_agent
import quote_agent
import booking_agent
import followup_agent
from session_logger import AgentSession, get_session
from config import BACKEND_BASE_URL

app = FastAPI(
    title="SewaBot Agents API",
    version="2.0.0",
    description="Agentic orchestration layer for SewaBot",
)

# ── CORS ──────────────────────────────────────────────────────────────────────
# Restrict in production — allow all for now so Flutter/web clients work
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


# ─── Request/Response Models ──────────────────────────────────────────────────

class ChatRequest(BaseModel):
    message: str
    session_id: Optional[str] = None


class BookRequest(BaseModel):
    session_id: str
    provider_id: str
    slot: str


class ExtractIntentRequest(BaseModel):
    message: str
    session_id: Optional[str] = None


class GetProvidersRequest(BaseModel):
    session_id: str
    intent: Dict[str, Any]


class GetPriceQuoteRequest(BaseModel):
    session_id: str
    intent: Dict[str, Any]
    provider: Dict[str, Any]


class ExecuteBookingRequest(BaseModel):
    session_id: str
    intent: Dict[str, Any]
    provider: Dict[str, Any]
    quote: Dict[str, Any]


# ─── Health ───────────────────────────────────────────────────────────────────

@app.get("/", tags=["Health"])
def health():
    return {
        "status": "ok",
        "service": "SewaBot Agents API",
        "version": "2.0.0",
        "backend_url": BACKEND_BASE_URL,
        "endpoints": [
            "POST /extractIntent",
            "POST /getProviders",
            "POST /getPriceQuote",
            "POST /executeBooking",
            "POST /chat",
            "POST /book",
            "GET  /agent-logs/{session_id}",
            "GET  /bookings/{booking_id}",
            "GET  /providers",
        ]
    }


# ─── Helper: fire-and-forget log push ────────────────────────────────────────

def _push_log_async(session: AgentSession):
    """Push session log to backend in a background thread.
    Never blocks or fails the user response.
    """
    def _push():
        try:
            orchestrator._push_log_to_backend(session)
        except Exception:
            pass
    threading.Thread(target=_push, daemon=True).start()


# ─── NEW ENDPOINT 1: POST /extractIntent ─────────────────────────────────────

@app.post("/extractIntent", tags=["Agents"])
async def extract_intent(req: ExtractIntentRequest):
    """
    Step 1: Run IntentAgent on raw user message.
    Returns: session_id, intent, workplan, agent_log
    """
    if not req.message or not req.message.strip():
        raise HTTPException(status_code=422, detail="message cannot be empty")

    session = AgentSession(req.session_id)

    context_msgs = [
        log["input"] for log in session.logs
        if log.get("agent") == "IntentAgent" and isinstance(log.get("input"), str)
    ]
    context_str = "\n".join([f"- {m}" for m in context_msgs])

    intent_data, workplan, agent_trace = intent_agent.run(req.message, context_str)

    session.log(
        "IntentAgent",
        req.message,
        agent_trace["reasoning"],
        intent_data,
        status=agent_trace["status"],
        duration_ms=agent_trace["latency_ms"],
    )
    session.save_to_file()
    _push_log_async(session)

    return {
        "session_id": session.session_id,
        "intent": intent_data,
        "workplan": workplan,
        "agent_log": session.logs,
    }


# ─── NEW ENDPOINT 2: POST /getProviders ──────────────────────────────────────

@app.post("/getProviders", tags=["Agents"])
async def get_providers_for_intent(req: GetProvidersRequest):
    """
    Step 2: Run DiscoveryAgent + RankingAgent using intent from /extractIntent.
    Returns: session_id, providers (ranked), agent_log
    """
    service_type = req.intent.get("service_type", "").strip()
    location = req.intent.get("location", "") or ""

    if not service_type:
        raise HTTPException(
            status_code=422,
            detail="intent.service_type is required and must not be empty"
        )
    if not location.strip():
        raise HTTPException(
            status_code=422,
            detail="intent.location is required — ask the user for their area"
        )

    session = AgentSession(req.session_id)
    time_pref = req.intent.get("preferred_time", "not_specified")

    disc_output, disc_reasoning = discovery_agent.run(service_type, location)
    session.log(
        "DiscoveryAgent",
        {"service_type": service_type, "location": location},
        disc_reasoning,
        {"total_found": disc_output["total_found"]},
        duration_ms=disc_output["duration_ms"],
    )

    if disc_output["total_found"] == 0:
        session.save_to_file()
        _push_log_async(session)
        return {
            "session_id": session.session_id,
            "providers": [],
            "agent_log": session.logs,
        }

    rank_output, rank_reasoning = ranking_agent.run(
        disc_output["providers"], disc_output["canonical_service"], time_pref
    )
    top_name = rank_output["top_pick"]["provider_name"] if rank_output["top_pick"] else None
    session.log(
        "RankingAgent",
        {"provider_count": disc_output["total_found"], "time_preference": time_pref},
        rank_reasoning,
        {"top_pick": top_name, "total_ranked": rank_output["total_ranked"]},
        duration_ms=rank_output["duration_ms"],
    )
    session.save_to_file()
    _push_log_async(session)

    enriched = orchestrator._enrich_providers(
        rank_output["ranked_providers"], disc_output["providers"]
    )

    return {
        "session_id": session.session_id,
        "providers": enriched,
        "agent_log": session.logs,
    }


# ─── NEW ENDPOINT 3: POST /getPriceQuote ─────────────────────────────────────

@app.post("/getPriceQuote", tags=["Agents"])
async def get_price_quote(req: GetPriceQuoteRequest):
    """
    Step 3: Run QuoteAgent — deterministic price calculation.
    Returns: quote, budget_alternative, agent_log
    """
    if not req.provider.get("provider_id") and not req.provider.get("id"):
        raise HTTPException(
            status_code=422,
            detail="provider must include provider_id or id"
        )

    session = AgentSession(req.session_id)
    quote_output, quote_reasoning = quote_agent.run(req.intent, req.provider)

    session.log(
        "QuoteAgent",
        {
            "service_type": req.intent.get("service_type"),
            "provider": req.provider.get("provider_name", req.provider.get("name"))
        },
        quote_reasoning,
        {"total_quoted_pkr": quote_output["quote"]["total_quoted_pkr"]},
        duration_ms=quote_output["duration_ms"],
    )
    session.save_to_file()
    _push_log_async(session)

    return {
        "session_id": session.session_id,
        "quote": quote_output["quote"],
        "budget_alternative": quote_output["budget_alternative"],
        "agent_log": session.logs,
    }


# ─── NEW ENDPOINT 4: POST /executeBooking ────────────────────────────────────

@app.post("/executeBooking", tags=["Agents"])
async def execute_booking(req: ExecuteBookingRequest):
    """
    Step 4: Run BookingAgent + FollowupAgent.
    Returns: booking, receipt, followups, agent_log
    """
    provider_id = req.provider.get("provider_id") or req.provider.get("id", "")
    time_slot = req.intent.get("preferred_time", "")

    if not provider_id:
        raise HTTPException(
            status_code=422,
            detail="provider must include provider_id or id"
        )
    if not time_slot:
        raise HTTPException(
            status_code=422,
            detail="intent.preferred_time is required"
        )

    session = AgentSession(req.session_id)

    bk_output, bk_reasoning = booking_agent.run(req.intent, req.provider, req.quote)
    booking_doc = bk_output["booking_confirmation"]

    session.log(
        "BookingAgent",
        {"provider_id": provider_id, "slot": time_slot},
        bk_reasoning,
        {"booking_id": booking_doc["booking_id"], "status": "confirmed"},
        duration_ms=bk_output["agent_trace"]["total_latency_ms"],
    )

    fu_output, fu_reasoning = followup_agent.run(booking_doc)
    session.log(
        "FollowupAgent",
        {"booking_id": booking_doc["booking_id"]},
        fu_reasoning,
        {"notifications_scheduled": fu_output["notifications_scheduled"]},
        duration_ms=fu_output["duration_ms"],
    )
    session.save_to_file()
    _push_log_async(session)

    return {
        "session_id": session.session_id,
        "booking": booking_doc,
        "receipt": booking_doc.get("receipt", ""),
        "followups": fu_output.get("notifications", []),
        "agent_log": session.logs,
    }


# ─── BACKWARD-COMPATIBLE: POST /chat ─────────────────────────────────────────

@app.post("/chat", tags=["Backward Compatible"])
async def chat(req: ChatRequest):
    """Combined endpoint: Intent → Discovery → Ranking in one call."""
    if not req.message or not req.message.strip():
        raise HTTPException(status_code=422, detail="message cannot be empty")
    return orchestrator.run_chat(req.message, req.session_id)


# ─── BACKWARD-COMPATIBLE: POST /book ─────────────────────────────────────────

@app.post("/book", tags=["Backward Compatible"])
async def book(req: BookRequest):
    """Combined endpoint: Booking + Followup in one call."""
    return orchestrator.run_book(req.session_id, req.provider_id, req.slot)


# ─── Utility Endpoints ────────────────────────────────────────────────────────

@app.get("/agent-logs/{session_id}", tags=["Utility"])
async def get_agent_logs(session_id: str):
    """Return the complete agent session trace for a given session ID."""
    session = get_session(session_id)
    if not session:
        raise HTTPException(
            status_code=404, detail=f"Session '{session_id}' not found"
        )
    return session.export()


@app.get("/bookings/{booking_id}", tags=["Utility"])
async def get_booking(booking_id: str):
    """Retrieve booking details — checks backend then local fallback."""
    booking = orchestrator.get_booking(booking_id)
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return booking


@app.get("/providers", tags=["Utility"])
async def list_providers(
    service: str = None, location: str = None, limit: int = 10
):
    """Basic provider search (delegates to DiscoveryAgent)."""
    return orchestrator.get_providers(service, location, limit)


# ─── Entry Point ──────────────────────────────────────────────────────────────

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8001))
    uvicorn.run("main_api:app", host="0.0.0.0", port=port, reload=False)
