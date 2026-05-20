"""
SewaBot Agents — pytest test suite
====================================
Tests the full agentic pipeline with the scenario:
  "Mujhe kal subah G-13 mein AC technician chahiye"

Runs with TEST_MODE=true (no Gemini call, deterministic responses).

Usage:
  cd Sewa-Bot-App-agents/agents
  TEST_MODE=true pytest test_sewabot_pipeline.py -v
"""
import sys
import os
import types
import pytest
import uuid

# ── Set TEST_MODE before importing anything ──────────────────────────────────
os.environ["TEST_MODE"] = "true"
os.environ.setdefault("BACKEND_BASE_URL", "http://localhost:8000")

# ── Mock google.generativeai so no pip install or API key needed ──────────────
mock_genai = types.ModuleType("google.generativeai")
mock_genai.configure = lambda **kwargs: None


class _MockModel:
    """Returns a deterministic AC-technician intent JSON for any prompt."""
    _RESPONSE = (
        '{"service_type": "AC Technician", "location": "G-13, Islamabad", '
        '"preferred_time": "tomorrow_morning", "urgency": "normal", '
        '"budget_sensitivity": "medium", "job_complexity": "simple", '
        '"language_detected": "roman_urdu", "confidence_score": 0.97, '
        '"clarification_needed": false, "clarification_question": null}'
    )

    def generate_content(self, prompt):
        class Resp:
            text = _MockModel._RESPONSE
        return Resp()


mock_genai.GenerativeModel = lambda x: _MockModel()
sys.modules["google"] = types.ModuleType("google")
sys.modules["google.generativeai"] = mock_genai

# ── Also mock requests so no network calls to backend ────────────────────────
mock_requests = types.ModuleType("requests")


class _FakeResp:
    status_code = 201
    def json(self): return {"status": "saved"}


mock_requests.post = lambda *a, **kw: _FakeResp()
mock_requests.get = lambda *a, **kw: _FakeResp()
sys.modules["requests"] = mock_requests

# ── Now we can import agents ──────────────────────────────────────────────────
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import orchestrator
import intent_agent
import discovery_agent
import ranking_agent
import quote_agent
import booking_agent
import followup_agent

# ── Test scenario ─────────────────────────────────────────────────────────────
TEST_INPUT = "Mujhe kal subah G-13 mein AC technician chahiye"


# ─── 1. Intent Agent ──────────────────────────────────────────────────────────

def test_intent_extraction_service_type():
    intent, _, trace = intent_agent.run(TEST_INPUT)
    assert intent["service_type"], "service_type must not be empty"
    assert "ac" in intent["service_type"].lower() or "technician" in intent["service_type"].lower(), \
        f"Expected AC-related service_type, got: {intent['service_type']}"


def test_intent_extraction_location():
    intent, _, _ = intent_agent.run(TEST_INPUT)
    assert intent.get("location"), "location must be extracted"
    assert "g-13" in intent["location"].lower() or "islamabad" in intent["location"].lower(), \
        f"Expected G-13 location, got: {intent['location']}"


def test_intent_extraction_time():
    intent, _, _ = intent_agent.run(TEST_INPUT)
    assert intent.get("preferred_time") == "tomorrow_morning", \
        f"Expected tomorrow_morning, got: {intent.get('preferred_time')}"


def test_intent_no_clarification_needed():
    intent, _, _ = intent_agent.run(TEST_INPUT)
    assert not intent.get("clarification_needed"), \
        "Clear input should not require clarification"


def test_intent_confidence_high():
    intent, _, _ = intent_agent.run(TEST_INPUT)
    assert intent.get("confidence_score", 0) >= 0.7, \
        f"Confidence too low: {intent.get('confidence_score')}"


def test_intent_heuristics_handle_clear_request_when_gemini_fails(monkeypatch):
    class _FailingModel:
        def generate_content(self, prompt):
            raise RuntimeError("simulated Gemini outage")

    monkeypatch.setattr(intent_agent, "model", _FailingModel())

    intent, _, _ = intent_agent.run("I need ac repair services in Islamabad g-13")

    assert intent["service_type"] == "AC Technician"
    assert "g-13" in intent["location"].lower()
    assert "islamabad" in intent["location"].lower()
    assert not intent.get("clarification_needed")


def test_chat_followup_merges_previous_service_when_gemini_fails(monkeypatch):
    class _FailingModel:
        def generate_content(self, prompt):
            raise RuntimeError("simulated Gemini outage")

    monkeypatch.setattr(intent_agent, "model", _FailingModel())
    session_id = f"test_loop_{uuid.uuid4().hex}"

    first = orchestrator.run_chat("hlo", session_id)
    assert first.get("clarification_needed")

    second = orchestrator.run_chat("I want ac repair services", session_id)
    assert second.get("clarification_needed")
    assert second["intent"]["service_type"] == "AC Technician"
    assert "area" in second.get("clarification_question", "").lower()

    third = orchestrator.run_chat("Islamabad g-13", session_id)
    assert third["intent"]["service_type"] == "AC Technician"
    assert "g-13" in third["intent"]["location"].lower()
    assert not third["intent"].get("clarification_needed")


# ─── 2. Discovery Agent ───────────────────────────────────────────────────────

def test_discovery_finds_ac_providers():
    output, _ = discovery_agent.run("AC Technician", "G-13, Islamabad")
    assert output["total_found"] > 0, "Should find at least one AC Technician provider"


def test_discovery_returns_provider_fields():
    output, _ = discovery_agent.run("AC Technician", "G-13, Islamabad")
    if output["total_found"] > 0:
        p = output["providers"][0]
        assert "id" in p or "provider_id" in p, "Provider must have an id"


