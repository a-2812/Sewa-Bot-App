"""
SewaBot Backend — AI Service Orchestrator for Pakistan's Informal Economy
=========================================================================
FastAPI application with provider discovery, proximity search, weighted
ranking, and persistent booking management.

Run with:
    python main.py
or:
    uvicorn main:app --reload --port 8000
"""

from __future__ import annotations

import asyncio
import json
import math
import uuid
import time
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Optional

import uvicorn
from fastapi import FastAPI, HTTPException, Query, Request, Path as FastApiPath
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse, JSONResponse
from pydantic import BaseModel, Field

from firebase_config import get_firestore_client

# ---------------------------------------------------------------------------
# App bootstrap
# ---------------------------------------------------------------------------

app = FastAPI(
    title="SewaBot API",
    description=(
        "AI-powered service orchestrator connecting customers with trusted "
        "informal-economy service providers across Pakistan."
    ),
    version="2.0.0",
    contact={"name": "SewaBot Team", "email": "hello@sewabot.pk"},
    license_info={"name": "MIT"},
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ---------------------------------------------------------------------------
# Middlewares & Exception Handlers
# ---------------------------------------------------------------------------

RATE_LIMIT_DURATION = 60
MAX_REQUESTS_PER_MINUTE = 100  # Agents hit this multiple times per user request
_ip_requests = defaultdict(list)

@app.middleware("http")
async def response_time_logging_middleware(request: Request, call_next):
    start_time = time.time()
    response = await call_next(request)
    process_time = time.time() - start_time
    print(f"[{datetime.now(timezone.utc).isoformat()}] {request.method} {request.url.path} responded in {process_time:.4f}s (status: {response.status_code})")
    response.headers["X-Process-Time"] = f"{process_time:.4f}s"
    return response


@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    client_ip = request.client.host if request.client else "127.0.0.1"
    now = time.time()
    
    # Clean up old requests
    _ip_requests[client_ip] = [t for t in _ip_requests[client_ip] if now - t < RATE_LIMIT_DURATION]
    
    if len(_ip_requests[client_ip]) >= MAX_REQUESTS_PER_MINUTE:
        return JSONResponse(
            status_code=429,
            content={"detail": "Too Many Requests. Please try again later."}
        )
        
    _ip_requests[client_ip].append(now)
    return await call_next(request)


@app.middleware("http")
async def timeout_middleware(request: Request, call_next):
    try:
        return await asyncio.wait_for(call_next(request), timeout=30.0)  # Gemini calls need up to 10s
    except asyncio.TimeoutError:
        return JSONResponse(
            status_code=504,
            content={"detail": "Gateway Timeout. The request took too long to process."}
        )


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    # Pass through standard HTTPExceptions
    if isinstance(exc, HTTPException):
        return JSONResponse(status_code=exc.status_code, content={"detail": exc.detail})
        
    print(f"Unhandled exception: {exc}")
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal Server Error. Please contact support."}
    )

# ---------------------------------------------------------------------------
# Paths — both files live next to main.py
# ---------------------------------------------------------------------------

_BASE = Path(__file__).parent
PROVIDERS_FILE = _BASE / "data" / "providers.json"
BOOKINGS_FILE  = _BASE / "data" / "bookings.json"

# ---------------------------------------------------------------------------
# Data-layer helpers
# ---------------------------------------------------------------------------


_cached_providers: Optional[list[dict[str, Any]]] = None
_cached_providers_timestamp: float = 0.0
PROVIDER_CACHE_TTL: float = 300.0  # 5 minutes

CANONICAL_SERVICES = {
    "AC Technician": ["ac", "air conditioner", "ac repair", "ac technician", "ac service", "ac wala", "ac thik", "ac repair wala", "cooling", "ref"],
    "Plumber": ["plumber", "plumbing", "pipe", "leak", "tap", "leakage", "urgent plumber", "plumber chahiye", " नल "],
    "Electrician": ["electrician", "bijli", "electricity", "fan repair", "short circuit", "board repair", "ups", "wiring"],
    "Math Tutor": ["math", "maths", "tutor", "teacher", "math tutor", "maths tutor", "tuition", "study", "academy", "math teacher"],
    "Beautician": ["beautician", "makeup", "beauty", "parlor", "salon", "facial", "threading", "hairdresser"],
    "Carpenter": ["carpenter", "wood", "furniture", "door repair", "cabinet", "sofa repair", "woodwork"]
}

