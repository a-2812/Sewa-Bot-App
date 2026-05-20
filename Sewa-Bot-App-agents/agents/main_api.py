"""
SewaBot Agents API — port 8001
================================
Exposes the full agentic pipeline as REST endpoints.

Primary (new) endpoints:
  POST /extractIntent     — IntentAgent
  POST /getProviders      — DiscoveryAgent + RankingAgent
  POST /getPriceQuote     — QuoteAgent
  POST /executeBooking    — BookingAgent + FollowupAgent

Backward-compatible endpoints:
  POST /chat              — Intent + Discovery + Ranking (single call)
  POST /book              — Booking + Followup (single call)

Utility:
  GET  /agent-logs/{session_id}
  GET  /bookings/{booking_id}
  GET  /providers
  GET  /
"""
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

app = FastAPI(
    title="SewaBot Agents API",
    version="2.0.0",
    description="Agentic orchestration layer for SewaBot — Challenge 2",
)

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


# ─── NEW ENDPOINT 1: POST /extractIntent ─────────────────────────────────────

@app.post("/extractIntent", tags=["Agents"])
async def extract_intent(req: ExtractIntentRequest):
    """
    Step 1 of the agentic pipeline.
    Runs IntentAgent on raw user message.

    Returns: session_id, intent (all fields), workplan, agent_log
    """
    session = AgentSession(req.session_id)

    intent_data, workplan, agent_trace = intent_agent.run(req.message)

    session.log(
        "IntentAgent",
        req.message,
        agent_trace["reasoning"],
        intent_data,
        status=agent_trace["status"],
        duration_ms=agent_trace["latency_ms"],
    )
    session.save_to_file()

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
    Step 2 of the agentic pipeline.
    Runs DiscoveryAgent + RankingAgent using the intent from /extractIntent.

    Returns: session_id, providers (ranked), agent_log
    """
    session = AgentSession(req.session_id)

    service_type  = req.intent.get("service_type", "")
    location      = req.intent.get("location", "")
    time_pref     = req.intent.get("preferred_time", "not_specified")

    # Discovery
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
        return {
            "session_id": session.session_id,
            "providers": [],
            "agent_log": session.logs,
        }

    # Ranking
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

    # Enrich with full provider fields
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
    Step 3 of the agentic pipeline.
    Runs QuoteAgent — deterministic price calculation.

    Returns: quote (with base_fee, urgency_fee, complexity_fee, total_quoted_pkr),
             budget_alternative, agent_log
    """
    session = AgentSession(req.session_id)

    quote_output, quote_reasoning = quote_agent.run(req.intent, req.provider)

    session.log(
        "QuoteAgent",
        {"service_type": req.intent.get("service_type"), "provider": req.provider.get("provider_name", req.provider.get("name"))},
        quote_reasoning,
        {"total_quoted_pkr": quote_output["quote"]["total_quoted_pkr"]},
        duration_ms=quote_output["duration_ms"],
    )
    session.save_to_file()

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
    Step 4 of the agentic pipeline.
    Runs BookingAgent + FollowupAgent.

    Returns: booking, receipt, followups, agent_log
    """
    session = AgentSession(req.session_id)

    # BookingAgent
    bk_output, bk_reasoning = booking_agent.run(req.intent, req.provider, req.quote)
    booking_doc = bk_output["booking_confirmation"]

    session.log(
        "BookingAgent",
        {"provider_id": req.provider.get("provider_id", req.provider.get("id")), "slot": req.intent.get("preferred_time")},
        bk_reasoning,
        {"booking_id": booking_doc["booking_id"], "status": "confirmed"},
        duration_ms=bk_output["agent_trace"]["total_latency_ms"],
    )

    # FollowupAgent
    fu_output, fu_reasoning = followup_agent.run(booking_doc)
    session.log(
        "FollowupAgent",
        {"booking_id": booking_doc["booking_id"]},
        fu_reasoning,
        {"notifications_scheduled": fu_output["notifications_scheduled"]},
        duration_ms=fu_output["duration_ms"],
    )
    session.save_to_file()
    orchestrator._push_log_to_backend(session)

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
    """
    Backward-compatible combined endpoint.
    Runs full Intent → Discovery → Ranking pipeline in one call.
    Returns: session_id, clarification_needed, intent, options, agent_log
    """
    return orchestrator.run_chat(req.message, req.session_id)


# ─── BACKWARD-COMPATIBLE: POST /book ─────────────────────────────────────────

@app.post("/book", tags=["Backward Compatible"])
async def book(req: BookRequest):
    """
    Backward-compatible combined endpoint.
    Runs Booking + Followup pipeline in one call.
    Returns: booking, receipt, followups, agent_log
    """
    return orchestrator.run_book(req.session_id, req.provider_id, req.slot)


# ─── Utility Endpoints ────────────────────────────────────────────────────────

@app.get("/agent-logs/{session_id}", tags=["Utility"])
async def get_agent_logs(session_id: str):
    """Return the complete agent session trace for a given session ID."""
    session = get_session(session_id)
    if not session:
        raise HTTPException(status_code=404, detail=f"Session '{session_id}' not found")
    return session.export()


@app.get("/bookings/{booking_id}", tags=["Utility"])
async def get_booking(booking_id: str):
    """Retrieve booking details — checks backend then local fallback."""
    booking = orchestrator.get_booking(booking_id)
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    return booking


@app.get("/providers", tags=["Utility"])
async def list_providers(service: str = None, location: str = None, limit: int = 10):
    """Basic provider search (delegates to DiscoveryAgent)."""
    return orchestrator.get_providers(service, location, limit)


# ─── Entry Point ──────────────────────────────────────────────────────────────

if __name__ == "__main__":
    uvicorn.run("main_api:app", host="0.0.0.0", port=8001, reload=True)
