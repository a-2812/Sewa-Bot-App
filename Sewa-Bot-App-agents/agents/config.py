import os
from dotenv import load_dotenv

load_dotenv()

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
FIREBASE_PROJECT_ID = os.getenv("FIREBASE_PROJECT_ID", "")
FIREBASE_CREDENTIALS_PATH = os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-credentials.json")

# Backend base URL — agents call this to persist bookings, notify, etc.
BACKEND_BASE_URL = os.getenv("BACKEND_BASE_URL", "http://localhost:8000")
