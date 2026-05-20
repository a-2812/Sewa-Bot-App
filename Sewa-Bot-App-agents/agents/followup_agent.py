import time
import os
import json
import uuid
from datetime import datetime

try:
    import requests as _requests
except ImportError:
    _requests = None

from config import BACKEND_BASE_URL

NOTIFICATIONS_FALLBACK = os.path.join(os.path.dirname(__file__), "data", "scheduled_notifications.json")


def _save_local_notifications(notif_doc: dict):
    os.makedirs(os.path.dirname(NOTIFICATIONS_FALLBACK), exist_ok=True)
    data = []
    if os.path.exists(NOTIFICATIONS_FALLBACK):
        with open(NOTIFICATIONS_FALLBACK, "r", encoding="utf-8") as f:
            data = json.load(f)
    data.append(notif_doc)
    with open(NOTIFICATIONS_FALLBACK, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def _send_notify(phone: str, message: str) -> bool:
    """Call backend POST /notify. Returns True if successful."""
    if _requests:
        try:
            resp = _requests.post(
                f"{BACKEND_BASE_URL}/notify",
                json={"recipient_phone": phone, "message": message},
                timeout=10,
            )
            return resp.status_code == 200
        except Exception:
            pass
    return False


def run(booking: dict) -> tuple[dict, str]:
    start = time.time()

    booking_id    = booking.get("booking_id", "BK-UNKNOWN")
    provider_name = booking.get("provider_name", "Provider")
    user_name     = booking.get("user_name", "User")
    slot_time     = booking.get("slot_time", "10:00 AM")
    location      = booking.get("location", "Location")
    date_str      = booking.get("booking_date", datetime.now().strftime("%Y-%m-%d"))
    service       = booking.get("service_display", booking.get("service", "Service"))
    provider_phone = booking.get("provider_phone", "+92-300-0000000")

    # Build 6 notification records
    notifications = [
        {
            "notification_id": f"notif_{uuid.uuid4().hex[:6]}",
            "type": "confirmation",
            "recipient": "user",
            "message": f"✅ SewaBot: Your {service} booking ({booking_id}) is confirmed for {date_str} at {slot_time}. Provider: {provider_name}. Shukriya!",
            "scheduled_for": datetime.now().isoformat(),
            "channel": "sms_simulated",
            "status": "sent_simulated",
        },
        {
            "notification_id": f"notif_{uuid.uuid4().hex[:6]}",
            "type": "provider_alert",
            "recipient": "provider",
            "message": f"🔔 SewaBot Alert: New booking! Customer {user_name} in {location} needs {service} at {slot_time} on {date_str}. Booking ID: {booking_id}. Please confirm.",
            "scheduled_for": datetime.now().isoformat(),
            "channel": "whatsapp_simulated",
            "status": "sent_simulated",
        },
        {
            "notification_id": f"notif_{uuid.uuid4().hex[:6]}",
            "type": "reminder_user",
            "recipient": "user",
            "message": f"⏰ Reminder: {provider_name} arrives in 1 hour at {location} ({slot_time}). Booking: {booking_id}",
            "scheduled_for": f"{date_str}T09:00:00",
            "channel": "push",
            "status": "scheduled",
        },
        {
            "notification_id": f"notif_{uuid.uuid4().hex[:6]}",
            "type": "reminder_provider",
            "recipient": "provider",
            "message": f"⏰ Reminder: You have a job at {location} at {slot_time}. Customer: {user_name}. Booking: {booking_id}",
            "scheduled_for": f"{date_str}T08:30:00",
            "channel": "sms_simulated",
            "status": "scheduled",
        },
        {
            "notification_id": f"notif_{uuid.uuid4().hex[:6]}",
            "type": "completion_check",
            "recipient": "user",
            "message": f"✔ Has your {service} service been completed? Tap to confirm and update your booking status.",
            "scheduled_for": f"{date_str}T12:00:00",
            "channel": "in_app",
            "status": "scheduled",
        },
        {
            "notification_id": f"notif_{uuid.uuid4().hex[:6]}",
            "type": "feedback_request",
            "recipient": "user",
            "message": f"⭐ Please rate {provider_name} for your {service} service. Your feedback helps others find great providers!",
            "scheduled_for": f"{date_str}T14:00:00",
            "channel": "in_app",
            "status": "scheduled",
        },
    ]

    # Send notifications via backend
    sent_via_backend = 0
    for notif in notifications:
        # Determine a reasonable recipient phone based on the type
        phone = provider_phone if notif["recipient"] == "provider" else "+92-300-0000000"
        if _send_notify(phone, notif["message"]):
            sent_via_backend += 1

    # Save all to local scheduled notifications file
    notif_doc = {
        "booking_id": booking_id,
        "created_at": datetime.now().isoformat(),
        "notifications": notifications,
    }
    _save_local_notifications(notif_doc)

    duration_ms = int((time.time() - start) * 1000)

    reasoning = (
        f"Booking confirmed for {date_str} {slot_time}. Scheduled 6 notifications: "
        f"(1) immediate confirmation SMS to user, (2) immediate WhatsApp alert to provider, "
        f"(3) 1-hour-before reminder to user at 09:00, (4) provider reminder at 08:30, "
        f"(5) completion check at 12:00, (6) feedback request at 14:00. "
        f"Sent {sent_via_backend} immediate notifications via backend /notify endpoint."
    )

    output = {
        "notifications_scheduled": 6,
        "notifications_sent_immediately": sent_via_backend,
        "notifications": notifications,
        "channels_used": ["sms_simulated", "whatsapp_simulated", "push", "in_app"],
        "duration_ms": duration_ms,
    }

    return output, reasoning
