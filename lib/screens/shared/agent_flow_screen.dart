import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AgentData {
  final String agentName;
  final String description;
  final String inputJson;
  final String outputJson;

  AgentData({
    required this.agentName,
    required this.description,
    required this.inputJson,
    required this.outputJson,
  });
}

class AgentFlowScreen extends StatelessWidget {
  AgentFlowScreen({super.key});

  final List<AgentData> agents = [
    AgentData(
      agentName: 'Agent 1: Data Collection',
      description: 'Collects raw user text input and identifies intent.',
      inputJson: '''{
  "user_text": "I need a plumber to fix a leaking pipe in my kitchen."
}''',
      outputJson: '''{
  "intent": "service_request",
  "category": "plumbing",
  "urgency": "high",
  "raw_text": "I need a plumber to fix a leaking pipe in my kitchen."
}''',
    ),
    AgentData(
      agentName: 'Agent 2: Entity Extraction',
      description: 'Extracts specific entities from the parsed intent data.',
      inputJson: '''{
  "intent": "service_request",
  "category": "plumbing",
  "urgency": "high",
  "raw_text": "I need a plumber to fix a leaking pipe in my kitchen."
}''',
      outputJson: '''{
  "service": "Plumber",
  "issue": "Leaking pipe",
  "location_context": "kitchen",
  "urgency_score": 0.9
}''',
    ),
    AgentData(
      agentName: 'Agent 3: Provider Matching',
      description: 'Finds available providers based on the extracted entities.',
      inputJson: '''{
  "service": "Plumber",
  "issue": "Leaking pipe",
  "location_context": "kitchen",
  "urgency_score": 0.9
}''',
      outputJson: '''{
  "matched_providers": [
    {"id": "p_101", "name": "Ali Plumbing", "rating": 4.8, "distance_km": 2.5},
    {"id": "p_105", "name": "Quick Fix Services", "rating": 4.5, "distance_km": 3.1}
  ],
  "estimated_cost_range": "Rs. 1500 - 3000"
}''',
    ),
    AgentData(
      agentName: 'Agent 4: Pricing Estimator',
      description: 'Calculates an accurate quote based on provider rates and issue severity.',
      inputJson: '''{
  "matched_providers": [
    {"id": "p_101", "name": "Ali Plumbing", "rating": 4.8, "distance_km": 2.5},
    {"id": "p_105", "name": "Quick Fix Services", "rating": 4.5, "distance_km": 3.1}
  ],
  "estimated_cost_range": "Rs. 1500 - 3000"
}''',
      outputJson: '''{
  "selected_provider": {"id": "p_101", "name": "Ali Plumbing"},
  "final_quote": {
    "base_fee": 1000,
    "labor_estimated": 1500,
    "total": 2500,
    "currency": "PKR"
  }
}''',
    ),
    AgentData(
      agentName: 'Agent 5: Response Generation',
      description: 'Formats the final data into a user-friendly response.',
      inputJson: '''{
  "selected_provider": {"id": "p_101", "name": "Ali Plumbing"},
  "final_quote": {
    "base_fee": 1000,
    "labor_estimated": 1500,
    "total": 2500,
    "currency": "PKR"
  }
}''',
      outputJson: '''{
  "display_message": "We found Ali Plumbing near you! The estimated cost to fix your leaking pipe is Rs. 2500. Would you like to book them now?",
  "action_required": "user_confirmation"
}''',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Execution Flow'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: agents.length,
        itemBuilder: (context, index) {
          final agent = agents[index];
          final isLast = index == agents.length - 1;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Colors.black12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            child: Text('${index + 1}'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  agent.agentName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  agent.description,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildJsonBox('Input JSON', agent.inputJson),
                      const SizedBox(height: 12),
                      const Center(
                        child: Icon(Icons.arrow_downward, color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      _buildJsonBox('Output JSON', agent.outputJson, isOutput: true),
                    ],
                  ),
                ),
              ),
              if (!isLast)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Icon(Icons.arrow_downward, size: 32, color: Colors.black),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildJsonBox(String title, String jsonString, {bool isOutput = false}) {
    return Container(
      decoration: BoxDecoration(
        color: isOutput ? const Color(0xFFF0FDF4) : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isOutput ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isOutput ? Colors.green.shade800 : Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            jsonString,
            style: GoogleFonts.firaCode(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
