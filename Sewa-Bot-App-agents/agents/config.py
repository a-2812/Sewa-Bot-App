import os
import json
from dotenv import load_dotenv

load_dotenv()

# ── Gemini ────────────────────────────────────────────────────────────────────
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")

# ── Firebase ──────────────────────────────────────────────────────────────────
FIREBASE_PROJECT_ID = os.getenv("FIREBASE_PROJECT_ID", "")

# Credentials resolution order:
# 1. FIREBASE_CREDENTIALS_JSON env var  — full JSON string (Render / cloud)
# 2. GOOGLE_APPLICATION_CREDENTIALS     — path to file (standard ADC)
# 3. FIREBASE_CREDENTIALS_PATH          — explicit path (local dev fallback)
FIREBASE_CREDENTIALS_JSON = os.getenv("FIREBASE_CREDENTIALS_JSON", "")
FIREBASE_CREDENTIALS_PATH = (
    os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    or os.getenv("FIREBASE_CREDENTIALS_PATH", "firebase-credentials.json")
)

# ── Backend ───────────────────────────────────────────────────────────────────
# Default to Render production URL; override in .env for local dev
BACKEND_BASE_URL = os.getenv("BACKEND_BASE_URL", "https://sewabot-backend.onrender.com")

# ── Test mode ─────────────────────────────────────────────────────────────────
# Set TEST_MODE=true in CI to bypass Gemini and use deterministic responses
TEST_MODE = os.getenv("TEST_MODE", "false").lower() == "true"
