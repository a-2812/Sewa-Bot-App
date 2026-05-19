import uuid
from datetime import datetime
import intent_agent
import discovery_agent
import ranking_agent
import quote_agent
import booking_agent
import followup_agent
from session_logger import AgentSession


def _session_id() -> str:
    return f"SWB-{datetime.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:6].upper()}"


def run_intent(user_message: str) -> dict:
    """
    POST /extractIntent
    Returns: {intent, workplan, agent_trace}
    """
    session = AgentSession(_session_id())

    intent_data, workplan, agent_trace = intent_agent.run(user_message)

    session.log(
        "IntentAgent", user_message,
        agent_trace["reasoning"], intent_data,
        duration_ms=agent_trace["latency_ms"]
    )
    session.save_to_file()

    return {
        "intent": intent_data,
        "workplan": workplan,
        "agent_trace": agent_trace
    }


def run_discovery_and_ranking(intent: dict) -> list:
    """
    POST /getProviders
    Returns: list of ranked provider objects
    """
    service_type = intent.get("service_type", "")
    location = intent.get("location", "")

    session = AgentSession(_session_id())

    # Agent 2: Discovery
    disc_output, disc_reasoning = discovery_agent.run(service_type, location)
    session.log(
        "DiscoveryAgent", {"service_type": service_type, "location": location},
        disc_reasoning, {"total_found": disc_output["total_found"]},
        duration_ms=disc_output["duration_ms"]
    )

    if disc_output["total_found"] == 0:
        session.save_to_file()
        return []

    # Agent 3: Ranking
    rank_output, rank_reasoning = ranking_agent.run(
        disc_output["providers"],
        disc_output["canonical_service"]
    )
    session.log(
        "RankingAgent", {"provider_count": disc_output["total_found"]},
        rank_reasoning,
        {"top_pick": rank_output["top_pick"]["provider_name"] if rank_output["top_pick"] else None},
        duration_ms=rank_output["duration_ms"]
    )
    session.save_to_file()

    return rank_output["ranked_providers"]


def run_quote(intent: dict, provider: dict) -> dict:
    """
    POST /getPriceQuote
    Returns: {quote, budget_alternative, agent_trace}
    """
    session = AgentSession(_session_id())

    qt_output, qt_reasoning = quote_agent.run(intent, provider)
    session.log(
        "QuoteAgent", {"service": intent.get("service_type"), "provider": provider.get("provider_name")},
        qt_reasoning, {"total_quoted_pkr": qt_output["quote"]["total_quoted_pkr"]},
        duration_ms=qt_output["agent_trace"]["latency_ms"]
    )
    session.save_to_file()

    return qt_output


def run_booking(intent: dict, provider: dict, quote: dict) -> dict:
    """
    POST /executeBooking
    Returns: {booking_confirmation, agent_trace}
    """
    session = AgentSession(_session_id())

    bk_output, bk_reasoning = booking_agent.run(intent, provider, quote)
    session.log(
        "BookingAgent",
        {"provider": provider.get("provider_name"), "slot": intent.get("preferred_time")},
        bk_reasoning,
        {"booking_id": bk_output["booking_confirmation"]["booking_id"], "status": "confirmed"},
        duration_ms=bk_output["agent_trace"]["total_latency_ms"]
    )

    # Agent 5: Follow-up notifications
    fu_output, fu_reasoning = followup_agent.run(bk_output["booking_confirmation"])
    session.log(
        "FollowupAgent",
        {"booking_id": bk_output["booking_confirmation"]["booking_id"]},
        fu_reasoning,
        {"notifications_scheduled": fu_output["notifications_scheduled"]},
        duration_ms=fu_output["duration_ms"]
    )
    session.save_to_file()

    return bk_output


def run_dispute(booking_id: str, dispute_type: str, details: str) -> dict:
    """
    POST /submitDispute
    Returns: dispute confirmation
    """
    dispute_id = f"DSP-{uuid.uuid4().hex[:8].upper()}"
    return {
        "status": "received",
        "dispute_id": dispute_id,
        "booking_id": booking_id,
        "type": dispute_type,
        "message": "Your dispute has been received and will be reviewed within 24 hours.",
        "created_at": datetime.now().isoformat()
    }
