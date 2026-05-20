"""
SewaBot — Dummy Account Seeder
================================
Creates Firebase Auth accounts + Firestore user records for testing.

Run once:
    python seed_accounts.py

Requirements:
    - FIREBASE_CREDENTIALS_JSON env var set (or firebase-key.json present)
    - firebase-admin installed
"""

import json
import os
import sys
from pathlib import Path

try:
    import firebase_admin
    from firebase_admin import auth, credentials, firestore
except ImportError:
    print("ERROR: firebase-admin not installed. Run: pip install firebase-admin")
    sys.exit(1)


# ── Init Firebase Admin ────────────────────────────────────────────────────────
def _init():
    try:
        firebase_admin.get_app()
        return
    except ValueError:
        pass

    creds_json = os.getenv("FIREBASE_CREDENTIALS_JSON", "").strip()
    if creds_json:
        cred = credentials.Certificate(json.loads(creds_json))
    else:
        local = Path(__file__).parent / "firebase-key.json"
        if local.exists():
            cred = credentials.Certificate(str(local))
        else:
            print("ERROR: No Firebase credentials found.")
            print("  Set FIREBASE_CREDENTIALS_JSON env var or place firebase-key.json here.")
            sys.exit(1)

    firebase_admin.initialize_app(cred)


# ── Account definitions ────────────────────────────────────────────────────────
DUMMY_USERS = [
    {
        "email":    "user.ali@sewabot.com",
        "password": "Test@1234",
        "name":     "Ali Hassan",
        "phone":    "+92-300-1111001",
        "address":  "F-7 Markaz, Islamabad",
        "role":     "user",
    },
    {
        "email":    "user.sara@sewabot.com",
        "password": "Test@1234",
        "name":     "Sara Khan",
        "phone":    "+92-300-1111002",
        "address":  "G-11 Markaz, Islamabad",
        "role":     "user",
    },
    {
        "email":    "user.ahmed@sewabot.com",
        "password": "Test@1234",
        "name":     "Ahmed Raza",
        "phone":    "+92-300-1111003",
        "address":  "DHA Phase 2, Lahore",
        "role":     "user",
    },
]

DUMMY_PROVIDERS = [
    {
        "email":      "provider.usman@sewabot.com",
        "password":   "Test@1234",
        "name":       "Usman Ali",
        "phone":      "+92-300-1234567",
        "address":    "F-10 Markaz, Islamabad",
        "role":       "provider",
        "provider_id": "p001",
        "specialty":  "AC Repair",
        "hourly_rate": 1500,
        "experience_years": 8,
        "bio":        "Expert AC technician with 8 years experience in Islamabad.",
        "is_approved": True,
    },
    {
        "email":      "provider.tariq@sewabot.com",
        "password":   "Test@1234",
        "name":       "Tariq Mehmood",
        "phone":      "+92-301-2345678",
        "address":    "G-11 Markaz, Islamabad",
        "role":       "provider",
        "provider_id": "p002",
        "specialty":  "AC Repair",
        "hourly_rate": 1200,
        "experience_years": 5,
        "bio":        "Budget-friendly AC technician, quick and reliable.",
        "is_approved": True,
    },
    {
        "email":      "provider.asif@sewabot.com",
        "password":   "Test@1234",
        "name":       "Asif Raza",
        "phone":      "+92-302-3456789",
        "address":    "Bahria Town Phase 4, Islamabad",
        "role":       "provider",
        "provider_id": "p006",
        "specialty":  "Plumbing",
        "hourly_rate": 1000,
        "experience_years": 6,
        "bio":        "Professional plumber for all types of pipe and drainage work.",
        "is_approved": True,
    },
    {
        "email":      "provider.kamran@sewabot.com",
        "password":   "Test@1234",
        "name":       "Kamran Hussain",
        "phone":      "+92-303-4567890",
        "address":    "DHA Phase 5, Lahore",
        "role":       "provider",
        "provider_id": "p004",
        "specialty":  "Electrical",
        "hourly_rate": 2000,
        "experience_years": 12,
        "bio":        "Senior electrician, specializes in home wiring and panel upgrades.",
        "is_approved": True,
    },
]


# ── Create or update a Firebase Auth account ──────────────────────────────────
def _upsert_auth_user(account: dict) -> str:
    """Create Firebase Auth user (or get existing). Returns UID."""
    try:
        user = auth.create_user(
            email=account["email"],
            password=account["password"],
            display_name=account["name"],
            phone_number=None,
        )
        print(f"  [Auth] Created:  {account['email']}  →  UID: {user.uid}")
        return user.uid
    except auth.EmailAlreadyExistsError:
        user = auth.get_user_by_email(account["email"])
        # Update password to ensure it matches our seed
        auth.update_user(user.uid, password=account["password"], display_name=account["name"])
        print(f"  [Auth] Exists:   {account['email']}  →  UID: {user.uid}")
        return user.uid


# ── Write Firestore user document ─────────────────────────────────────────────
def _upsert_firestore_user(uid: str, account: dict):
    db = firestore.client()
    doc_ref = db.collection("users").document(uid)
    data = {
        "uid":     uid,
        "name":    account["name"],
        "email":   account["email"].lower(),
        "phone":   account["phone"],
        "address": account["address"],
        "role":    account["role"],
    }
    # Provider-specific fields
    for field in ("provider_id", "specialty", "hourly_rate", "experience_years", "bio", "is_approved"):
        if field in account:
            data[field] = account[field]

    doc_ref.set(data, merge=True)
    print(f"  [FS]   Saved:    users/{uid}")


# ── Main ──────────────────────────────────────────────────────────────────────
def main():
    print("\n=== SewaBot Account Seeder ===\n")
    _init()

    all_accounts = DUMMY_USERS + DUMMY_PROVIDERS
    results = []

    for acc in all_accounts:
        print(f"Processing: {acc['email']} ({acc['role']})")
        uid = _upsert_auth_user(acc)
        _upsert_firestore_user(uid, acc)
        results.append({
            "email":    acc["email"],
            "password": acc["password"],
            "name":     acc["name"],
            "role":     acc["role"],
            "uid":      uid,
        })
        print()

    print("=== Done! ===\n")
    print("Test credentials:")
    print(f"{'Email':<40} {'Password':<15} {'Role':<10} Name")
    print("-" * 90)
    for r in results:
        print(f"{r['email']:<40} {r['password']:<15} {r['role']:<10} {r['name']}")

    # Save credentials to a local file for reference
    out_path = Path(__file__).parent / "seeded_accounts.json"
    with open(out_path, "w") as f:
        json.dump(results, f, indent=2)
    print(f"\nSaved to: {out_path}")


if __name__ == "__main__":
    main()
