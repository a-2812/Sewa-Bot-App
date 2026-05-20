import json
import time
import google.generativeai as genai
from config import GEMINI_API_KEY

genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel("gemini-2.5-flash")

INTENT_PROMPT = """
You are a multilingual service request parser for Pakistan's informal economy.

Parse the user's request and return ONLY valid JSON with these exact fields:
- service_type: human-readable service name (e.g. "AC Technician", "Plumber", "Electrician", "Math Tutor", "Beautician", "Carpenter")
- location: area/sector name in Pakistan (e.g. "G-13, Islamabad", "DHA Lahore", "Gulberg, Lahore"). Set to null ONLY if genuinely not mentioned at all.
- preferred_time: one of ["urgent", "today_morning", "today_afternoon", "today_evening", "tomorrow_morning", "tomorrow_afternoon", "tomorrow_evening", "not_specified"]
- urgency: one of ["urgent", "high", "normal"]
- budget_sensitivity: one of ["high", "medium", "low"]
- job_complexity: one of ["simple", "intermediate", "complex"]
- language_detected: one of ["urdu", "roman_urdu", "english", "mixed"]
- confidence_score: float 0.0 to 1.0
- clarification_needed: boolean — set true ONLY if EITHER service_type OR location cannot be determined
- clarification_question: short friendly question in the SAME language as the user. null if not needed.

IMPORTANT location rules:
- If the user mentions a city (Islamabad, Lahore, Karachi, Rawalpindi, etc.) without a specific area, use that city name as location
- If the user mentions a sector/area (G-13, F-10, DHA, Gulberg, Bahria Town, Cantt, etc.), include both area and city if inferrable
- If NO location is mentioned at all → set location=null and clarification_needed=true
- The clarification_question for missing location should ask for their area/city in the user's language

Example clarification questions:
- Roman Urdu: "Aap ka area ya city kia hai? Jaise G-13 Islamabad ya DHA Lahore."
- English: "Which area or city are you in? For example, G-13 Islamabad or DHA Lahore."
- Urdu: "آپ کا علاقہ یا شہر کیا ہے؟"

Common Pakistani expressions:
- chahiye / چاہیے = I need
- karwana hai = I want it done
- abhi / فوری = urgent/right now
- kal subah = tomorrow morning
- aaj shaam = this evening
- bilkul kaam nahi = completely broken (high urgency, complex)
- thora sa problem = small issue (simple)

Return ONLY valid JSON, no markdown, no explanation.

Previous conversation context (if any):
{context}

User's latest request: "{user_input}"
"""


def run(user_input: str, context: str = "") -> tuple[dict, str, dict]:
    start = time.time()

    prompt = INTENT_PROMPT.format(user_input=user_input, context=context or "None")

    try:
        response = model.generate_content(prompt)
        raw = response.text.strip()
        if raw.startswith("```"):
            lines = raw.split("\n")
            raw = "\n".join(lines[1:-1])
        intent_data = json.loads(raw)
    except Exception as e:
        print(f"\n[INTENT AGENT ERROR]: Gemini API failed: {e}\n")
        intent_data = {
            "service_type": "unknown",
            "location": None,
            "preferred_time": "not_specified",
            "urgency": "normal",
            "budget_sensitivity": "medium",
            "job_complexity": "simple",
            "language_detected": "mixed",
            "confidence_score": 0.3,
            "clarification_needed": True,
            "clarification_question": "Could you please clarify what service you need and your area/city?"
        }

    # ── Post-parse enforcement: location is ALWAYS required ──────────────────
    # Even if Gemini returns clarification_needed=False, validate fields.
    # This ensures we never pass a null location to DiscoveryAgent.
    location = intent_data.get("location")
    service  = intent_data.get("service_type", "unknown")

    location_missing = (
        location is None
        or str(location).strip().lower() in ("", "null", "none", "not mentioned", "unknown")
    )
    service_missing = (
        not service
        or service.strip().lower() in ("", "null", "none", "unknown")
    )

    if location_missing and not intent_data.get("clarification_needed"):
        lang = intent_data.get("language_detected", "mixed")
        if lang == "urdu":
            question = "آپ کا علاقہ یا شہر کیا ہے؟ مثلاً G-13 اسلام آباد یا DHA لاہور"
        elif lang == "roman_urdu":
            question = "Aap ka area ya city kia hai? Jaise G-13 Islamabad ya DHA Lahore."
        else:
            question = "Which area or city are you in? For example, G-13 Islamabad or DHA Lahore."
        intent_data["clarification_needed"] = True
        intent_data["clarification_question"] = question
        intent_data["location"] = None

    if service_missing and not intent_data.get("clarification_needed"):
        intent_data["clarification_needed"] = True
        intent_data["clarification_question"] = (
            "Which service do you need? (e.g. AC Technician, Plumber, Electrician)"
        )
    # ─────────────────────────────────────────────────────────────────────────

    duration_ms = int((time.time() - start) * 1000)
    intent_data["raw_input"] = user_input

    svc  = intent_data.get("service_type", "unknown")
    loc  = intent_data.get("location") or "not mentioned"
    lang = intent_data.get("language_detected", "unknown")
    conf = intent_data.get("confidence_score", 0)

    observations = (
        f"User wrote in {lang}. "
        f"Key phrases parsed from: '{user_input[:80]}'. "
        f"Urgency signals: {intent_data.get('urgency')}. "
        f"Complexity indicators: {intent_data.get('job_complexity')}."
    )
    reasoning = (
        f"Extracted service_type={svc}, location={loc}. "
        f"Time preference={intent_data.get('preferred_time')}. "
        f"Confidence {conf:.0%}. "
        + (
            f"Clarification needed: {intent_data.get('clarification_question')}"
            if intent_data.get("clarification_needed")
            else "Extraction successful — all key fields resolved."
        )
    )

    workplan = {
        "task": f"Find and book {svc} in {loc}",
        "steps": [
            f"Extract service details from {lang} input",
            f"Query {svc} providers available near {loc}",
            "Score and rank providers using distance, rating, and availability",
            "Generate transparent price quote for selected provider",
            "Execute booking and schedule follow-up notifications"
        ]
    }

    agent_trace = {
        "agent_name": "intent_extraction_agent",
        "sequence": 1,
        "observations": observations,
        "reasoning": reasoning,
        "latency_ms": duration_ms,
        "status": "success" if not intent_data.get("clarification_needed") else "needs_clarification"
    }

    return intent_data, workplan, agent_trace
