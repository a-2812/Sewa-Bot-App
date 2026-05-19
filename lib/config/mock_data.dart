/// Complete mock data for KhidmatAI demo mode
class MockData {
  // ─── Intent Response ───────────────────────────────────────
  static Map<String, dynamic> intentResponse = {
    "intent": {
      "service_type": "AC repair",
      "location": "G-13, Islamabad",
      "preferred_time": "tomorrow_morning",
      "urgency": "high",
      "budget_sensitivity": "high",
      "job_complexity": "intermediate",
      "language_detected": "roman_urdu",
      "confidence_score": 0.91,
      "clarification_needed": false,
      "clarification_question": null,
      "raw_input": "AC bilkul kaam nahi kar raha"
    },
    "workplan": {
      "task": "Find and book AC repair in G-13",
      "steps": [
        "Extract service details from Roman Urdu input",
        "Query AC technicians available in G-13 area",
        "Score and rank providers on 8 factors",
        "Generate transparent price quote",
        "Execute booking and send confirmations"
      ]
    },
    "agent_trace": {
      "agent_name": "intent_extraction_agent",
      "sequence": 1,
      "observations":
          "User wrote in Roman Urdu. Key signals: 'bilkul kaam nahi' indicates complete failure (high urgency). Location G-13 clearly stated. No budget amount given but 'zyada nahi' phrase signals budget sensitivity.",
      "reasoning":
          "Parsed service_type=AC repair from context. Urgency=high from 'bilkul kaam nahi'. Budget sensitivity=high from implied constraint. Confidence 91% as all key fields extracted.",
      "latency_ms": 820,
      "status": "success"
    }
  };

  // ─── Providers Response ────────────────────────────────────
  static List<Map<String, dynamic>> providersResponse = [
    {
      "rank": 1,
      "provider_id": "p001",
      "provider_name": "Ahmed AC Services",
      "area": "G-13",
      "distance_km": 1.2,
      "rating": 4.7,
      "review_count": 89,
      "on_time_score": 0.92,
      "cancellation_rate": 0.05,
      "price_tier": "medium",
      "is_verified": true,
      "experience_years": 8,
      "total_score": 82.4,
      "score_breakdown": {
        "distance_score": 15.2,
        "rating_score": 18.8,
        "reliability_score": 13.8,
        "cancellation_penalty": -0.75,
        "specialization_score": 15.0,
        "availability_score": 15.0,
        "recency_score": 8.4,
        "budget_fit_score": 5.0
      },
      "why_chosen":
          "Ahmed scores highest at 82.4/100 due to AC specialization, 92% on-time rate, and strong recent reviews. Reliable choice despite not being the closest option.",
      "why_over_rank_2":
          "Ali is 0.4km closer but has 35% cancellation rate and no AC specialization. Ahmed's reliability score (13.8) far exceeds Ali's (10.7).",
      "agent_trace": {
        "agent_name": "provider_matching_agent",
        "sequence": 2,
        "observations": {
          "total_providers_found": 7,
          "providers_in_area": 4,
          "providers_available_at_time": 3,
          "providers_specialized": 2,
          "conflicts_detected": [
            "Closest provider (Ali Quick Fix) has 35% cancellation rate"
          ],
          "conflict_resolutions": [
            "Prioritizing reliability over proximity - cancellation rate penalty applied"
          ]
        },
        "reasoning":
            "Found 7 providers in G-13 area. Applied 8-factor scoring. Critical conflict: Ali Quick Fix is closest at 0.8km but cancellation_rate=0.35 results in -5.25 penalty, dropping score to 51.3. Ahmed AC Services scores 82.4 due to specialization match, reliability, and availability.",
        "tool_calls": [
          {
            "tool": "firestore_query",
            "output": "7 providers returned",
            "latency_ms": 145
          },
          {
            "tool": "distance_calculator",
            "output": "Distances calculated for 7 providers",
            "latency_ms": 312
          }
        ],
        "latency_ms": 1240,
        "status": "success"
      }
    },
    {
      "rank": 2,
      "provider_id": "p003",
      "provider_name": "Hassan Cooling Solutions",
      "area": "G-12",
      "distance_km": 2.1,
      "rating": 4.5,
      "review_count": 156,
      "on_time_score": 0.88,
      "cancellation_rate": 0.08,
      "price_tier": "medium",
      "is_verified": true,
      "experience_years": 11,
      "total_score": 74.1,
      "score_breakdown": {
        "distance_score": 11.6,
        "rating_score": 18.0,
        "reliability_score": 13.2,
        "cancellation_penalty": -1.2,
        "specialization_score": 15.0,
        "availability_score": 15.0,
        "recency_score": 7.5,
        "budget_fit_score": 5.0
      },
      "why_chosen":
          "Strong backup option with 156 reviews and 11 years experience. Slightly farther but very reliable.",
      "agent_trace": null
    },
    {
      "rank": 3,
      "provider_id": "p002",
      "provider_name": "Ali Quick Fix",
      "area": "G-13",
      "distance_km": 0.8,
      "rating": 3.9,
      "review_count": 34,
      "on_time_score": 0.71,
      "cancellation_rate": 0.35,
      "price_tier": "budget",
      "is_verified": false,
      "experience_years": 3,
      "total_score": 51.3,
      "score_breakdown": {
        "distance_score": 16.8,
        "rating_score": 15.6,
        "reliability_score": 10.7,
        "cancellation_penalty": -5.25,
        "specialization_score": 7.0,
        "availability_score": 7.0,
        "recency_score": 4.5,
        "budget_fit_score": 10.0
      },
      "why_chosen":
          "Closest provider but AI ranked lowest due to high cancellation rate and lack of AC specialization.",
      "warning":
          "⚠ 35% cancellation rate — AI ranked lower despite closest distance",
      "agent_trace": null
    }
  ];

