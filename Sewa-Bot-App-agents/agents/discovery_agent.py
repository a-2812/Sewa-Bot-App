import json
import math
import time
import os

try:
    import requests as _requests
except ImportError:
    _requests = None

from config import BACKEND_BASE_URL

# Map user-friendly service names to canonical service_type field in providers.json
SERVICE_ALIASES = {
    "ac repair": "AC Technician",
    "ac repair service": "AC Technician",
    "ac repair services": "AC Technician",
    "ac service": "AC Technician",
    "ac services": "AC Technician",
    "ac repairing": "AC Technician",
    "repair ac": "AC Technician",
    "ac": "AC Technician",
    "air conditioning": "AC Technician",
    "air conditioner": "AC Technician",
    "air conditioner repair": "AC Technician",
    "air conditioner service": "AC Technician",
    "cooling": "AC Technician",
    "ac technician": "AC Technician",
    "ac_technician": "AC Technician",
    "plumber": "Plumber",
    "plumber service": "Plumber",
    "plumbing service": "Plumber",
    "plumbing services": "Plumber",
    "plumbing": "Plumber",
    "water": "Plumber",
    "pipe": "Plumber",
    "leak": "Plumber",
    "electrician": "Electrician",
    "electrician service": "Electrician",
    "electrical service": "Electrician",
    "electrical services": "Electrician",
    "electrical": "Electrician",
    "electric": "Electrician",
    "wiring": "Electrician",
    "lights": "Electrician",
    "tutor": "Math Tutor",
    "math tutor": "Math Tutor",
    "teacher": "Math Tutor",
    "math": "Math Tutor",
    "mathematics": "Math Tutor",
    "education": "Math Tutor",
    "study": "Math Tutor",
    "beautician": "Beautician",
    "beauty": "Beautician",
    "salon": "Beautician",
    "makeup": "Beautician",
    "hair": "Beautician",
    "carpenter": "Carpenter",
    "carpentry": "Carpenter",
    "wood": "Carpenter",
    "furniture": "Carpenter",
}

# Area name → coordinates for distance calculation
LOCATION_COORDS = {
    "g-13": {"lat": 33.6844, "lng": 73.0479},
    "g-12": {"lat": 33.6900, "lng": 73.0400},
    "g-11": {"lat": 33.6950, "lng": 73.0580},
    "g-10": {"lat": 33.6893, "lng": 73.0690},
    "g-9":  {"lat": 33.7000, "lng": 73.0700},
    "f-10": {"lat": 33.7067, "lng": 73.0479},
    "f-11": {"lat": 33.7167, "lng": 73.0290},
    "f-7":  {"lat": 33.7215, "lng": 73.0587},
    "f-8":  {"lat": 33.7100, "lng": 73.0650},
    "f-6":  {"lat": 33.7256, "lng": 73.0798},
    "i-8":  {"lat": 33.6400, "lng": 73.1000},
    "i-9":  {"lat": 33.6545, "lng": 73.0728},
    "i-10": {"lat": 33.6440, "lng": 73.0700},
    "e-11": {"lat": 33.7400, "lng": 73.0100},
    "e-7":  {"lat": 33.7347, "lng": 73.0467},
    "g-8":  {"lat": 33.6990, "lng": 73.0562},
    "g-6":  {"lat": 33.7262, "lng": 73.0698},
    "islamabad": {"lat": 33.6844, "lng": 73.0479},
    "blue area": {"lat": 33.7115, "lng": 73.0600},
    "f-7 markaz": {"lat": 33.7215, "lng": 73.0576},
    "dha lahore": {"lat": 31.4817, "lng": 74.4020},
    "dha": {"lat": 31.4817, "lng": 74.4020},
    "gulberg": {"lat": 31.5120, "lng": 74.3587},
    "lahore": {"lat": 31.5204, "lng": 74.3587},
    "johar town": {"lat": 31.4697, "lng": 74.2728},
    "model town": {"lat": 31.4991, "lng": 74.3319},
}


def _normalize_service(raw: str) -> str:
    key = raw.lower().strip()
    if key in SERVICE_ALIASES:
        return SERVICE_ALIASES[key]
    for alias, canonical in SERVICE_ALIASES.items():
        if alias in key or key in alias:
            return canonical
    return raw.title()


def _haversine_km(lat1, lon1, lat2, lon2) -> float:
    R = 6371
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2) ** 2
    return round(2 * R * math.atan2(math.sqrt(a), math.sqrt(1 - a)), 2)


def _resolve_coords(location: str) -> dict | None:
    if not location:
        return None
    key = location.lower().strip()
    for k, v in LOCATION_COORDS.items():
        if k in key or key in k:
            return v
    return None


def _load_providers_local() -> list:
    """Fallback: load providers.json from the backend data directory."""
    candidates = [
        os.path.join(os.path.dirname(__file__), "..", "..", "Sewa-Bot-App-backend", "data", "providers.json"),
        os.path.join(os.path.dirname(__file__), "..", "data", "providers.json"),
        os.path.join(os.path.dirname(__file__), "data", "providers.json"),
    ]
    for path in candidates:
        norm = os.path.normpath(path)
        if os.path.exists(norm):
            with open(norm, "r", encoding="utf-8") as f:
                return json.load(f)
    return []


def run(service_type: str, location: str, radius_km: float = 50) -> tuple[dict, str]:
    start = time.time()

    canonical_service = _normalize_service(service_type)
    coords = _resolve_coords(location)

    providers = []
    source = "local"

    # ── Try backend API first ──────────────────────────────────
    if _requests and coords:
        try:
            resp = _requests.post(
                f"{BACKEND_BASE_URL}/search",
                json={
                    "service_type": canonical_service,
                    "user_lat": coords["lat"],
                    "user_lon": coords["lng"],
                    "location": location,
                    "radius_km": radius_km,
                },
                timeout=10,
            )
            if resp.status_code == 200:
                data = resp.json()
                providers = data.get("providers", [])
                source = "backend_api"
            elif resp.status_code == 404:
                providers = []
                source = "backend_api_empty"
        except Exception:
            pass  # Fall through to local

    # ── Fallback: local providers.json ────────────────────────
    if not providers and source == "local":
        all_providers = _load_providers_local()
        matched = [p for p in all_providers if p.get("service_type") == canonical_service]
        for p in matched:
            loc = p.get("location", {})
            if coords:
                p["distance_km"] = _haversine_km(coords["lat"], coords["lng"],
                                                  loc.get("lat", 0), loc.get("lng", 0))
            else:
                p["distance_km"] = 999
        nearby = [p for p in matched if p["distance_km"] <= radius_km]
        if not nearby and matched:
            nearby = sorted(matched, key=lambda x: x["distance_km"])[:5]
        nearby.sort(key=lambda x: x["distance_km"])
        providers = nearby

    # ── Ensure distance_km is present ─────────────────────────
    if coords:
        for p in providers:
            if "distance_km" not in p:
                loc = p.get("location", {})
                p["distance_km"] = _haversine_km(coords["lat"], coords["lng"],
                                                  loc.get("lat", 0), loc.get("lng", 0))

    duration_ms = int((time.time() - start) * 1000)

    reasoning = (
        f"Searched for '{canonical_service}' (normalized from '{service_type}'). "
        f"Source: {source}. "
        f"Resolved '{location}' → coords {coords}. "
        f"Found {len(providers)} providers within {radius_km}km radius."
    )

    output = {
        "canonical_service": canonical_service,
        "total_found": len(providers),
        "providers": providers,
        "search_radius_km": radius_km,
        "duration_ms": duration_ms,
    }

    return output, reasoning
