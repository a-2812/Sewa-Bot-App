import time
import json
import google.generativeai as genai
from config import GEMINI_API_KEY

genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel("gemini-2.5-flash")

WHY_CHOSEN_PROMPT = """
Write 1-2 sentences explaining why this provider is the top choice for a {service} request.
Be specific: mention distance ({distance_km}km), rating ({rating}/5), verification status, slot availability ({slot}), and score ({score}/100).
Keep it simple — write for a non-technical user. English only.

Return ONLY the explanation, no extra text.
"""


def _time_slot_matches(available_slots: list, time_preference: str) -> bool:
    morning_slots = ["07:00", "08:00", "09:00", "10:00", "11:00", "12:00"]
    afternoon_slots = ["12:00", "13:00", "14:00", "15:00", "16:00"]
    evening_slots = ["17:00", "18:00", "19:00", "20:00"]
    
    slot_map = {
        "today_morning": morning_slots,
        "tomorrow_morning": morning_slots,
        "today_afternoon": afternoon_slots,
        "tomorrow_afternoon": afternoon_slots,
        "today_evening": evening_slots,
        "tomorrow_evening": evening_slots,
        "urgent": available_slots,
        "not_specified": available_slots
    }
    
    target_slots = slot_map.get(time_preference, available_slots)
    if not available_slots:
        # Mock slots if none exist in provider data
        available_slots = ["09:00", "10:00", "14:00"]
    return any(slot in available_slots for slot in target_slots)


def _score(provider: dict, time_preference: str) -> dict:
    distance_km = provider.get("distance_km", 999)
    rating = provider.get("rating", 3.0)
    verified = provider.get("verified", False)
    slots = provider.get("available_slots", ["09:00", "10:00", "14:00"])

    # Score out of 40 max
    distance_score = round(max(0, 40 - (distance_km * 4)), 1)
    
    # Score out of 35 max
    rating_score = round((rating / 5.0) * 35, 1)
    
    # Score out of 25 max
    if _time_slot_matches(slots, time_preference):
        availability_score = 25.0
    else:
        availability_score = 8.0
        
    verification_bonus = 2.0 if verified else 0.0

    total = round(distance_score + rating_score + availability_score + verification_bonus, 1)

    return {
        "total_score": total,
        "score_breakdown": {
            "distance_score": distance_score,
            "rating_score": rating_score,
            "availability_score": availability_score,
            "verification_bonus": verification_bonus,
        }
    }


def run(providers: list, service_type: str, time_preference: str) -> tuple[dict, str]:
    start = time.time()

    scored = []
    for p in providers:
        s = _score(p, time_preference)
        scored.append({
            "rank": 0,
            "provider_id": p.get("id", ""),
            "provider_name": p.get("name", ""),
            "distance_km": p.get("distance_km", 999),
            "rating": p.get("rating", 0),
            "is_verified": p.get("verified", False),
            "total_score": s["total_score"],
            "score_breakdown": s["score_breakdown"],
            "matched_slot": "10:00 AM", # Hardcode mock for now based on availability
            "why_chosen": ""
        })

    scored.sort(key=lambda x: x["total_score"], reverse=True)
    for i, item in enumerate(scored):
        item["rank"] = i + 1

    top = scored[0] if scored else None

    # Generate Gemini explanations for top
    if top:
        try:
            prompt = WHY_CHOSEN_PROMPT.format(
                service=service_type,
                distance_km=top["distance_km"],
                rating=top["rating"],
                slot=top["matched_slot"],
                score=top["total_score"]
            )
            top["why_chosen"] = model.generate_content(prompt).text.strip()
        except Exception:
            top["why_chosen"] = (
                f"{top['provider_name']} was selected as the top provider because it is "
                f"{top['distance_km']}km away, holds a rating of {top['rating']}/5, "
                f"and has an open slot at {top['matched_slot']} which matches your preference."
            )

    duration_ms = int((time.time() - start) * 1000)

    reasoning = (
        f"Scored {len(scored)} providers using weighted formula: distance(40%) + rating(35%) + availability(25%). "
        f"{top['provider_name']} scored {top['total_score']}/100: "
        f"distance_score={top['score_breakdown']['distance_score']} ({top['distance_km']}km away), "
        f"rating_score={top['score_breakdown']['rating_score']} ({top['rating']} stars), "
        f"availability_score={top['score_breakdown']['availability_score']}. Selected as top pick."
        if top else "No providers to rank."
    )

    output = {
        "ranked_providers": scored[:5],
        "top_pick": top,
        "total_ranked": len(scored),
        "duration_ms": duration_ms
    }

    return output, reasoning
