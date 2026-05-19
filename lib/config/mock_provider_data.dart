/// Mock data for the service provider role
class MockProviderData {
  // ─── Incoming Jobs ─────────────────────────────────────────
  static List<Map<String, dynamic>> incomingJobsMock = [
    {
      "job_id": "JOB-20260518-001",
      "service_type": "AC repair",
      "user_name": "Ahmed K.",
      "location": "G-13, Street 4",
      "distance_km": 1.2,
      "slot": "Tomorrow 10:00 AM",
      "quoted_price": 893,
      "urgency": "high",
      "job_complexity": "intermediate",
      "time_to_accept": 900,
      "status": "pending",
      "ai_match_score": 94,
      "ai_reason":
          "You are the top match for this job based on your AC specialization and 92% on-time rate"
    },
    {
      "job_id": "JOB-20260518-002",
      "service_type": "AC maintenance",
      "user_name": "Sara M.",
      "location": "G-12, Block C",
      "distance_km": 2.4,
      "slot": "Tomorrow 2:00 PM",
      "quoted_price": 650,
      "urgency": "low",
      "job_complexity": "basic",
      "time_to_accept": 900,
      "status": "pending",
      "ai_match_score": 87,
      "ai_reason": "Routine maintenance job, matches your skill level"
    },
    {
      "job_id": "JOB-20260518-003",
      "service_type": "AC installation",
      "user_name": "Usman R.",
      "location": "G-11/2, Street 8",
      "distance_km": 3.5,
      "slot": "Today 4:00 PM",
      "quoted_price": 2200,
      "urgency": "medium",
      "job_complexity": "advanced",
      "time_to_accept": 600,
      "status": "pending",
      "ai_match_score": 78,
      "ai_reason":
          "Installation job — slightly outside your usual range but matches specialization"
    },
  ];

  // ─── Earnings Summary ──────────────────────────────────────
  static Map<String, dynamic> earningsMock = {
    "today": 1786.0,
    "this_week": 8940.0,
    "this_month": 34200.0,
    "total_jobs_today": 2,
    "total_jobs_week": 11,
    "total_jobs_month": 43,
    "rating": 4.7,
    "on_time_rate": 0.92,
    "acceptance_rate": 0.85,
    "weekly_data": [1200, 2400, 1800, 3200, 8940, 0, 0],
    "top_service": "AC repair",
    "peak_hours": "9 AM - 12 PM"
  };

  // ─── Active Job Mock ───────────────────────────────────────
  static Map<String, dynamic> activeJobMock = {
    "job_id": "JOB-20260517-005",
    "service_type": "AC repair",
    "user_name": "Bilal H.",
    "user_phone": "+92 300 1234567",
    "location": "G-13, Street 7, House 42",
    "distance_km": 0.8,
    "slot": "Today 2:00 PM",
    "quoted_price": 750,
    "urgency": "medium",
    "job_complexity": "basic",
    "status": "in_progress",
    "started_at": "2026-05-17T14:05:00Z",
    "notes": "Split AC, gas leak suspected",
  };

  // ─── Provider Profile Mock ─────────────────────────────────
  static Map<String, dynamic> profileMock = {
    "provider_id": "p001",
    "name": "Ahmed AC Services",
    "phone": "+92 312 9876543",
    "area": "G-13, Islamabad",
    "categories": ["AC repair", "AC installation", "AC maintenance"],
    "experience_years": 8,
    "rating": 4.7,
    "review_count": 89,
    "on_time_rate": 0.92,
    "cancellation_rate": 0.05,
    "is_verified": true,
    "joined_date": "2024-03-15",
    "total_jobs": 312,
    "total_earnings": 245000.0,
  };
}
