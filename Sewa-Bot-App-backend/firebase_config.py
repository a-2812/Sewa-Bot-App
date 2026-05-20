import json
import os
from pathlib import Path

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    _FIREBASE_AVAILABLE = True
except ImportError:
    _FIREBASE_AVAILABLE = False

_db = None
_INIT_ATTEMPTED = False


def get_firestore_client():
    """
    Return a Firestore client, or None if Firebase is unavailable.

    Credential resolution order:
      1. FIREBASE_CREDENTIALS_JSON env var  — full JSON string (Render secret)
      2. GOOGLE_APPLICATION_CREDENTIALS     — path to service account file (ADC)
      3. firebase-key.json in repo root     — local dev fallback

    If none of the above are available, returns None so the app can
    fall back to local JSON files instead of crashing.
    """
    global _db, _INIT_ATTEMPTED
    if _db is not None:
        return _db
    if _INIT_ATTEMPTED:
        return None
    _INIT_ATTEMPTED = True

    if not _FIREBASE_AVAILABLE:
        print("[firebase_config] firebase_admin not installed — Firestore disabled")
        return None

    cred = None

    # 1. JSON string in env var (Render / cloud deployments)
    creds_json = os.getenv("FIREBASE_CREDENTIALS_JSON", "").strip()
    if creds_json:
        try:
            cred_dict = json.loads(creds_json)
            cred = credentials.Certificate(cred_dict)
            print("[firebase_config] Using FIREBASE_CREDENTIALS_JSON env var")
        except Exception as e:
            print(f"[firebase_config] Failed to parse FIREBASE_CREDENTIALS_JSON: {e}")

    # 2. GOOGLE_APPLICATION_CREDENTIALS path
    if cred is None:
        gac = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "")
        if gac and Path(gac).exists():
            try:
                cred = credentials.Certificate(gac)
                print(f"[firebase_config] Using GOOGLE_APPLICATION_CREDENTIALS: {gac}")
            except Exception as e:
                print(f"[firebase_config] Failed to load GOOGLE_APPLICATION_CREDENTIALS: {e}")

    # 3. Local firebase-key.json fallback
    if cred is None:
        local_key = Path(__file__).parent / "firebase-key.json"
        if local_key.exists():
            try:
                cred = credentials.Certificate(str(local_key))
                print(f"[firebase_config] Using local firebase-key.json")
            except Exception as e:
                print(f"[firebase_config] Failed to load firebase-key.json: {e}")

    if cred is None:
        print(
            "[firebase_config] No Firebase credentials found. "
            "Firestore disabled — using local JSON fallback."
        )
        return None

    try:
        try:
            firebase_admin.get_app()
        except ValueError:
            firebase_admin.initialize_app(cred)
        _db = firestore.client()
        print("[firebase_config] Firestore client initialised successfully")
        return _db
    except Exception as e:
        print(f"[firebase_config] Firestore init failed: {e}")
        return None
