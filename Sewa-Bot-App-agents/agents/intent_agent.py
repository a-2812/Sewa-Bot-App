import json
import time
import re
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

# ── Service keyword map — mirrors discovery_agent.SERVICE_ALIASES ────────────
SERVICE_KEYWORDS = {
    "ac":              "AC Technician",
    "ac repair":       "AC Technician",
    "ac technician":   "AC Technician",
    "ac service":      "AC Technician",
    "ac fix":          "AC Technician",
    "air conditioning":"AC Technician",
    "air conditioner": "AC Technician",
    "cooling":         "AC Technician",
    "plumber":         "Plumber",
    "plumbing":        "Plumber",
    "water":           "Plumber",
    "pipe":            "Plumber",
    "leak":            "Plumber",
    "nalkay":          "Plumber",
    "pani":            "Plumber",
    "electrician":     "Electrician",
    "electrical":      "Electrician",
    "electric":        "Electrician",
    "wiring":          "Electrician",
    "lights":          "Electrician",
    "bijli":           "Electrician",
    "tutor":           "Math Tutor",
    "math tutor":      "Math Tutor",
    "teacher":         "Math Tutor",
    "math":            "Math Tutor",
    "mathematics":     "Math Tutor",
    "education":       "Math Tutor",
    "study":           "Math Tutor",
    "padhai":          "Math Tutor",
    "beautician":      "Beautician",
    "beauty":          "Beautician",
    "salon":           "Beautician",
    "makeup":          "Beautician",
    "hair":            "Beautician",
    "parlour":         "Beautician",
    "parlor":          "Beautician",
    "carpenter":       "Carpenter",
    "carpentry":       "Carpenter",
    "wood":            "Carpenter",
    "furniture":       "Carpenter",
    "lakri":           "Carpenter",
}


def _is_empty(val) -> bool:
    """Check if a value is effectively empty/null/unknown."""
    if val is None:
        return True
    s = str(val).strip().lower()
    return s in ("", "null", "none", "not mentioned", "unknown", "not_specified")


def _extract_service_from_text(text: str):
    """Heuristic: extract service_type from user text using keyword matching."""
    if not text:
        return None
    t = text.lower().strip()

    # Try multi-word matches first (longer keys first for greedy match)
    sorted_keywords = sorted(SERVICE_KEYWORDS.keys(), key=len, reverse=True)
    for keyword in sorted_keywords:
        # Use word-boundary matching to avoid false positives
        pattern = r'\b' + re.escape(keyword) + r'\b'
        if re.search(pattern, t):
            return SERVICE_KEYWORDS[keyword]

    return None


def _extract_location_from_text(text: str):
    """Heuristic: extract location from user text using area/city patterns."""
    if not text:
        return None
    t = (text or "").lower()

    # Normalize common area shorthand like 'g13' -> 'g-13'
    t_norm = re.sub(r"\bg\s*[-\s]?\s*(\d{1,2})\b", r"g-\1", t, flags=re.IGNORECASE)
    t_norm = re.sub(r"\bf\s*[-\s]?\s*(\d{1,2})\b", r"f-\1", t_norm, flags=re.IGNORECASE)
    t_norm = re.sub(r"\bi\s*[-\s]?\s*(\d{1,2})\b", r"i-\1", t_norm, flags=re.IGNORECASE)
    t_norm = re.sub(r"\be\s*[-\s]?\s*(\d{1,2})\b", r"e-\1", t_norm, flags=re.IGNORECASE)

    # Look for area patterns and city names
    area_match = re.search(
        r"\b([gfie]-\d{1,2}|dha|gulberg|bahria\s*town|cantt|model\s*town|johar\s*town|blue\s*area|saddar|clifton|defence|sector\s*\d+)\b",
        t_norm, flags=re.IGNORECASE
    )
    cities = [
        "islamabad", "lahore", "karachi", "rawalpindi", "peshawar",
        "multan", "faisalabad", "quetta", "sialkot", "gujranwala",
        "hyderabad", "abbottabad", "mardan",
    ]
    city_found = None
    for c in cities:
        if re.search(r"\b" + re.escape(c) + r"\b", t_norm):
            city_found = c.title()
            break

    if area_match and city_found:
        area = area_match.group(0).upper()
        return f"{area}, {city_found}"
    if city_found:
        return city_found
    if area_match:
        return area_match.group(0).upper()
    return None


