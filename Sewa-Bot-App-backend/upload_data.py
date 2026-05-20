"""
upload_data.py
--------------
Uploads providers.json to the Firestore 'providers' collection.

Usage:
    python upload_data.py              # upload all providers
    python upload_data.py --check      # only upload if collection is empty
"""

import json
import sys
from pathlib import Path
from firebase_config import get_firestore_client

_BASE = Path(__file__).parent
PROVIDERS_FILE = _BASE / "data" / "providers.json"


def upload_providers(check_first: bool = False) -> int:
    """Upload providers.json to Firestore. Returns number of docs written."""
    if not PROVIDERS_FILE.exists():
        print(f"[upload] ERROR: {PROVIDERS_FILE} not found.")
        return 0

    db = get_firestore_client()
    if db is None:
        print("[upload] ERROR: Firestore client unavailable — skipping upload.")
        return 0

    providers_ref = db.collection("providers")

    if check_first:
        # Only upload if the collection is empty (first-run / cold start)
        existing = list(providers_ref.limit(1).stream())
        if existing:
            print(f"[upload] Providers collection already populated — skipping.")
            return 0
        print("[upload] Providers collection is empty — uploading now...")

    print("[upload] Loading providers from local JSON...")
    with open(PROVIDERS_FILE, "r", encoding="utf-8") as f:
        raw_providers = json.load(f)

    print(f"[upload] Found {len(raw_providers)} providers. Writing to Firestore...")

    batch = db.batch()
    count = 0
    skipped = 0

    for p in raw_providers:
        doc_id = p.get("id")
        if not doc_id:
            print(f"[upload] Skipping provider without ID: {p.get('name')}")
            skipped += 1
            continue

        doc_ref = providers_ref.document(doc_id)
        batch.set(doc_ref, p)
        count += 1

        # Firestore batch limit is 500
        if count % 400 == 0:
            batch.commit()
            print(f"[upload]   Committed batch ({count} so far)...")
            batch = db.batch()

    if count % 400 != 0:
        batch.commit()

    print(f"[upload] Done. {count} providers uploaded, {skipped} skipped.")
    return count


def ensure_providers_in_firestore():
    """Called on Render startup — uploads providers only if Firestore is empty."""
    try:
        uploaded = upload_providers(check_first=True)
        if uploaded:
            print(f"[startup] Seeded {uploaded} providers into Firestore.")
    except Exception as e:
        print(f"[startup] Provider seed failed (non-fatal): {e}")


if __name__ == "__main__":
    check_only = "--check" in sys.argv
    upload_providers(check_first=check_only)
