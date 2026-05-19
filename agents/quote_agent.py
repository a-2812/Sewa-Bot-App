import time

# Base fee by service type (PKR) — fallback if provider.price not available
SERVICE_BASE_FEES = {
    "AC Technician": 800,
    "Plumber": 600,
    "Electrician": 700,
    "Math Tutor": 500,
    "Beautician": 1000,
    "Carpenter": 900,
}

COMPLEXITY_MULTIPLIERS = {
    "simple": 0.0,
    "intermediate": 0.25,
    "complex": 0.45,
}

URGENCY_MULTIPLIERS = {
    "normal": 0.0,
    "high": 0.30,
    "urgent": 0.50,
}


def run(intent: dict, provider: dict) -> tuple[dict, str]:
    start = time.time()

    service_type = provider.get("provider_name", intent.get("service_type", "Service"))
    base_fee = provider.get("price_pkr") or provider.get("price") or SERVICE_BASE_FEES.get(
        intent.get("service_type", ""), 700
    )

    complexity = intent.get("job_complexity", "simple")
    urgency = intent.get("urgency", "normal")
    budget_sensitivity = intent.get("budget_sensitivity", "medium")

    complexity_pct = COMPLEXITY_MULTIPLIERS.get(complexity, 0)
    urgency_pct = URGENCY_MULTIPLIERS.get(urgency, 0)

    complexity_charge = round(base_fee * complexity_pct)
    urgency_surcharge = round(base_fee * urgency_pct)
    total = base_fee + complexity_charge + urgency_surcharge

    # Budget alternative: show non-urgent price if urgency surcharge applies
    budget_alt = None
    if urgency_surcharge > 0:
        alt_price = base_fee + complexity_charge
        budget_alt = {
            "available": True,
            "alternative_price_pkr": alt_price,
            "how_to_achieve": "Book for a non-urgent slot (tomorrow) to remove urgency surcharge",
            "tradeoff": f"Wait a few more hours — save PKR {total - alt_price}"
        }
    else:
        budget_alt = {"available": False}

    breakdown_parts = [f"Base {base_fee} PKR"]
    if complexity_charge:
        breakdown_parts.append(f"Complexity (+{complexity_pct:.0%}): +{complexity_charge}")
    if urgency_surcharge:
        breakdown_parts.append(f"Urgency (+{urgency_pct:.0%}): +{urgency_surcharge}")
    breakdown_parts.append(f"Total: {total} PKR")

    duration_ms = int((time.time() - start) * 1000)

    observations = (
        f"Service: {service_type}. Complexity: {complexity}. Urgency: {urgency}. "
        f"Base fee: {base_fee} PKR."
    )
    reasoning = (
        f"Applied {complexity_pct:.0%} complexity charge (+{complexity_charge} PKR) "
        f"and {urgency_pct:.0%} urgency surcharge (+{urgency_surcharge} PKR). "
        f"Total: {total} PKR."
    )

    quote = {
        "base_fee": base_fee,
        "complexity_charge": complexity_charge,
        "urgency_surcharge": urgency_surcharge,
        "total_quoted_pkr": total,
        "price_breakdown_text": " + ".join(breakdown_parts),
        "fairness_note": (
            f"Provider earns fair rate for {complexity} work. "
            f"{'No surcharges apply.' if total == base_fee else f'Charges reflect {complexity} complexity and {urgency} urgency.'}"
        ),
        "surge_applied": False,
        "surge_reason": None,
        "distance_charge": 0,
        "loyalty_discount": 0,
    }

    agent_trace = {
        "agent_name": "pricing_agent",
        "sequence": 3,
        "observations": observations,
        "reasoning": reasoning,
        "calculation_steps": breakdown_parts,
        "latency_ms": duration_ms,
        "status": "success"
    }

    output = {
        "quote": quote,
        "budget_alternative": budget_alt,
        "agent_trace": agent_trace
    }

    return output, reasoning
