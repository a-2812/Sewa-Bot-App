import json
import uuid
import time
import os
import requests
from datetime import datetime, timedelta

SAAD_BACKEND_URL = os.getenv("SAAD_BACKEND_URL", "http://localhost:8000")
NOTIFICATIONS_FALLBACK = os.path.join(os.path.dirname(__file__), "data", "scheduled_notifications.json")


def _save_notifications_local(data: list):
    os.makedirs(os.path.dirname(NOTIFICATIONS_FALLBACK), exist_ok=True)
    existing = []
    if os.path.exists(NOTIFICATIONS_FALLBACK):
        with open(NOTIFICATIONS_FALLBACK, "r", encoding="utf-8") as f:
            existing = json.load(f)
    existing.append(data)
    with open(NOTIFICATIONS_FALLBACK, "w", encoding="utf-8") as f:
        json.dump(existing, f, indent=2, ensure_ascii=False)


def _send_notification(phone: str, message: str) -> bool:
    try:
        resp = requests.post(
            f"{SAAD_BACKEND_URL}/notify",
            json={"recipient_phone": phone, "message": message},
            timeout=3
        )
        return resp.status_code == 200
    except Exception:
        return False


def run(booking_confirmation: dict, provider_phone: str = "") -> tuple[dict, str]:
    start = time.time()

    bid = booking_confirmation.get("booking_id", "BK-UNKNOWN")
    provider_name = booking_confirmation.get("provider_name", "Provider")
    service_type = booking_confirmation.get("service_type", "Service")
    confirmed_slot = booking_confirmation.get("confirmed_slot", "Scheduled Time")
    location = booking_confirmation.get("location", "")
    total_price = booking_confirmation.get("total_price_pkr", 0)

    now = datetime.now()
    # Estimate appointment time (2 hours from now as proxy for scheduled slot)
    appointment_dt = now + timedelta(hours=2)

    notifications = [
        {
            "notification_id": f"notif_{uuid.uuid4().hex[:6]}",
            "type": "confirmation",
            "recipient": "user",
            "message": booking_confirmation.get("user_message", f"Booking {bid} confirmed."),
            "scheduled_for": now.isoformat(),
            "channel": "sms_simulated",
            "status": "sent_simulated"
        },
        {
            "notification_id": f"notif_{uuid.uuid4().hex[:6]}",
            "type": "provider_alert",
            "recipient": "provider",
            "message": booking_confirmation.get("provider_message", f"New job: {service_type} at {location}."),
            "scheduled_for": now.isoformat(),
            "channel": "whatsapp_simulated",
            "status": "sent_simulated"
        },
        {
            "notification_id": f"notif_{uuid.uuid4().hex[:6]}",
            "type": "reminder_user",
            "recipient": "user",
            "message": f"Reminder: {provider_name} arrives in 1 hour at {location} ({confirmed_slot}).",
            "scheduled_for": (appointment_dt - timedelta(hours=1)).isoformat(),
            "channel": "push",
            "status": "scheduled"
        },
        {
            "notification_id": f"notif_{uuid.uuid4().hex[:6]}",
            "type": "reminder_provider",
            "recipient": "provider",
            "message": f"Reminder: Job at {location} at {confirmed_slot}. Customer waiting.",
            "scheduled_for": (appointment_dt - timedelta(hours=1, minutes=30)).isoformat(),
            "channel": "sms_simulated",
            "status": "scheduled"
        },
        {
            "notification_id": f"notif_{uuid.uuid4().hex[:6]}",
            "type": "completion_check",
            "recipient": "user",
            "message": f"Has your {service_type} been completed? Tap to confirm and rate.",
            "scheduled_for": (appointment_dt + timedelta(hours=2)).isoformat(),
            "channel": "in_app",
            "status": "scheduled"
        },
        {
            "notification_id": f"notif_{uuid.uuid4().hex[:6]}",
            "type": "feedback_request",
            "recipient": "user",
            "message": f"Please rate {provider_name}. Your feedback helps others in the community!",
            "scheduled_for": (appointment_dt + timedelta(hours=4)).isoformat(),
            "channel": "in_app",
            "status": "scheduled"
        }
    ]

    # Try sending immediate notifications via Saad's /notify endpoint
    sent_via_backend = 0
    for n in notifications[:2]:  # Only send immediate ones now
        if _send_notification("+92-300-0000000", n["message"]):
            n["status"] = "sent"
            sent_via_backend += 1

    # Save all notifications locally as audit trail
    _save_notifications_local({
        "booking_id": bid,
        "created_at": now.isoformat(),
        "notifications": notifications
    })

    duration_ms = int((time.time() - start) * 1000)
    channels = list({n["channel"] for n in notifications})

    reasoning = (
        f"Booking {bid} follow-up scheduled. "
        f"{len(notifications)} notifications queued: "
        f"2 immediate (confirmation + provider alert), "
        f"2 reminders (1hr before user, 1.5hr before provider), "
        f"completion check (2hr after), feedback request (4hr after). "
        f"Channels: {', '.join(channels)}."
    )

    output = {
        "booking_id": bid,
        "notifications_scheduled": len(notifications),
        "notifications": notifications,
        "channels_used": channels,
        "duration_ms": duration_ms
    }

    return output, reasoning