  // ─── Quote Response ────────────────────────────────────────
  static Map<String, dynamic> quoteResponse = {
    "quote": {
      "base_fee": 500,
      "complexity_charge": 150,
      "urgency_surcharge": 243,
      "distance_charge": 0,
      "loyalty_discount": 0,
      "surge_applied": false,
      "surge_reason": null,
      "total_quoted_pkr": 893,
      "price_breakdown_text":
          "Base 500 + Complexity (×1.3) + Urgency (×1.35) = 893 PKR",
      "fairness_note":
          "Provider earns fair rate for specialized work. User pays market rate for urgent AC repair with no hidden charges."
    },
    "budget_alternative": {
      "available": true,
      "alternative_price_pkr": 661,
      "how_to_achieve":
          "Book for non-urgent slot (tomorrow afternoon) to remove 35% urgency surcharge",
      "tradeoff": "Wait 4-6 more hours for service"
    },
    "agent_trace": {
      "agent_name": "pricing_agent",
      "sequence": 3,
      "observations":
          "Service complexity: intermediate (complete AC failure). Urgency: high. Distance: 1.2km (under 3km free threshold). First booking — no loyalty discount.",
      "reasoning":
          "Base fee 500 PKR for AC repair. Complexity multiplier 1.3x adds 150. Urgency multiplier 1.35x adds 243. No distance charge (under 3km). No loyalty discount (first booking). No surge conditions detected.",
      "calculation_steps": [
        "Base fee: 500 PKR",
        "Complexity (intermediate × 1.3): +150 PKR",
        "Urgency (high × 1.35): +243 PKR",
        "Distance (1.2km, under 3km threshold): +0 PKR",
        "Provider tier (medium × 1.0): no adjustment",
        "Loyalty discount (first booking): -0 PKR",
        "Surge check: no surge conditions → no surcharge",
        "Total: 893 PKR"
      ],
      "latency_ms": 640,
      "status": "success"
    }
  };

