import json
import os

path = "d:/Sewabot frontend/Sewa-Bot-App-backend/data/providers.json"
with open(path, "r", encoding="utf-8") as f:
    data = json.load(f)

new_providers = [
    {
        "id": "p031", "name": "Haider Washing Machine Expert", "service_type": "Washing Machine Repair",
        "location": { "area": "Madina Syedan", "city": "Gujrat", "lat": 32.5711, "lng": 74.0750 },
        "rating": 4.8, "price": 1000, "verified": True, "phone": "+92-300-1112233",
        "available_slots": ["09:00", "11:00", "13:00", "16:00"],
        "experience_years": 10, "review_count": 210, "on_time_score": 0.95, "price_tier": "Standard"
    },
    {
        "id": "p032", "name": "Ali Master Plumber", "service_type": "Plumber",
        "location": { "area": "Model Town", "city": "Lahore", "lat": 31.4820, "lng": 74.3255 },
        "rating": 4.6, "price": 800, "verified": True, "phone": "+92-321-4455667",
        "available_slots": ["10:00", "14:00"],
        "experience_years": 7, "review_count": 140, "on_time_score": 0.89, "price_tier": "Budget"
    },
    {
        "id": "p033", "name": "Kamran Electrician", "service_type": "Electrician",
        "location": { "area": "DHA Phase 5", "city": "Lahore", "lat": 31.4720, "lng": 74.4120 },
        "rating": 4.9, "price": 2000, "verified": True, "phone": "+92-333-8899001",
        "available_slots": ["08:00", "12:00", "18:00"],
        "experience_years": 12, "review_count": 320, "on_time_score": 0.98, "price_tier": "Premium"
    },
    {
        "id": "p034", "name": "Gujrat Electric & Repair", "service_type": "Electrician",
        "location": { "area": "Star Colony", "city": "Gujrat", "lat": 32.5721, "lng": 74.0761 },
        "rating": 4.5, "price": 1200, "verified": False, "phone": "+92-345-6677889",
        "available_slots": ["09:00", "15:00"],
        "experience_years": 4, "review_count": 55, "on_time_score": 0.85, "price_tier": "Budget"
    },
    {
        "id": "p035", "name": "Farhan Appliances Repair", "service_type": "Washing Machine Repair",
        "location": { "area": "Satellite Town", "city": "Rawalpindi", "lat": 33.6334, "lng": 73.0694 },
        "rating": 4.7, "price": 1500, "verified": True, "phone": "+92-300-9988776",
        "available_slots": ["11:00", "16:00"],
        "experience_years": 6, "review_count": 180, "on_time_score": 0.91, "price_tier": "Standard"
    },
    {
        "id": "p036", "name": "Ahmed Carpenter", "service_type": "Carpenter",
        "location": { "area": "G-13", "city": "Islamabad", "lat": 33.6521, "lng": 72.9691 },
        "rating": 4.4, "price": 1500, "verified": True, "phone": "+92-333-1231234",
        "available_slots": ["10:00", "14:00"],
        "experience_years": 8, "review_count": 125, "on_time_score": 0.88, "price_tier": "Standard"
    },
    {
        "id": "p037", "name": "Gujrat Washing Machine Specialist", "service_type": "Washing Machine Repair",
        "location": { "area": "Jalalpur Jattan Road", "city": "Gujrat", "lat": 32.6100, "lng": 74.1100 },
        "rating": 4.9, "price": 800, "verified": True, "phone": "+92-311-5556667",
        "available_slots": ["10:00", "12:00", "15:00"],
        "experience_years": 15, "review_count": 405, "on_time_score": 0.97, "price_tier": "Budget"
    }
]

data.extend(new_providers)
with open(path, "w", encoding="utf-8") as f:
    json.dump(data, f, indent=2)

print(f"Successfully added {len(new_providers)} new providers.")
