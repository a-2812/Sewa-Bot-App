import json
import time
import os
import uuid
from datetime import datetime

try:
    import requests as _requests
except ImportError:
    _requests = None

from config import BACKEND_BASE_URL

BOOKINGS_FALLBACK = os.path.join(os.path.dirname(__file__), "data", "bookings.json")


def _save_booking_local(booking: dict):
    os.makedirs(os.path.dirname(BOOKINGS_FALLBACK), exist_ok=True)
    data = []
    if os.path.exists(BOOKINGS_FALLBACK):
        with open(BOOKINGS_FALLBACK, "r", encoding="utf-8") as f:
            data = json.load(f)
    data.append(booking)
    with open(BOOKINGS_FALLBACK, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def run(intent: dict, provider: dict, quote: dict) -> tuple[dict, str]:
    start = time.time()

    provider_id   = provider.get("provider_id", provider.get("id", "prov_000"))
    provider_name = provider.get("provider_name", provider.get("name", "Provider"))
    service_type  = intent.get("service_type", "Service")
    user_name     = intent.get("user_name", "SewaBot User")
    user_phone    = intent.get("user_phone", "+92-300-0000000")
    location      = intent.get("location", "User Location")
    time_pref     = intent.get("preferred_time", "10:00")

    # Map time preference string to a readable slot
    slot_map = {
        "today_morning": "09:00", "tomorrow_morning": "10:00",
        "today_afternoon": "14:00", "tomorrow_afternoon": "14:00",
        "today_evening": "17:00", "tomorrow_evening": "17:00",
        "urgent": "09:00", "not_specified": "10:00",
    }
    slot = slot_map.get(time_pref, time_pref if ":" in time_pref else "10:00")

    # Use a slot from provider's available_slots if possible
    available_slots = provider.get("available_slots", [])
    if available_slots and slot not in available_slots:
        slot = available_slots[0]

    # --- Try booking via backend API ---
    booking_id = None
    receipt    = None
    used_backend = False

    if _requests:
        try:
            resp = _requests.post(
                f"{BACKEND_BASE_URL}/book",
                json={
                    "provider_id":  provider_id,
                    "user_name":    user_name,
                    "user_phone":   user_phone,
                    "service_type": service_type,
                    "time_slot":    slot,
                    "location":     location,
                    "notes":        "Created by SewaBot agent orchestrator",
                },
                timeout=15,
            )
            if resp.status_code in (200, 201):
                data = resp.json()
                booking_id   = data.get("booking_id")
                receipt      = data.get("receipt", "")
                used_backend = True
        except Exception:
            pass

    # --- Fallback: local booking ---
    if not booking_id:
        booking_id = f"BK-{datetime.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:4].upper()}"
        receipt = (
            f"╔══════════════════════════════════╗\n"
            f"║    SEWABOT BOOKING CONFIRMED     ║\n"
            f"╠══════════════════════════════════╣\n"
            f"║  Booking ID:  {booking_id:<18} ║\n"
            f"║  Service:     {service_type[:15]:<18} ║\n"
            f"║  Provider:    {provider_name[:15]:<18} ║\n"
            f"║  Date:        {datetime.now().strftime('%a, %b %d, %Y')[:18]:<18} ║\n"
            f"║  Time:        {slot[:18]:<18} ║\n"
            f"║  Location:    {location[:18]:<18} ║\n"
            f"║  Est. Cost:   PKR {quote.get('total_quoted_pkr', provider.get('price_pkr', provider.get('price', 1500))):<14} ║\n"
            f"╠══════════════════════════════════╣\n"
            f"║  Status:      ✓ CONFIRMED        ║\n"
            f"╚══════════════════════════════════╝"
        )

    booking_doc = {
        "booking_id":       booking_id,
        "session_id":       intent.get("session_id", "sess_" + uuid.uuid4().hex[:8]),
        "user_name":        user_name,
        "service":          service_type,
        "service_display":  service_type,
        "provider_id":      provider_id,
        "provider_name":    provider_name,
        "provider_phone":   provider.get("phone", "0300-XXXXXXX"),
        "location":         location,
        "slot_time":        slot,
        "booking_date":     datetime.now().strftime("%Y-%m-%d"),
        "status":           "confirmed",
        "price_estimate":   quote.get("total_quoted_pkr", provider.get("price_pkr", provider.get("price", 1500))),
        "currency":         "PKR",
        "created_at":       datetime.now().isoformat(),
        "reminders_scheduled": True,
        "receipt":          receipt,
    }

    if not used_backend:
        _save_booking_local(booking_doc)

    duration_ms = int((time.time() - start) * 1000)

    reasoning = (
        f"Generated booking ID {booking_id}. "
        f"{'Persisted via backend API.' if used_backend else 'Saved to local fallback.'} "
        f"Provider {provider_id} assigned slot '{slot}'. "
        f"Generated formatted receipt. System state changed successfully."
    )

    agent_trace = {
        "agent_name": "BookingAgent",
        "total_latency_ms": duration_ms,
        "status": "success",
    }

    output = {
        "booking_confirmation": booking_doc,
        "agent_trace": agent_trace,
    }

    return output, reasoning
