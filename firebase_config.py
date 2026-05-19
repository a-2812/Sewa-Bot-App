import os
from pathlib import Path
# pyrefly: ignore [missing-import]
import firebase_admin
# pyrefly: ignore [missing-import]
from firebase_admin import credentials, firestore

_BASE = Path(__file__).parent
FIREBASE_KEY_PATH = _BASE / "firebase-key.json"

_db = None

def get_firestore_client():
    global _db
    if _db is not None:
        return _db
        
    if not FIREBASE_KEY_PATH.exists():
        raise FileNotFoundError(f"Firebase key file not found at {FIREBASE_KEY_PATH}")
        
    try:
        # Check if already initialized (e.g. during testing or reloads)
        firebase_admin.get_app()
    except ValueError:
        cred = credentials.Certificate(str(FIREBASE_KEY_PATH))
        firebase_admin.initialize_app(cred)
        
    _db = firestore.client()
    return _db
