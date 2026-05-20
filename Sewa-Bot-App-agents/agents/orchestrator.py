"""
SewaBot Agent Orchestrator
==========================
Coordinates the full agentic pipeline:
  POST /chat  → IntentAgent → DiscoveryAgent → RankingAgent
  POST /book  → BookingAgent → FollowupAgent

All provider data is fetched from the backend API.
Bookings and notifications are persisted via the backend API.
"""

import uuid
from datetime import datetime
import json
import os
import random

try:
    import requests as _requests
except ImportError:
    _requests = None

import intent_agent
import discovery_agent
import ranking_agent
import booking_agent
import followup_agent
from session_logger import AgentSession
from config import BACKEND_BASE_URL


def _is_empty_intent_value(value) -> bool:
    if value is None:
        return True
    return str(value).strip().lower() in (
        "",
        "null",
        "none",
        "not mentioned",
        "unknown",
        "not_specified",
    )


def _build_conversation_context(logs: list) -> tuple[str, dict]:
    """
    Build prompt context from previous user turns and extracted intent fields.
    Also returns an accumulated intent so follow-up answers can fill one field
    without losing fields extracted earlier.
    """
    context_lines = []
    previous_intent = {}
    tracked_fields = [
        "service_type",
        "location",
        "preferred_time",
        "urgency",
        "budget_sensitivity",
        "job_complexity",
        "language_detected",
    ]

    for log in logs:
        if log.get("agent") != "IntentAgent":
            continue

        user_input = log.get("input")
        output = log.get("output") if isinstance(log.get("output"), dict) else {}

        if isinstance(user_input, str) and user_input.strip():
            context_lines.append(f"- User: {user_input.strip()}")

        if output:
            extracted = []
            for field in tracked_fields:
                value = output.get(field)
                if not _is_empty_intent_value(value):
                    previous_intent[field] = value
                    extracted.append(f"{field}={value}")
            if extracted:
                context_lines.append(f"  Extracted: {', '.join(extracted)}")
            if output.get("clarification_needed"):
                question = output.get("clarification_question") or "clarification requested"
                context_lines.append(f"  Bot asked: {question}")

    return "\n".join(context_lines), previous_intent


def run_chat(user_message: str, session_id: str = None) -> dict:
    """
    POST /chat
    Runs IntentAgent → DiscoveryAgent → RankingAgent.
    Returns: session_id, intent, options (ranked providers), agent_log
    """
    session = AgentSession(session_id)

    # ── 1. Intent Agent ───────────────────────────────────────
    context_str, previous_intent = _build_conversation_context(session.logs)
    
    intent_data, workplan, agent_trace_int = intent_agent.run(
        user_message,
        context_str,
        previous_intent,
    )
    session.log(
        "IntentAgent", user_message,
        agent_trace_int["reasoning"], intent_data,
        duration_ms=agent_trace_int["latency_ms"],
    )

    # Clarification needed?
    if intent_data.get("clarification_needed"):
        session.save_to_file()
        _push_log_to_backend(session)
        return {
            "session_id": session.session_id,
            "clarification_needed": True,
            "clarification_question": intent_data.get("clarification_question"),
            "intent": intent_data,
            "options": [],
            "agent_log": session.logs,
        }

    # ── 2. Discovery Agent ────────────────────────────────────
    service_type = intent_data.get("service_type", "")
    location     = intent_data.get("location", "")

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
        _push_log_to_backend(session)
        return {
            "session_id": session.session_id,
            "clarification_needed": False,
            "intent": intent_data,
            "options": [],
            "agent_log": session.logs,
        }

    # ── 3. Ranking Agent ──────────────────────────────────────
    time_pref = intent_data.get("preferred_time", "not_specified")
    rank_output, rank_reasoning = ranking_agent.run(
        disc_output["providers"],
        disc_output["canonical_service"],
        time_pref,
    )
    top_name = rank_output["top_pick"]["provider_name"] if rank_output["top_pick"] else None
    session.log(
        "RankingAgent",
        {"provider_count": disc_output["total_found"], "time_preference": time_pref},
        rank_reasoning,
        {"top_pick": top_name},
        duration_ms=rank_output["duration_ms"],
    )

    session.save_to_file()
    _push_log_to_backend(session)

    # Enrich ranked providers with full backend fields (area, experience_years, etc.)
    enriched_options = _enrich_providers(rank_output["ranked_providers"], disc_output["providers"])

    return {
        "session_id": session.session_id,
        "clarification_needed": False,
        "intent": intent_data,
        "options": enriched_options,
        "agent_log": session.logs,
    }


