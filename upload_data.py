import json
from pathlib import Path
from firebase_config import get_firestore_client
import firebase_admin

_BASE = Path(__file__).parent
PROVIDERS_FILE = _BASE / "providers.json"

def upload_providers():
    if not PROVIDERS_FILE.exists():
        print(f"Error: {PROVIDERS_FILE} not found.")
        return
        
    print("Loading providers from local JSON...")
    with open(PROVIDERS_FILE, "r", encoding="utf-8") as f:
        raw_providers = json.load(f)
        
    print(f"Found {len(raw_providers)} providers. Initializing Firestore...")
    db = get_firestore_client()
    
    providers_ref = db.collection("providers")
    
    # Optional: Clear existing providers collection first to avoid duplicates
    # (Leaving this out for safety, but we use the provider's 'id' as the document ID anyway)
    
    print("Uploading providers...")
    batch = db.batch()
    count = 0
    
    for p in raw_providers:
        # Use the 'id' field as the document ID
        doc_id = p.get("id")
        if not doc_id:
            print("Skipping provider without ID:", p.get("name"))
            continue
            
        doc_ref = providers_ref.document(doc_id)
        batch.set(doc_ref, p)
        count += 1
        
        # Firestore batch limit is 500
        if count % 400 == 0:
            batch.commit()
            print(f"  Committed batch of {count}...")
            batch = db.batch()
            
    if count % 400 != 0:
        batch.commit()
        
    print(f"Successfully uploaded {count} providers to Firestore.")

if __name__ == "__main__":
    upload_providers()
