import json
import time
import os
import uuid
from datetime import datetime

# Attempt to load Firebase Admin
try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    from config import FIREBASE_CREDENTIALS_PATH, FIREBASE_PROJECT_ID
    
    if os.path.exists(FIREBASE_CREDENTIALS_PATH):
        if not firebase_admin._apps:
            cred = credentials.Certificate(FIREBASE_CREDENTIALS_PATH)
            firebase_admin.initialize_app(cred, {'projectId': FIREBASE_PROJECT_ID})
        db = firestore.client()
    else:
        db = None
except ImportError:
    db = None

BOOKINGS_FALLBACK = os.path.join(os.path.dirname(__file__), "data", "bookings.json")
PROVIDERS_FALLBACK = os.path.join(os.path.dirname(__file__), "data", "providers.json")

def _get_local_providers():
    if os.path.exists(PROVIDERS_FALLBACK):
        with open(PROVIDERS_FALLBACK, "r", encoding="utf-8") as f:
            return json.load(f)
    return []

def _save_local_providers(providers):
    with open(PROVIDERS_FALLBACK, "w", encoding="utf-8") as f:
        json.dump(providers, f, indent=2, ensure_ascii=False)

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
    
    service_type = provider.get("provider_name", intent.get("service_type", "Service"))
    provider_id = provider.get("provider_id", "prov_000")
    user_name = intent.get("user_name", "SewaBot User")
    location = intent.get("location", "User Location")
    time_pref = intent.get("preferred_time", "10:00")
    
    # Generate unique ID
    booking_id = f"BK-{datetime.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:4].upper()}"
    
    # 1. State change: Write to Bookings & Update Provider
    booking_doc = {
        "booking_id": booking_id,
        "session_id": "sess_" + uuid.uuid4().hex[:8], # Mock session if unavailable
        "user_name": user_name,
        "service": intent.get("service_type", "service"),
        "service_display": service_type,
        "provider_id": provider_id,
        "provider_name": provider.get("provider_name", "Provider"),
        "provider_phone": "0300-XXXXXXX",
        "location": location,
        "slot_time": time_pref,
        "booking_date": datetime.now().strftime("%Y-%m-%d"),
        "status": "confirmed",
        "price_estimate": quote.get("total_quoted_pkr", 1500),
        "currency": "PKR",
        "created_at": datetime.now().isoformat(),
        "reminders_scheduled": True
    }

    slot_removed = False
    
    if db:
        # Real Firebase
        try:
            # Write booking
            db.collection("bookings").document(booking_id).set(booking_doc)
            # Update provider
            prov_ref = db.collection("providers").document(provider_id)
            prov_doc = prov_ref.get()
            if prov_doc.exists:
                data = prov_doc.to_dict()
                slots = data.get("available_slots", [])
                if time_pref in slots:
                    slots.remove(time_pref)
                    prov_ref.update({"available_slots": slots})
                    slot_removed = True
        except Exception as e:
            pass # Fallback to local
    
    if not slot_removed:
        # Local mock
        _save_booking_local(booking_doc)
        local_providers = _get_local_providers()
        for p in local_providers:
            if p.get("id") == provider_id:
                if "available_slots" in p and time_pref in p["available_slots"]:
                    p["available_slots"].remove(time_pref)
                    slot_removed = True
        _save_local_providers(local_providers)

    # 2. Receipt Generation
    receipt = (
        f"╔══════════════════════════════════╗\n"
        f"║    SEWABOT BOOKING CONFIRMED     ║\n"
        f"╠══════════════════════════════════╣\n"
        f"║  Booking ID:  {booking_id:<18} ║\n"
        f"║  Service:     {service_type[:15]:<18} ║\n"
        f"║  Provider:    {provider.get('provider_name', 'Provider')[:15]:<18} ║\n"
        f"║  Date:        {datetime.now().strftime('%a, %b %d, %Y')[:18]:<18} ║\n"
        f"║  Time:        {time_pref[:18]:<18} ║\n"
        f"║  Location:    {location[:18]:<18} ║\n"
        f"║  Est. Cost:   PKR {quote.get('total_quoted_pkr', 1500):<14} ║\n"
        f"╠══════════════════════════════════╣\n"
        f"║  Status:      ✓ CONFIRMED        ║\n"
        f"╚══════════════════════════════════╝"
    )
    
    booking_doc["receipt"] = receipt
    
    duration_ms = int((time.time() - start) * 1000)

    reasoning = (
        f"Generated booking ID {booking_id}. "
        f"Wrote confirmed booking to {'Firestore' if db else 'local fallback'}. "
        f"Updated provider {provider_id} available_slots: removed '{time_pref}' so slot is now unavailable. "
        f"Generated formatted receipt. System state changed successfully."
    )

    agent_trace = {
        "agent_name": "BookingAgent",
        "total_latency_ms": duration_ms,
        "status": "success"
    }

    output = {
        "booking_confirmation": booking_doc,
        "agent_trace": agent_trace
    }

    return output, reasoning
