import sys
import os

# Mock google.generativeai so we don't need the pip package for this local unit test
import types
mock_genai = types.ModuleType("google.generativeai")
mock_genai.configure = lambda **kwargs: None
class MockModel:
    def generate_content(self, prompt):
        class Resp:
            text = "{}"
        return Resp()
mock_genai.GenerativeModel = lambda x: MockModel()

sys.modules["google"] = types.ModuleType("google")
sys.modules["google.generativeai"] = mock_genai

# Ensure we can import from agents directory
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

import orchestrator

def test_pipeline():
    user_input = "Mujhe kal subah G-13 mein AC technician chahiye"
    print(f"--- 1. Testing Intent, Discovery, Ranking ---")
    chat_result = orchestrator.run_chat(user_input)
    
    intent = chat_result.get("intent", {})
    print(f"Intent Service: {intent.get('service_type')}")
    print(f"Intent Location: {intent.get('location')}")
    print(f"Intent Time: {intent.get('preferred_time')}")
    
    options = chat_result.get("options", [])
    print(f"\nDiscovered Providers: {len(options)}")
    if not options:
        print("FAILED: No providers found.")
        return
        
    top_provider = options[0]
    print(f"Top Provider: {top_provider.get('provider_name')}")
    print(f"Score: {top_provider.get('total_score')}")
    print(f"Why Chosen: {top_provider.get('why_chosen')}")
    print(f"Quote (Price PKR): {top_provider.get('price_pkr')}")
    
    session_id = chat_result.get("session_id")
    provider_id = top_provider.get("provider_id")
    slot = top_provider.get("matched_slot", "10:00")
    
    print(f"\n--- 2. Testing Booking & Followup ---")
    book_result = orchestrator.run_book(session_id, provider_id, slot)
    
    booking = book_result.get("booking", {})
    print(f"Booking ID: {booking.get('booking_id')}")
    print(f"Status: {booking.get('status')}")
    
    receipt = book_result.get("receipt")
    print(f"Receipt Generated: {'Yes' if receipt else 'No'}")
    if receipt:
        print(receipt)
        
    followups = book_result.get("followups", [])
    print(f"\nNotifications Scheduled: {len(followups)}")
    for f in followups:
        print(f"- [{f.get('type')}] -> {f.get('recipient')} ({f.get('channel')})")

    # Verify agent logs
    print(f"\n--- 3. Trace Logs ---")
    agent_logs = book_result.get("agent_log", [])
    agents_run = [log.get("agent") for log in agent_logs]
    print(f"Agents Executed: {', '.join(agents_run)}")

if __name__ == "__main__":
    test_pipeline()