  // ─── Booking Response ──────────────────────────────────────
  static Map<String, dynamic> bookingResponse = {
    "booking_confirmation": {
      "booking_id": "BK-20260518-001",
      "provider_name": "Ahmed AC Services",
      "service_type": "AC repair",
      "confirmed_slot": "Tomorrow, 10:00 AM",
      "location": "G-13, Islamabad",
      "total_price_pkr": 893,
      "user_message":
          "Booking Confirmed! AC repair booked with Ahmed AC Services for tomorrow 10:00 AM at G-13, Islamabad. Estimated cost: PKR 893. Booking ID: BK-20260518-001. Provider will arrive within 30 mins of slot time.",
      "provider_message":
          "📋 New Job: AC repair at G-13 on tomorrow 10:00 AM. Quoted: PKR 893. Accept within 15 minutes.",
      "reminders_scheduled": [
        "Tomorrow 9:00 AM — Service reminder for user",
        "Tomorrow 8:00 AM — Job reminder for provider",
        "Tomorrow 1:00 PM — Feedback request"
      ],
      "status": "confirmed"
    },
    "agent_trace": {
      "agent_name": "booking_execution_agent",
      "sequence": 4,
      "observations":
          "Slot tomorrow_morning available for Ahmed AC Services. No conflicts found in booking database.",
      "actions_executed": [
        {
          "step": 1,
          "action": "slot_conflict_check",
          "result": "no_conflict",
          "latency_ms": 145
        },
        {
          "step": 2,
          "action": "booking_record_created",
          "booking_id": "BK-20260518-001",
          "result": "success",
          "latency_ms": 312
        },
        {
          "step": 3,
          "action": "user_confirmation_generated",
          "result": "success",
          "latency_ms": 89
        },
        {
          "step": 4,
          "action": "provider_notified",
          "result": "success",
          "latency_ms": 76
        },
        {
          "step": 5,
          "action": "reminders_scheduled",
          "count": 3,
          "result": "success",
          "latency_ms": 98
        }
      ],
      "error_recovery": null,
      "total_latency_ms": 1180,
      "status": "success"
    }
  };

  // ─── Master Trace ──────────────────────────────────────────
  static Map<String, dynamic> masterTrace = {
    "trace_id": "TR-20260518-001",
    "session_id": "DEMO-SESSION",
    "timestamp_start": "2026-05-18T10:23:00Z",
    "timestamp_end": "2026-05-18T10:23:05Z",
    "total_latency_ms": 4521,
    "user_input":
        "AC bilkul kaam nahi kar raha, kal subah G-13 mein technician chahiye",
    "agent_runs": [
      {
        "agent_name": "intent_extraction_agent",
        "sequence": 1,
        "status": "success",
        "latency_ms": 820,
        "observations":
            "User wrote in Roman Urdu. Key signals: 'bilkul kaam nahi' indicates complete failure.",
        "reasoning":
            "Parsed service_type=AC repair. Urgency=high. Confidence 91%.",
      },
      {
        "agent_name": "provider_matching_agent",
        "sequence": 2,
        "status": "success",
        "latency_ms": 1240,
        "observations": "Found 7 providers. Applied 8-factor scoring.",
        "reasoning":
            "Ahmed AC Services scores 82.4/100. Ali Quick Fix penalized for 35% cancellation rate.",
      },
      {
        "agent_name": "pricing_agent",
        "sequence": 3,
        "status": "success",
        "latency_ms": 640,
        "observations":
            "Intermediate complexity. High urgency. Under 3km distance.",
        "reasoning": "Base 500 + Complexity 150 + Urgency 243 = 893 PKR.",
      },
      {
        "agent_name": "booking_execution_agent",
        "sequence": 4,
        "status": "success",
        "latency_ms": 1180,
        "observations": "Slot available. No conflicts.",
        "reasoning":
            "5 steps executed successfully. Booking BK-20260518-001 confirmed.",
      },
    ],
    "final_outcome": {
      "booking_confirmed": true,
      "booking_id": "BK-20260518-001",
      "provider_assigned": "Ahmed AC Services",
      "total_price_pkr": 893,
      "edge_case_triggered": null,
      "recovery_applied": false
    },
    "cost_estimate": {
      "gemini_tokens_used": 2847,
      "gemini_cost_usd": 0.00285,
      "firestore_reads": 12,
      "firestore_writes": 5,
      "total_cost_usd": 0.00612,
      "cost_pkr_approximate": 1.71
    },
    "baseline_comparison": {
      "traditional_time": "15-30 minutes",
      "agentic_time_seconds": 4.5,
      "matching_factors_traditional": 2,
      "matching_factors_agentic": 8,
      "price_transparency": "Full itemized breakdown vs none",
      "follow_up": "3 automated touchpoints vs manual"
    }
  };
}