def run(user_input: str, context: str = "", previous_intent: dict = None) -> tuple[dict, str, dict]:
    start = time.time()

    prompt = INTENT_PROMPT.format(user_input=user_input, context=context or "None")

    intent_data = None
    gemini_error = None

    # ── Try Gemini with 1 retry ───────────────────────────────────────────────
    for attempt in range(2):
        try:
            response = model.generate_content(prompt)
            raw = response.text.strip()
            if raw.startswith("```"):
                lines = raw.split("\n")
                raw = "\n".join(lines[1:-1])
            intent_data = json.loads(raw)
            gemini_error = None
            break  # Success
        except Exception as e:
            gemini_error = e
            if attempt == 0:
                time.sleep(0.5)  # Brief pause before retry
                continue

    # ── If Gemini failed both attempts, build intent from heuristics ──────────
    if intent_data is None:
        print(f"\n[INTENT AGENT ERROR]: Gemini API failed after 2 attempts: {gemini_error}\n")

        # Try to extract what we can from the user's text directly
        heuristic_service = _extract_service_from_text(user_input)
        heuristic_location = _extract_location_from_text(user_input)

        intent_data = {
            "service_type": heuristic_service or "unknown",
            "location": heuristic_location,
            "preferred_time": "not_specified",
            "urgency": "normal",
            "budget_sensitivity": "medium",
            "job_complexity": "simple",
            "language_detected": "mixed",
            "confidence_score": 0.5 if (heuristic_service or heuristic_location) else 0.2,
            "clarification_needed": False,  # Will be re-evaluated below
            "clarification_question": None,
        }

    # ── Merge with previous intent (multi-turn conversation) ─────────────────
    if previous_intent and isinstance(previous_intent, dict):
        for field in ["service_type", "location", "preferred_time", "urgency",
                       "budget_sensitivity", "job_complexity", "language_detected"]:
            current_val = intent_data.get(field)
            prev_val = previous_intent.get(field)
            if _is_empty(current_val) and not _is_empty(prev_val):
                intent_data[field] = prev_val

    # ── Post-parse: validate & patch missing fields ──────────────────────────
    location = intent_data.get("location")
    service  = intent_data.get("service_type", "unknown")

    location_missing = _is_empty(location)
    service_missing  = _is_empty(service)

    # Try heuristic extraction if fields are still missing
    if location_missing:
        fallback_loc = _extract_location_from_text(user_input)
        if fallback_loc:
            intent_data["location"] = fallback_loc
            location_missing = False

    if service_missing:
        fallback_svc = _extract_service_from_text(user_input)
        if fallback_svc:
            intent_data["service_type"] = fallback_svc
            service_missing = False

    # Re-read after patching
    location_missing = _is_empty(intent_data.get("location"))
    service_missing  = _is_empty(intent_data.get("service_type"))

    # ── Determine if clarification is actually needed ────────────────────────
    lang = intent_data.get("language_detected", "mixed")

    if location_missing and service_missing:
        # Both missing — ask for both
        intent_data["clarification_needed"] = True
        if lang == "urdu":
            intent_data["clarification_question"] = "آپ کو کیا سروس چاہیے اور آپ کا علاقہ کیا ہے؟ مثلاً AC ٹیکنیشن G-13 اسلام آباد"
        elif lang == "roman_urdu":
            intent_data["clarification_question"] = "Aap ko kya service chahiye aur aap ka area kya hai? Jaise AC Technician G-13 Islamabad"
        else:
            intent_data["clarification_question"] = "What service do you need and which area are you in? For example: AC Technician in G-13, Islamabad"
    elif service_missing:
        # Only service missing
        intent_data["clarification_needed"] = True
        if lang == "urdu":
            intent_data["clarification_question"] = "آپ کو کون سی سروس چاہیے؟ مثلاً AC ٹیکنیشن، پلمبر، الیکٹریشن"
        elif lang == "roman_urdu":
            intent_data["clarification_question"] = "Aap ko konsi service chahiye? Jaise AC Technician, Plumber, Electrician"
        else:
            intent_data["clarification_question"] = "Which service do you need? (e.g. AC Technician, Plumber, Electrician)"
    elif location_missing:
        # Only location missing
        intent_data["clarification_needed"] = True
        if lang == "urdu":
            intent_data["clarification_question"] = "آپ کا علاقہ یا شہر کیا ہے؟ مثلاً G-13 اسلام آباد یا DHA لاہور"
        elif lang == "roman_urdu":
            intent_data["clarification_question"] = "Aap ka area ya city kia hai? Jaise G-13 Islamabad ya DHA Lahore."
        else:
            intent_data["clarification_question"] = "Which area or city are you in? For example, G-13 Islamabad or DHA Lahore."
    else:
        # Both resolved — no clarification needed!
        intent_data["clarification_needed"] = False
        intent_data["clarification_question"] = None

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
        + (f" [Gemini failed, used heuristics]" if gemini_error else "")
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