def normalize_service_type(query: str) -> str:
    if not query:
        return ""
    q = query.lower().strip()
    
    # 1. Check exact/close match first
    for canonical, keywords in CANONICAL_SERVICES.items():
        if q == canonical.lower():
            return canonical
        for kw in keywords:
            if q == kw.lower():
                return canonical
                
    # 2. Check substring match
    matches = []
    for canonical, keywords in CANONICAL_SERVICES.items():
        for kw in keywords:
            if kw.lower() in q:
                matches.append((len(kw), canonical))
    if matches:
        matches.sort(reverse=True, key=lambda x: x[0])
        return matches[0][1]
        
    # 3. Check word-by-word
    words = q.split()
    for word in words:
        for canonical, keywords in CANONICAL_SERVICES.items():
            for kw in keywords:
                if word == kw.lower():
                    return canonical
                    
    return query.title()

def _load_providers() -> list[dict[str, Any]]:
    """Load and normalise provider records from providers.json with in-memory caching.

    Field mapping (new schema → internal):
        service_type → service
        price        → price_pkr
        verified     → verified  (also used in ranking)
    """
    global _cached_providers, _cached_providers_timestamp
    now = time.time()
    
    if _cached_providers is not None and (now - _cached_providers_timestamp) < PROVIDER_CACHE_TTL:
        return _cached_providers

    if not PROVIDERS_FILE.exists():
        raise HTTPException(
            status_code=503,
            detail="Provider data store is unavailable.",
        )
    try:
        raw: list[dict[str, Any]] = json.loads(PROVIDERS_FILE.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=503, detail=f"Provider data malformed: {exc}")

    normalised: list[dict[str, Any]] = []
    for p in raw:
        loc = p.get("location", {})
        normalised.append({
            **p,
            # Canonical service key used throughout the app
            "service":          p.get("service_type", p.get("service", "")),
            # Canonical price key (PKR per visit)
            "price_pkr":        p.get("price", p.get("price_pkr", 0)),
            # verified stays as-is; True = can accept bookings
            "verified":         p.get("verified", True),
            # Availability alias (True unless explicitly False)
            "available":        p.get("verified", p.get("available", True)),
            # Extra fields needed by Flutter provider cards
            "area":             p.get("area", loc.get("area", "")),
            "experience_years": p.get("experience_years", 1),
            "review_count":     p.get("review_count", 0),
            "on_time_score":    p.get("on_time_score", 0.8),
            "price_tier":       p.get("price_tier", "Mid"),
            "available_slots":  p.get("available_slots", ["09:00", "10:00", "14:00"]),
        })
    
    _cached_providers = normalised
    _cached_providers_timestamp = now
    return normalised


def _load_bookings() -> dict[str, Any]:
    """Return the bookings dict from Firestore, falling back to local JSON."""
    try:
        db = get_firestore_client()
        if db:
            docs = db.collection('bookings').stream()
            return {doc.id: doc.to_dict() for doc in docs}
    except Exception as e:
        print(f"[backend] Firestore read failed: {e} — falling back to local JSON")

    # Local JSON fallback
    if BOOKINGS_FILE.exists():
        try:
            raw = json.loads(BOOKINGS_FILE.read_text(encoding="utf-8"))
            if isinstance(raw, list):
                return {b.get("booking_id", str(i)): b for i, b in enumerate(raw)}
            return raw
        except json.JSONDecodeError:
            pass
    return {}


def _save_booking(booking_id: str, record: dict[str, Any]) -> None:
    """Persist a booking to Firestore, falling back to local JSON."""
    saved_to_firestore = False
    try:
        db = get_firestore_client()
        if db:
            db.collection('bookings').document(booking_id).set(record)
            saved_to_firestore = True
    except Exception as e:
        print(f"[backend] Firestore write failed: {e}")

    if not saved_to_firestore:
        # Local JSON fallback
        BOOKINGS_FILE.parent.mkdir(parents=True, exist_ok=True)
        bookings: dict[str, Any] = {}
        if BOOKINGS_FILE.exists():
            try:
                raw = json.loads(BOOKINGS_FILE.read_text(encoding="utf-8"))
                if isinstance(raw, list):
                    bookings = {b.get("booking_id", str(i)): b for i, b in enumerate(raw)}
                else:
                    bookings = raw
            except json.JSONDecodeError:
                pass
        bookings[booking_id] = record
        BOOKINGS_FILE.write_text(
            json.dumps(list(bookings.values()), indent=2, ensure_ascii=False),
            encoding="utf-8",
        )


