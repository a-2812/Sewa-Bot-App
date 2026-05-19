import time
import json
import google.generativeai as genai
from config import GEMINI_API_KEY

genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel("gemini-2.5-flash")

WHY_CHOSEN_PROMPT = """
Write 1-2 sentences explaining why this provider is the top choice for a {service} request.
Be specific: mention distance ({distance_km}km), rating ({rating}/5), verification status, and score ({score}/100).
Keep it simple — write for a non-technical user. English only.

Return ONLY the explanation, no extra text.
"""

WHY_OVER_RANK_2_PROMPT = """
Rank 1: {rank1_name} — score {rank1_score}/100, {rank1_km}km away, rating {rank1_rating}/5, {rank1_verified}
Rank 2: {rank2_name} — score {rank2_score}/100, {rank2_km}km away, rating {rank2_rating}/5, {rank2_verified}

Write 1 sentence explaining why Rank 1 beats Rank 2. Be specific with numbers.
Return ONLY the sentence.
"""


def _score(provider: dict) -> dict:
    distance_km = provider.get("distance_km", 999)
    rating = provider.get("rating", 3.0)
    verified = provider.get("verified", False)

    # Weights aligned with Saad's backend: Distance 40%, Rating 35%, Availability 15%, Verified 10%
    # Since providers.json has no slot data, we use verified as availability proxy
    distance_score = round(max(0, 40 - (distance_km * 4)), 1)
    rating_score = round((rating / 5.0) * 35, 1)
    availability_score = 15.0  # All providers assumed available
    verification_score = round((rating / 5.0) * 10, 1)  # Verified weight from rating quality

    if verified:
        verification_score = 10.0
    else:
        verification_score = min(verification_score, 5.0)

    total = round(distance_score + rating_score + availability_score + verification_score, 1)

    return {
        "total_score": total,
        "score_breakdown": {
            "distance_score": distance_score,
            "rating_score": rating_score,
            "availability_score": availability_score,
            "verification_score": verification_score,
        }
    }


def _price_tier(price: int) -> str:
    if price <= 1000:
        return "budget"
    if price <= 2000:
        return "medium"
    return "premium"


def run(providers: list, service_type: str) -> tuple[dict, str]:
    start = time.time()

    scored = []
    for p in providers:
        s = _score(p)
        scored.append({
            "rank": 0,
            "provider_id": p.get("id", ""),
            "provider_name": p.get("name", ""),
            "area": p.get("location", {}).get("area", ""),
            "city": p.get("location", {}).get("city", ""),
            "distance_km": p.get("distance_km", 999),
            "rating": p.get("rating", 0),
            "price_pkr": p.get("price", 0),
            "price_tier": _price_tier(p.get("price", 0)),
            "is_verified": p.get("verified", False),
            "phone": p.get("phone", ""),
            "total_score": s["total_score"],
            "score_breakdown": s["score_breakdown"],
            "why_chosen": "",
            "why_over_rank_2": None,
            "agent_trace": None,
        })

    scored.sort(key=lambda x: x["total_score"], reverse=True)
    for i, item in enumerate(scored):
        item["rank"] = i + 1

    top = scored[0] if scored else None

    # Generate Gemini explanations for top 2
    if top:
        try:
            prompt = WHY_CHOSEN_PROMPT.format(
                service=service_type,
                distance_km=top["distance_km"],
                rating=top["rating"],
                score=top["total_score"]
            )
            top["why_chosen"] = model.generate_content(prompt).text.strip()
        except Exception:
            top["why_chosen"] = (
                f"Top choice with {top['rating']}/5 rating, "
                f"{top['distance_km']}km away, score {top['total_score']}/100."
            )

        if len(scored) >= 2:
            r2 = scored[1]
            try:
                prompt2 = WHY_OVER_RANK_2_PROMPT.format(
                    rank1_name=top["provider_name"],
                    rank1_score=top["total_score"],
                    rank1_km=top["distance_km"],
                    rank1_rating=top["rating"],
                    rank1_verified="verified" if top["is_verified"] else "unverified",
                    rank2_name=r2["provider_name"],
                    rank2_score=r2["total_score"],
                    rank2_km=r2["distance_km"],
                    rank2_rating=r2["rating"],
                    rank2_verified="verified" if r2["is_verified"] else "unverified",
                )
                top["why_over_rank_2"] = model.generate_content(prompt2).text.strip()
            except Exception:
                top["why_over_rank_2"] = (
                    f"{top['provider_name']} scores {top['total_score']} vs "
                    f"{r2['provider_name']}'s {r2['total_score']} — "
                    f"better rating and proximity."
                )

    # Add agent_trace to top provider only
    duration_ms = int((time.time() - start) * 1000)
    if top:
        top["agent_trace"] = {
            "agent_name": "provider_matching_agent",
            "sequence": 2,
            "observations": {
                "total_providers_found": len(scored),
                "scoring_weights": {"distance": "40%", "rating": "35%", "availability": "15%", "verified": "10%"},
                "top_provider": top["provider_name"],
                "top_score": top["total_score"]
            },
            "reasoning": (
                f"Scored {len(scored)} providers for '{service_type}'. "
                f"Top: {top['provider_name']} — {top['distance_km']}km, "
                f"rated {top['rating']}/5, score {top['total_score']}/100."
            ),
            "latency_ms": duration_ms,
            "status": "success"
        }

    reasoning = (
        f"Ranked {len(scored)} providers. "
        f"Top: {top['provider_name']} scored {top['total_score']}/100 — "
        f"distance={top['score_breakdown']['distance_score']}pts, "
        f"rating={top['score_breakdown']['rating_score']}pts, "
        f"availability={top['score_breakdown']['availability_score']}pts, "
        f"verified={top['score_breakdown']['verification_score']}pts."
        if top else "No providers to rank."
    )

    output = {
        "ranked_providers": scored[:5],
        "top_pick": top,
        "total_ranked": len(scored),
        "duration_ms": duration_ms
    }

    return output, reasoning
