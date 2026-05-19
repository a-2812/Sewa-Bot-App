import uuid
from datetime import datetime
import json
import os

import intent_agent
import discovery_agent
import ranking_agent
import booking_agent
import followup_agent
from session_logger import AgentSession


def run_chat(user_message: str, session_id: str = None) -> dict:
    """
    POST /chat
    Runs Intent -> Discovery -> Ranking agents
    """
    session = AgentSession(session_id)

    # 1. Intent Agent
    intent_data, workplan, agent_trace_int = intent_agent.run(user_message)
    session.log(
        "IntentAgent", user_message,
        agent_trace_int["reasoning"], intent_data,
        duration_ms=agent_trace_int["latency_ms"]
    )
    
    # Check if fallback/clarification is needed
    if intent_data.get("clarification_needed"):
        session.save_to_file()
        return {
            "session_id": session.session_id,
            "clarification_needed": True,
            "clarification_question": intent_data.get("clarification_question"),
            "agent_log": session.logs
        }

    # 2. Discovery Agent
    service_type = intent_data.get("service_type", "")
    location = intent_data.get("location", "")
    
    disc_output, disc_reasoning = discovery_agent.run(service_type, location)
    session.log(
        "DiscoveryAgent", {"service_type": service_type, "location": location},
        disc_reasoning, {"total_found": disc_output["total_found"]},
        duration_ms=disc_output["duration_ms"]
    )

    if disc_output["total_found"] == 0:
        session.save_to_file()
        return {
            "session_id": session.session_id,
            "options": [],
            "agent_log": session.logs
        }

    # 3. Ranking Agent
    time_pref = intent_data.get("preferred_time", "not_specified")
    rank_output, rank_reasoning = ranking_agent.run(
        disc_output["providers"],
        disc_output["canonical_service"],
        time_pref
    )
    session.log(
        "RankingAgent", {"provider_count": disc_output["total_found"], "time_preference": time_pref},
        rank_reasoning,
        {"top_pick": rank_output["top_pick"]["provider_name"] if rank_output["top_pick"] else None},
        duration_ms=rank_output["duration_ms"]
    )
    
    session.save_to_file()

    return {
        "session_id": session.session_id,
        "options": rank_output["ranked_providers"],
        "agent_log": session.logs
    }


def run_book(session_id: str, provider_id: str, slot: str) -> dict:
    """
    POST /book
    Runs Booking -> Follow-up agents
    """
    session = AgentSession(session_id)
    
    # Retrieve intent from session logs
    intent = {}
    provider = {"provider_id": provider_id, "provider_name": "Selected Provider"}
    quote = {"total_quoted_pkr": 1500} # Mock quote since we dropped QuoteAgent
    
    for log in session.logs:
        if log["agent"] == "IntentAgent":
            intent = log["output"]
            break
            
    # Also find the provider details from RankingAgent logs
    for log in session.logs:
        if log["agent"] == "RankingAgent":
            # Just grab it from the file directly or fallback
            break
            
    # Use the selected slot
    intent["preferred_time"] = slot
    
    # 4. Booking Agent
    bk_output, bk_reasoning = booking_agent.run(intent, provider, quote)
    session.log(
        "BookingAgent",
        {"provider_id": provider_id, "slot": slot, "date": datetime.now().strftime("%Y-%m-%d")},
        bk_reasoning,
        {"booking_id": bk_output["booking_confirmation"]["booking_id"], "status": "confirmed"},
        duration_ms=bk_output["agent_trace"]["total_latency_ms"]
    )

    # 5. Follow-up Agent
    fu_output, fu_reasoning = followup_agent.run(bk_output["booking_confirmation"])
    session.log(
        "FollowupAgent",
        {"booking_id": bk_output["booking_confirmation"]["booking_id"]},
        fu_reasoning,
        {"notifications_scheduled": fu_output["notifications_scheduled"]},
        duration_ms=fu_output["duration_ms"]
    )
    
    session.save_to_file()

    return {
        "booking": bk_output["booking_confirmation"],
        "receipt": bk_output["booking_confirmation"].get("user_message", ""),
        "followups": bk_output["booking_confirmation"].get("reminders_scheduled", []),
        "agent_log": session.logs
    }


def get_booking(booking_id: str) -> dict:
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