def _save_notification(record: dict[str, Any]) -> None:
    """Save a simulated WhatsApp notification to data/notifications.json."""
    NOTIFICATIONS_FILE = _BASE / "data" / "notifications.json"
    NOTIFICATIONS_FILE.parent.mkdir(parents=True, exist_ok=True)
    
    notifications = []
    if NOTIFICATIONS_FILE.exists():
        try:
            notifications = json.loads(NOTIFICATIONS_FILE.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            pass
            
    notifications.append(record)
    NOTIFICATIONS_FILE.write_text(
        json.dumps(notifications, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )


def _load_agent_logs() -> list[dict[str, Any]]:
    AGENT_LOGS_FILE = _BASE / "data" / "agent_logs.json"
    if not AGENT_LOGS_FILE.exists():
        return []
    try:
        return json.loads(AGENT_LOGS_FILE.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return []


def log_agent_action(agent: str, action: str, reasoning: Optional[str] = None) -> None:
    """Log an agent's decision-making process to data/agent_logs.json."""
    AGENT_LOGS_FILE = _BASE / "data" / "agent_logs.json"
    AGENT_LOGS_FILE.parent.mkdir(parents=True, exist_ok=True)
    
    logs = _load_agent_logs()
    logs.append({
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "agent": agent,
        "agent_name": agent,
        "action": action,
        "reasoning": reasoning or ""
    })
    
    AGENT_LOGS_FILE.write_text(
        json.dumps(logs, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )


# ---------------------------------------------------------------------------
# Haversine utility
# ---------------------------------------------------------------------------


def haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    """Great-circle distance between two decimal-degree coordinates (km)."""
    R = 6_371.0
    phi1, phi2   = math.radians(lat1), math.radians(lat2)
    d_phi        = math.radians(lat2 - lat1)
    d_lambda     = math.radians(lng2 - lng1)
    a = (
        math.sin(d_phi / 2) ** 2
        + math.cos(phi1) * math.cos(phi2) * math.sin(d_lambda / 2) ** 2
    )
    return round(R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)), 2)


# ---------------------------------------------------------------------------
# Pydantic request / response models
# ---------------------------------------------------------------------------


class SearchRequest(BaseModel):
    """POST /search request body."""
    service_type: str = Field(..., min_length=2, examples=["Plumber"],
                              description="Service category to search for.")
    user_lat:  float  = Field(..., ge=-90,  le=90,  description="User latitude.")
    user_lon:  float  = Field(..., ge=-180, le=180, description="User longitude.")
    location:  Optional[str] = Field(None, description="Human-readable location label (city / area).")
    radius_km: float  = Field(50.0, gt=0, le=500, description="Search radius in km.")


class RankRequest(BaseModel):
    """POST /rank request body."""
    providers_list: list[dict[str, Any]] = Field(
        ..., description="List of provider objects (as returned by /search or /providers)."
    )
    user_lat: float = Field(..., ge=-90,  le=90)
    user_lon: float = Field(..., ge=-180, le=180)


class BookingRequest(BaseModel):
    """POST /book request body."""
    provider_id:  str = Field(..., pattern=r"^[A-Za-z0-9_-]+$", description="Unique provider ID (e.g. 'p008').")
    user_name:    str = Field(..., min_length=2, description="Customer full name.")
    user_phone:   str = Field(..., description="Customer phone number (+92-...).")
    service_type: str = Field(..., description="Service being booked.")
    time_slot:    str = Field(..., description="Requested date/time (ISO 8601 or human-readable).")
    location:     str = Field(..., min_length=3, description="Full service address.")
    notes:        Optional[str] = Field(None, description="Extra instructions for the provider.")


class HealthResponse(BaseModel):
    status:    str
    timestamp: str
    version:   str


class BookingResponse(BaseModel):
    booking_id: str
    status:     str
    message:    str
    created_at: str
    receipt:    str


class NotifyRequest(BaseModel):
    """POST /notify request body."""
    recipient_phone: str = Field(..., description="Recipient WhatsApp number")
    message: str = Field(..., description="Message content to send")


class NotifyResponse(BaseModel):
    status: str
    message_id: str
    timestamp: str


# ---------------------------------------------------------------------------
# Ranking helper
# ---------------------------------------------------------------------------


def _score_provider(
    provider: dict[str, Any],
    user_lat: float,
    user_lon: float,
    max_distance_km: float = 100.0,
) -> dict[str, Any]:
    """Compute a [0, 1] composite score with the SewaBot weighting:

    * Distance   40 %  — closer is better (linear decay over max_distance_km)
    * Rating     35 %  — provider.rating / 5.0
    * Availability 15 % — 1.0 if available, 0.0 otherwise
    * Verified   10 %  — 1.0 if verified, 0.0 otherwise
    """
    loc = provider.get("location", {})
    dist_km = haversine_km(
        user_lat, user_lon,
        loc.get("lat", user_lat),
        loc.get("lng", user_lon),
    )

    # Component scores (all in [0, 1])
    dist_score  = max(0.0, 1.0 - dist_km / max_distance_km)
    rating_score = min(provider.get("rating", 0.0), 5.0) / 5.0
    avail_score  = 1.0 if provider.get("available", True) else 0.0
    verif_score  = 1.0 if provider.get("verified", False) else 0.0

    composite = (
        0.40 * dist_score
        + 0.35 * rating_score
        + 0.15 * avail_score
        + 0.10 * verif_score
    )

    return {
        **provider,
        "distance_km": dist_km,
        "score": round(composite, 4),
        "score_breakdown": {
            "distance":     round(0.40 * dist_score,  4),
            "rating":       round(0.35 * rating_score, 4),
            "availability": round(0.15 * avail_score,  4),
            "verified":     round(0.10 * verif_score,  4),
        },
    }


# ---------------------------------------------------------------------------
# Routes
# ---------------------------------------------------------------------------


@app.get("/", response_model=HealthResponse, summary="Health Check", tags=["System"])
def health_check() -> HealthResponse:
    """Return API health status and current UTC timestamp."""
    return HealthResponse(
        status="ok",
        timestamp=datetime.now(timezone.utc).isoformat(),
        version=app.version,
    )


@app.get("/admin", response_class=HTMLResponse, include_in_schema=False)
def admin_dashboard():
    """Serve the simple HTML admin dashboard."""
    admin_file = _BASE / "admin.html"
    if admin_file.exists():
        return HTMLResponse(content=admin_file.read_text(encoding="utf-8"))
    return HTMLResponse(content="<h1>Admin File Not Found</h1>", status_code=404)


@app.get("/providers", summary="List All Providers", tags=["Providers"])
def list_providers(
    service: Optional[str] = Query(
        None,
        description="Filter by service category (case-insensitive). "
                    "E.g. 'Plumber', 'AC Technician', 'Electrician'.",
    ),
    city: Optional[str] = Query(None, description="Filter by city (case-insensitive)."),
    verified_only: bool  = Query(False, description="Return only verified providers."),
) -> dict[str, Any]:
    """Return the full provider catalogue with optional filters."""
    providers = _load_providers()

    if service:
        normalized_service = normalize_service_type(service)
        providers = [p for p in providers if p["service"].lower() == normalized_service.lower()]
    if city:
        providers = [
            p for p in providers
            if p.get("location", {}).get("city", "").lower() == city.lower()
        ]
    if verified_only:
        providers = [p for p in providers if p.get("verified", False)]

    return {"total": len(providers), "providers": providers}


@app.post("/search", summary="Search Providers by Service + Location", tags=["Providers"])
def search_providers(body: SearchRequest) -> dict[str, Any]:
    """Find providers within *radius_km* of the user offering the requested service.

    Results include a ``distance_km`` field and are sorted nearest-first.
    """
    providers = _load_providers()

    # Filter by service category (case-insensitive)
    normalized_service = normalize_service_type(body.service_type)
    matched = [
        p for p in providers
        if p["service"].lower() == normalized_service.lower()
    ]
    if not matched:
        raise HTTPException(
            status_code=404,
            detail=f"No providers found for service '{body.service_type}' (mapped to '{normalized_service}').",
        )

    # Attach distance and filter by radius
    results: list[dict[str, Any]] = []
    for p in matched:
        loc  = p.get("location", {})
        dist = haversine_km(body.user_lat, body.user_lon, loc.get("lat", 0), loc.get("lng", 0))
        if dist <= body.radius_km:
            results.append({**p, "distance_km": dist})

    if not results:
        return {
            "total": 0,
            "providers": [],
            "message": (
                f"No '{body.service_type}' providers found within "
                f"{body.radius_km} km of the supplied location."
            ),
        }

    results.sort(key=lambda p: p["distance_km"])

    return {
        "total": len(results),
        "search_params": {
            "service_type": body.service_type,
            "user_lat":     body.user_lat,
            "user_lon":     body.user_lon,
            "location":     body.location,
            "radius_km":    body.radius_km,
        },
        "providers": results,
    }


@app.post("/rank", summary="Rank Providers by Composite Score", tags=["Providers"])
def rank_providers(body: RankRequest) -> dict[str, Any]:
    """Rank a list of providers using SewaBot's weighted scoring model:

    | Factor       | Weight |
    |--------------|--------|
    | Distance     | 40 %   |
    | Rating       | 35 %   |
    | Availability | 15 %   |
    | Verified     | 10 %   |

    Pass the ``providers_list`` returned by ``POST /search`` or ``GET /providers``.
    The response adds ``score`` and ``score_breakdown`` fields to every provider.
    """
    if not body.providers_list:
        raise HTTPException(status_code=422, detail="providers_list cannot be empty.")

    scored = [
        _score_provider(p, body.user_lat, body.user_lon)
        for p in body.providers_list
    ]
    scored.sort(key=lambda p: p["score"], reverse=True)

    return {
        "total": len(scored),
        "weights": {
            "distance":     "40%",
            "rating":       "35%",
            "availability": "15%",
            "verified":     "10%",
        },
        "providers": scored,
    }


@app.post(
    "/book",
    response_model=BookingResponse,
    status_code=201,
    summary="Create a Booking",
    tags=["Bookings"],
)
def create_booking(body: BookingRequest) -> BookingResponse:
    """Create a new service booking and persist it to bookings.json.

    Raises 404 if the provider doesn't exist.
    Raises 409 if the provider is unavailable (verified=False).
    """
    providers = _load_providers()
    provider  = next((p for p in providers if p["id"] == body.provider_id), None)

    if provider is None:
        raise HTTPException(
            status_code=404,
            detail=f"Provider '{body.provider_id}' does not exist.",
        )
    if not provider.get("available", True):
        raise HTTPException(
            status_code=409,
            detail=(
                f"Provider '{provider['name']}' is currently unavailable. "
                "Please choose a different provider or try again later."
            ),
        )

    booking_id = f"BK-{uuid.uuid4().hex[:10].upper()}"
    created_at = datetime.now(timezone.utc).isoformat()

    record: dict[str, Any] = {
        "booking_id":  booking_id,
        "status":      "confirmed",
        "provider": {
            "id":          provider["id"],
            "name":        provider["name"],
            "service":     provider["service"],
            "phone":       provider.get("phone", ""),
            "price_pkr":   provider.get("price_pkr", provider.get("price", 0)),
            "location":    provider.get("location", {}),
        },
        "customer": {
            "name":  body.user_name,
            "phone": body.user_phone,
        },
        "service_type": body.service_type,
        "time_slot":    body.time_slot,
        "location":     body.location,
        "notes":        body.notes,
        "created_at":   created_at,
        "updated_at":   created_at,
    }

    _save_booking(booking_id, record)

    price_pkr = provider.get("price_pkr", provider.get("price", 0))
    receipt_text = (
        f"--- SewaBot Booking Receipt ---\n"
        f"Booking ID: {booking_id}\n"
        f"Customer: {body.user_name}\n"
        f"Provider: {provider['name']}\n"
        f"Service: {body.service_type}\n"
        f"Time Slot: {body.time_slot}\n"
        f"Location: {body.location}\n"
        f"Price: Rs. {price_pkr}\n"
        f"-------------------------------\n"
        f"Shukriya! Your booking is confirmed. Provider apse jald raabta karega."
    )

    return BookingResponse(
        booking_id=booking_id,
        status="confirmed",
        message=(
            f"Booking confirmed with {provider['name']}. "
            f"They will contact you at {body.user_phone}."
        ),
        created_at=created_at,
        receipt=receipt_text,
    )


@app.get("/bookings/{booking_id}", summary="Get Booking Details", tags=["Bookings"])
def get_booking(
    booking_id: str = FastApiPath(..., pattern=r"^BK-[A-F0-9]{10}$", description="Booking ID format: BK-XXXXXXXXXX")
) -> dict[str, Any]:
    """Retrieve full details for a single booking by its ID."""
    bookings = _load_bookings()
    booking  = bookings.get(booking_id)
    if booking is None:
        raise HTTPException(
            status_code=404,
            detail=f"Booking '{booking_id}' not found.",
        )
    return booking


@app.get("/bookings", summary="List All Bookings", tags=["Bookings"])
def list_bookings(
    status: Optional[str] = Query(None, description="Filter by status ('confirmed', 'cancelled')."),
) -> dict[str, Any]:
    """Return all persisted bookings, optionally filtered by status."""
    bookings = list(_load_bookings().values())
    if status:
        bookings = [b for b in bookings if b["status"].lower() == status.lower()]
    return {"total": len(bookings), "bookings": bookings}


# ---------------------------------------------------------------------------
# Notifications Route
# ---------------------------------------------------------------------------

@app.post("/notify", response_model=NotifyResponse, summary="Simulate WhatsApp Notification", tags=["Notifications"])
def send_notification(body: NotifyRequest) -> NotifyResponse:
    """Simulate sending a WhatsApp notification to a provider or customer.
    
    Used by the Booking Agent and Follow-up Agent.
    """
    timestamp = datetime.now(timezone.utc).isoformat()
    message_id = f"MSG-{uuid.uuid4().hex[:8].upper()}"
    
    # 1. Log a fake WhatsApp message format to console
    print(f"\n{'='*40}")
    print(f"🟢 WHATSAPP MESSAGE SIMULATOR")
    print(f"To: {body.recipient_phone}")
    print(f"Time: {timestamp}")
    print(f"ID: {message_id}")
    print(f"----------------------------------------")
    print(f"{body.message}")
    print(f"{'='*40}\n")
    
    # 2. Save to data/notifications.json
    record = {
        "message_id": message_id,
        "recipient_phone": body.recipient_phone,
        "message": body.message,
        "timestamp": timestamp,
        "status": "delivered_simulated"
    }
    _save_notification(record)
    
    return NotifyResponse(
        status="sent",
        message_id=message_id,
        timestamp=timestamp,
    )


# ---------------------------------------------------------------------------
# Agent Logs Route
# ---------------------------------------------------------------------------

@app.get("/agent-logs", summary="Get Agent Reasoning Traces", tags=["Agents"])
def get_agent_logs(
    limit: int = Query(50, description="Maximum number of recent logs to return"),
) -> dict[str, Any]:
    """Retrieve the most recent agent reasoning traces."""
    logs = _load_agent_logs()
    logs.sort(key=lambda x: x.get("timestamp", ""), reverse=True)
    recent_logs = logs[:limit]
    return {"total": len(recent_logs), "logs": recent_logs}


class AgentLogEntry(BaseModel):
    """POST /agent-logs request body — agents push session logs here."""
    session_id: str
    flow: list[dict[str, Any]] = Field(default_factory=list)
    total_agents_run: Optional[int] = None
    created_at: Optional[str] = None


@app.post("/agent-logs", summary="Push Agent Session Log", tags=["Agents"], status_code=201)
def push_agent_log(body: AgentLogEntry) -> dict[str, Any]:
    """Agents API pushes completed session logs here for persistence and Trace screen retrieval."""
    AGENT_LOGS_FILE = _BASE / "data" / "agent_logs.json"
    AGENT_LOGS_FILE.parent.mkdir(parents=True, exist_ok=True)

    logs = _load_agent_logs()
    # Remove existing entry for same session (upsert)
    logs = [l for l in logs if l.get("session_id") != body.session_id]
    entry = {
        "session_id": body.session_id,
        "created_at": body.created_at or datetime.now(timezone.utc).isoformat(),
        "total_agents_run": body.total_agents_run or len(body.flow),
        "flow": body.flow,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    logs.append(entry)
    AGENT_LOGS_FILE.write_text(
        json.dumps(logs, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    return {"status": "saved", "session_id": body.session_id}


@app.get("/agent-logs/{session_id}", summary="Get Agent Log by Session", tags=["Agents"])
def get_agent_log_by_session(session_id: str) -> dict[str, Any]:
    """Get the agent reasoning trace for a specific session (used by Flutter Trace screen)."""
    logs = _load_agent_logs()
    for log in logs:
        if log.get("session_id") == session_id:
            return log
    raise HTTPException(status_code=404, detail=f"Session '{session_id}' not found.")


# ---------------------------------------------------------------------------
# Background Tasks
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Disputes Route
# ---------------------------------------------------------------------------

class DisputeRequest(BaseModel):
    """POST /disputes request body."""
    booking_id: str = Field(..., description="Booking ID the dispute is against")
    category: str = Field(..., description="Category: Late Arrival, Quality Issue, etc.")
    description: str = Field(..., min_length=20, description="Detailed description")
    contact_phone: str = Field(..., description="Contact phone number")


class DisputeResponse(BaseModel):
    dispute_id: str
    status: str
    message: str
    created_at: str


@app.post(
    "/disputes",
    response_model=DisputeResponse,
    status_code=201,
    summary="File a Dispute",
    tags=["Disputes"],
)
def create_dispute(body: DisputeRequest) -> DisputeResponse:
    """File a dispute against a booking. Persists to Firestore disputes collection."""
    dispute_id = f"DS-{uuid.uuid4().hex[:10].upper()}"
    created_at = datetime.now(timezone.utc).isoformat()

    record: dict[str, Any] = {
        "dispute_id": dispute_id,
        "booking_id": body.booking_id,
        "category": body.category,
        "description": body.description,
        "contact_phone": body.contact_phone,
        "status": "received",
        "created_at": created_at,
    }

    # Persist to Firestore if available, else write to local JSON
    try:
        db = get_firestore_client()
        if db:
            db.collection("disputes").document(dispute_id).set(record)
        else:
            _save_dispute_local(record)
    except Exception as e:
        print(f"Error saving dispute: {e}")
        _save_dispute_local(record)

    return DisputeResponse(
        dispute_id=dispute_id,
        status="received",
        message="Your dispute has been received. We will review it within 24 hours.",
        created_at=created_at,
    )


def _save_dispute_local(record: dict[str, Any]) -> None:
    """Local JSON fallback when Firestore is unavailable."""
    disputes_file = _BASE / "data" / "disputes.json"
    disputes_file.parent.mkdir(parents=True, exist_ok=True)
    disputes = []
    if disputes_file.exists():
        try:
            disputes = json.loads(disputes_file.read_text(encoding="utf-8"))
        except json.JSONDecodeError:
            pass
    disputes.append(record)
    disputes_file.write_text(
        json.dumps(disputes, indent=2, ensure_ascii=False), encoding="utf-8"
    )


# ---------------------------------------------------------------------------
# Background Tasks
# ---------------------------------------------------------------------------

async def backup_firestore_data():
    """Background task to back up Firestore data every hour."""
    while True:
        await asyncio.sleep(3600)  # Wait 1 hour
        try:
            db = get_firestore_client()
            backup_data = {"bookings": {}, "providers": {}}
            
            # Export bookings
            bookings_docs = db.collection('bookings').stream()
            for doc in bookings_docs:
                backup_data["bookings"][doc.id] = doc.to_dict()
                
            # Export providers
            providers_docs = db.collection('providers').stream()
            for doc in providers_docs:
                backup_data["providers"][doc.id] = doc.to_dict()
                
            backup_file = _BASE / "data" / "backup.json"
            backup_file.parent.mkdir(parents=True, exist_ok=True)
            backup_file.write_text(
                json.dumps(backup_data, indent=2, ensure_ascii=False), 
                encoding="utf-8"
            )
            print(f"[{datetime.now(timezone.utc).isoformat()}] Backed up Firestore data to {backup_file}")
        except Exception as e:
            print(f"Error during backup: {e}")

@app.on_event("startup")
async def startup_event():
    asyncio.create_task(backup_firestore_data())


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    _port = int(os.getenv("PORT", 8000))
    uvicorn.run("main:app", host="0.0.0.0", port=_port, reload=False)
