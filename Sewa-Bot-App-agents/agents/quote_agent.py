"""
QuoteAgent
==========
Generates a transparent price quote for a given provider + intent.
No Gemini call needed — purely deterministic calculation.
"""
import time


# Base price ranges per service (PKR)
BASE_PRICES = {
    "ac technician":   1500,
    "ac repair":       1500,
    "ac":              1500,
    "plumber":         800,
    "plumbing":        800,
    "electrician":     1200,
    "electrical":      1200,
    "math tutor":      2000,
    "tutor":           2000,
    "beautician":      2500,
    "beauty":          2500,
    "carpenter":       1800,
    "carpentry":       1800,
}


def _base_fee(service_type: str, provider_price: int) -> int:
    """Use provider's own price if available, else fall back to category default."""
    if provider_price > 0:
        return provider_price
    key = service_type.lower().strip()
    for k, v in BASE_PRICES.items():
        if k in key or key in k:
            return v
    return 1500  # generic fallback


def run(intent: dict, provider: dict) -> tuple[dict, str]:
    start = time.time()

    service_type   = intent.get("service_type", "Service")
    urgency        = intent.get("urgency", "normal")
    complexity     = intent.get("job_complexity", "simple")
    budget_sens    = intent.get("budget_sensitivity", "medium")
    distance_km    = float(provider.get("distance_km", 5.0))
    provider_price = int(provider.get("price_pkr", provider.get("price", 0)))
    is_verified    = provider.get("is_verified", provider.get("verified", False))

    base = _base_fee(service_type, provider_price)

    # Urgency surcharge
    urgency_map = {"urgent": 0.25, "high": 0.10, "normal": 0.0}
    urgency_rate = urgency_map.get(urgency, 0.0)
    urgency_fee  = round(base * urgency_rate)

    # Complexity adjustment
    complexity_map = {"complex": 0.20, "intermediate": 0.10, "simple": 0.0}
    complexity_rate = complexity_map.get(complexity, 0.0)
    complexity_fee  = round(base * complexity_rate)

    # Distance surcharge (PKR 30/km beyond 5km)
    distance_extra = max(0, distance_km - 5.0)
    distance_charge = round(distance_extra * 30)

    # Loyalty/verification discount
    loyalty_discount = 100 if is_verified else 0

    total = base + urgency_fee + complexity_fee + distance_charge - loyalty_discount
    total = max(total, base)  # never below base

    # Surge pricing signal
    surge_applied = urgency in ("urgent", "high")
    surge_reason  = f"{urgency.title()} demand" if surge_applied else None

    # Fairness note
    fairness_note = (
        f"Price based on {service_type} category average (PKR {base}). "
        f"{'Urgency surcharge applied due to same-day request. ' if urgency_fee else ''}"
        f"{'Verified provider discount applied. ' if loyalty_discount else ''}"
        "SewaBot ensures transparent, fair pricing with no hidden fees."
    )

    # Budget alternative
    budget_alt_price = round(base * 0.75)
    budget_alternative = {
        "available": True,
        "alternative_price_pkr": budget_alt_price,
        "how_to_achieve": "Schedule for next-day off-peak hours (8 AM – 9 AM)",
        "tradeoff": "Slightly less convenient timing but same quality provider",
    }

    duration_ms = int((time.time() - start) * 1000)

    reasoning = (
        f"Base fee PKR {base} for {service_type}. "
        f"Urgency ({urgency}): +PKR {urgency_fee}. "
        f"Complexity ({complexity}): +PKR {complexity_fee}. "
        f"Distance {distance_km}km: +PKR {distance_charge}. "
        f"Verified discount: -PKR {loyalty_discount}. "
        f"Total: PKR {total}."
    )

    quote = {
        "base_fee":           base,
        "urgency_fee":        urgency_fee,
        "urgency_surcharge":  urgency_fee,   # alias for Flutter compat
        "complexity_fee":     complexity_fee,
        "complexity_charge":  complexity_fee, # alias
        "distance_charge":    distance_charge,
        "loyalty_discount":   loyalty_discount,
        "surge_applied":      surge_applied,
        "surge_reason":       surge_reason,
        "total_quoted_pkr":   total,
        "currency":           "PKR",
        "price_breakdown_text": f"PKR {base} base + adjustments = PKR {total} total",
        "fairness_note":      fairness_note,
    }

    output = {
        "quote":              quote,
        "budget_alternative": budget_alternative,
        "duration_ms":        duration_ms,
    }

    return output, reasoning