# ─── 3. Ranking Agent ─────────────────────────────────────────────────────────

def test_ranking_returns_providers():
    disc, _ = discovery_agent.run("AC Technician", "G-13, Islamabad")
    if disc["total_found"] > 0:
        rank, _ = ranking_agent.run(
            disc["providers"], disc["canonical_service"], "tomorrow_morning"
        )
        assert rank["total_ranked"] > 0


def test_ranking_has_top_pick():
    disc, _ = discovery_agent.run("AC Technician", "G-13, Islamabad")
    if disc["total_found"] > 0:
        rank, _ = ranking_agent.run(
            disc["providers"], disc["canonical_service"], "tomorrow_morning"
        )
        assert rank["top_pick"] is not None, "Ranking must produce a top pick"


def test_ranking_sorted_by_score():
    disc, _ = discovery_agent.run("AC Technician", "G-13, Islamabad")
    if disc["total_found"] > 1:
        rank, _ = ranking_agent.run(
            disc["providers"], disc["canonical_service"], "tomorrow_morning"
        )
        scores = [p.get("total_score", 0) for p in rank["ranked_providers"]]
        assert scores == sorted(scores, reverse=True), "Providers must be sorted by score desc"


# ─── 4. Quote Agent ───────────────────────────────────────────────────────────

def test_quote_generation_positive_price():
    intent, _, _ = intent_agent.run(TEST_INPUT)
    disc, _ = discovery_agent.run("AC Technician", "G-13, Islamabad")
    if disc["total_found"] > 0:
        provider = disc["providers"][0]
        out, _ = quote_agent.run(intent, provider)
        assert out["quote"]["total_quoted_pkr"] > 0, "Quote price must be positive"


def test_quote_has_required_fields():
    intent, _, _ = intent_agent.run(TEST_INPUT)
    disc, _ = discovery_agent.run("AC Technician", "G-13, Islamabad")
    if disc["total_found"] > 0:
        provider = disc["providers"][0]
        out, _ = quote_agent.run(intent, provider)
        q = out["quote"]
        for field in ["base_fee", "total_quoted_pkr", "currency"]:
            assert field in q, f"Quote must have field: {field}"


# ─── 5. Booking Agent ─────────────────────────────────────────────────────────

def test_booking_generates_id():
    intent, _, _ = intent_agent.run(TEST_INPUT)
    disc, _ = discovery_agent.run("AC Technician", "G-13, Islamabad")
    if disc["total_found"] > 0:
        provider = disc["providers"][0]
        out_q, _ = quote_agent.run(intent, provider)
        out_b, _ = booking_agent.run(intent, provider, out_q["quote"])
        bk = out_b["booking_confirmation"]
        assert bk.get("booking_id"), "Booking must have an ID"
        assert bk["booking_id"].startswith("BK-"), \
            f"Booking ID must start with BK-, got: {bk['booking_id']}"


def test_booking_status_confirmed():
    intent, _, _ = intent_agent.run(TEST_INPUT)
    disc, _ = discovery_agent.run("AC Technician", "G-13, Islamabad")
    if disc["total_found"] > 0:
        provider = disc["providers"][0]
        out_q, _ = quote_agent.run(intent, provider)
        out_b, _ = booking_agent.run(intent, provider, out_q["quote"])
        bk = out_b["booking_confirmation"]
        assert bk.get("status") in ("confirmed", "CONFIRMED"), \
            f"Booking status must be confirmed, got: {bk.get('status')}"


# ─── 6. Followup Agent ────────────────────────────────────────────────────────

def test_followup_schedules_notifications():
    intent, _, _ = intent_agent.run(TEST_INPUT)
    disc, _ = discovery_agent.run("AC Technician", "G-13, Islamabad")
    if disc["total_found"] > 0:
        provider = disc["providers"][0]
        out_q, _ = quote_agent.run(intent, provider)
        out_b, _ = booking_agent.run(intent, provider, out_q["quote"])
        out_f, _ = followup_agent.run(out_b["booking_confirmation"])
        assert out_f["notifications_scheduled"] > 0, \
            "Followup must schedule at least one notification"


# ─── 7. Full end-to-end pipeline ─────────────────────────────────────────────

def test_full_pipeline_chat_returns_options():
    result = orchestrator.run_chat(TEST_INPUT)
    assert "session_id" in result
    assert "intent" in result
    assert isinstance(result.get("options"), list), "Options must be a list"


def test_full_pipeline_book_returns_booking():
    chat = orchestrator.run_chat(TEST_INPUT)
    session_id = chat["session_id"]
    options = chat.get("options", [])
    if not options:
        pytest.skip("No providers found — skipping booking test")
    provider_id = options[0].get("provider_id") or options[0].get("id", "p001")
    slot = options[0].get("matched_slot", "10:00")
    book = orchestrator.run_book(session_id, provider_id, slot)
    assert "booking" in book
    assert book["booking"].get("booking_id"), "Booking must have an ID"


def test_full_pipeline_agent_log_has_all_agents():
    chat = orchestrator.run_chat(TEST_INPUT)
    session_id = chat["session_id"]
    options = chat.get("options", [])
    if not options:
        pytest.skip("No providers found")
    provider_id = options[0].get("provider_id") or options[0].get("id", "p001")
    slot = options[0].get("matched_slot", "10:00")
    book = orchestrator.run_book(session_id, provider_id, slot)
    agents_run = [log["agent"] for log in book.get("agent_log", [])]
    for expected in ["IntentAgent", "DiscoveryAgent", "RankingAgent", "BookingAgent", "FollowupAgent"]:
        assert expected in agents_run, f"Agent not in log: {expected}"
