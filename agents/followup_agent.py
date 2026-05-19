import time
import os
import json
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


def run(booking: dict) -> tuple[dict, str]:
    start = time.time()
    
    booking_id = booking.get("booking_id", "BK-UNKNOWN")
    provider_name = booking.get("provider_name", "Provider")
    user_name = booking.get("user_name", "User")
    slot_time = booking.get("slot_time", "10:00 AM")
    location = booking.get("location", "Location")
    date_str = booking.get("booking_date", datetime.now().strftime("%Y-%m-%d"))
    
    # 6 Notifications
    notifications = [
        {
            "notification_id": f"notif_{uuid.uuid4().hex[:6]}",
            "type": "confirmation",
            "recipient": "user",
            "message": f"Your {booking.get('service_display', 'Service')} {provider_name} is confirmed for {date_str} at {slot_time}. Booking ID: {booking_id}",
            "scheduled_for": datetime.now().isoformat(),
            "channel": "sms_simulated",
            "status": "sent_simulated"
        },
        {
            "notification_id": f"notif_{uuid.uuid4().hex[:6]}",
            "type": "provider_alert",
            "recipient": "provider",
            "message": f"New booking! Customer {user_name} in {location} needs service at {slot_time} on {date_str}. Please confirm.",
            "scheduled_for": datetime.now().isoformat(),
            "channel": "whatsapp_simulated",
            "status": "sent_simulated"
        },
        {
            "notification_id": f"notif_{uuid.uuid4().hex[:6]}",
            "type": "reminder_user",
            "recipient": "user",
            "message": f"Reminder: {provider_name} arrives at your {location} location in 1 hour at {slot_time}.",
            "scheduled_for": f"{date_str}T09:00:00Z",
            "channel": "push",
            "status": "scheduled"
        },
        {
            "notification_id": f"notif_{uuid.uuid4().hex[:6]}",
            "type": "reminder_provider",
            "recipient": "provider",
            "message": f"Reminder: You have a booking at {location} at {slot_time}. Customer: {user_name}.",
            "scheduled_for": f"{date_str}T08:30:00Z",
            "channel": "sms_simulated",
            "status": "scheduled"
        },
        {
            "notification_id": f"notif_{uuid.uuid4().hex[:6]}",
            "type": "completion_check",
            "recipient": "user",
            "message": "Has your service been completed? Tap to confirm.",
            "scheduled_for": f"{date_str}T12:00:00Z",
            "channel": "in_app",
            "status": "scheduled"
        },
        {
            "notification_id": f"notif_{uuid.uuid4().hex[:6]}",
            "type": "feedback_request",
            "recipient": "user",
            "message": f"Please rate {provider_name}. Your feedback helps others!",
            "scheduled_for": f"{date_str}T14:00:00Z",
            "channel": "in_app",
            "status": "scheduled"
        }
    ]
    
    notif_doc = {
        "booking_id": booking_id,
        "created_at": datetime.now().isoformat(),
        "notifications": notifications
    }
    
    if db:
        try:
            db.collection("scheduled_notifications").add(notif_doc)
        except Exception:
            _save_local_notifications(notif_doc)
    else:
        _save_local_notifications(notif_doc)
        
    duration_ms = int((time.time() - start) * 1000)
    
    reasoning = (
        f"Booking confirmed for {date_str} {slot_time}. Scheduled 6 notifications: "
        f"(1) immediate confirmation SMS to user, (2) immediate WhatsApp alert to provider, "
        f"(3) 1-hour-before reminder to user at 09:00 AM, (4) provider reminder at 08:30 AM, "
        f"(5) completion check at 12:00 PM, (6) feedback request at 02:00 PM. "
        f"All written to scheduled_notifications collection."
    )
    
    output = {
        "notifications_scheduled": 6,
        "channels_used": ["sms_simulated", "whatsapp_simulated", "push", "in_app"],
        "duration_ms": duration_ms
    }
    
    return output, reasoning