def run_book(session_id: str, provider_id: str, slot: str) -> dict:
    """
    POST /book
    Runs BookingAgent → FollowupAgent.
    Returns: booking, receipt, followups, agent_log
    """
    session = AgentSession(session_id)

    # Retrieve intent from session logs
    intent = {}
    provider_from_logs = {}
    for log in session.logs:
        if log["agent"] == "IntentAgent":
            intent = log["output"]
        if log["agent"] == "DiscoveryAgent":
            # We'll enrich provider below from backend
            pass

    intent["preferred_time"] = slot
    intent["session_id"] = session_id

    # Fetch provider details from backend
    provider = _fetch_provider(provider_id)
    if not provider:
        provider = {"provider_id": provider_id, "provider_name": "Selected Provider"}

    # Normalise provider dict keys for booking_agent
    provider["provider_id"]   = provider.get("id", provider_id)
    provider["provider_name"] = provider.get("name", "Provider")
    provider["price_pkr"]     = provider.get("price_pkr", provider.get("price", 1500))

    quote = {"total_quoted_pkr": provider["price_pkr"]}

    # ── 4. Booking Agent ──────────────────────────────────────
    bk_output, bk_reasoning = booking_agent.run(intent, provider, quote)
    booking_doc = bk_output["booking_confirmation"]
    session.log(
        "BookingAgent",
        {"provider_id": provider_id, "slot": slot},
        bk_reasoning,
        {"booking_id": booking_doc["booking_id"], "status": "confirmed"},
        duration_ms=bk_output["agent_trace"]["total_latency_ms"],
    )

    # ── 5. Follow-up Agent ────────────────────────────────────
    fu_output, fu_reasoning = followup_agent.run(booking_doc)
    session.log(
        "FollowupAgent",
        {"booking_id": booking_doc["booking_id"]},
        fu_reasoning,
        {"notifications_scheduled": fu_output["notifications_scheduled"]},
        duration_ms=fu_output["duration_ms"],
    )

    session.save_to_file()
    _push_log_to_backend(session)

    return {
        "booking": booking_doc,
        "receipt": booking_doc.get("receipt", ""),
        "followups": fu_output.get("notifications", []),
        "agent_log": session.logs,
    }


def get_booking(booking_id: str) -> dict:
    """Try backend first, then local file."""
    if _requests:
        try:
            resp = _requests.get(f"{BACKEND_BASE_URL}/bookings/{booking_id}", timeout=10)
            if resp.status_code == 200:
                return resp.json()
        except Exception:
            pass

    fallback_path = os.path.join(os.path.dirname(__file__), "data", "bookings.json")
    if os.path.exists(fallback_path):
        with open(fallback_path, "r", encoding="utf-8") as f:
            bookings = json.load(f)
            for b in bookings:
                if b.get("booking_id") == booking_id:
                    return b
    return {}


def get_providers(service: str, location: str, limit: int) -> list:
    disc_output, _ = discovery_agent.run(service or "", location or "", radius_km=50)
    return disc_output.get("providers", [])[:limit]


# ── Helpers ────────────────────────────────────────────────────────────────

def _fetch_provider(provider_id: str) -> dict:
    """Fetch a single provider record from backend."""
    if _requests:
        try:
            resp = _requests.get(f"{BACKEND_BASE_URL}/providers", timeout=10)
            if resp.status_code == 200:
                for p in resp.json().get("providers", []):
                    if p.get("id") == provider_id:
                        return p
        except Exception:
            pass
    return {}


def _enrich_providers(ranked: list, discovered: list) -> list:
    """
    Merge ranking agent output with full provider data from discovery
    so Flutter gets all fields it needs (area, experience_years, etc.).
    """
    discovered_map = {p.get("id", ""): p for p in discovered}
    enriched = []
    for r in ranked:
        pid = r.get("provider_id", "")
        full = discovered_map.get(pid, {})
        merged = {**full, **r}
        # Ensure Flutter-required fields have values
        loc = full.get("location", {})
        merged["area"]             = full.get("area", loc.get("area", loc.get("city", "Nearby")))
        merged["experience_years"] = full.get("experience_years", 3)
        merged["review_count"]     = full.get("review_count", random.randint(40, 150))
        merged["on_time_score"]    = full.get("on_time_score", round(random.uniform(0.85, 0.98), 2))
        
        price = full.get("price_pkr", full.get("price", 0))
        merged["price_pkr"]        = price
        
        if price < 1500:
            tier = "Budget"
        elif price <= 2500:
            tier = "Standard"
        else:
            tier = "Premium"
            
        merged["price_tier"]       = full.get("price_tier", tier)
        merged["available_slots"]  = full.get("available_slots", ["10:00"])
        merged["phone"]            = full.get("phone", "")
        enriched.append(merged)
    return enriched


def _push_log_to_backend(session: AgentSession):
    """Push session log to backend POST /agent-logs for persistence."""
    if not _requests:
        return
    try:
        _requests.post(
            f"{BACKEND_BASE_URL}/agent-logs",
            json=session.export(),
            timeout=5,
        )
    except Exception:
        pass  # Non-critical; logs are already saved locally
