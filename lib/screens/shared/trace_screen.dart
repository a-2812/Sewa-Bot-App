import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/role_state.dart';

import '../../theme/app_theme.dart';
import '../../config/mock_data.dart';
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

class TraceViewerScreen extends StatefulWidget {
  const TraceViewerScreen({super.key});

  @override
  State<TraceViewerScreen> createState() => _TraceViewerScreenState();
}

class _TraceViewerScreenState extends State<TraceViewerScreen> {
  late Map<String, dynamic> _traceData;
  final Set<int> _expandedSteps = {0, 1, 2, 3, 4}; // Expand all by default
  bool _showJson = true;

  final List<AgentData> _staticAgents = [
    AgentData(
      agentName: 'Agent 1: Data Collection',
      description: 'Collects raw user text input and identifies intent.',
      inputJson: '''{\n  "user_text": "I need a plumber to fix a leaking pipe in my kitchen."\n}''',
      outputJson: '''{\n  "intent": "service_request",\n  "category": "plumbing",\n  "urgency": "high",\n  "raw_text": "I need a plumber to fix a leaking pipe in my kitchen."\n}''',
    ),
    AgentData(
      agentName: 'Agent 2: Entity Extraction',
      description: 'Extracts specific entities from the parsed intent data.',
      inputJson: '''{\n  "intent": "service_request",\n  "category": "plumbing",\n  "urgency": "high",\n  "raw_text": "I need a plumber to fix a leaking pipe in my kitchen."\n}''',
      outputJson: '''{\n  "service": "Plumber",\n  "issue": "Leaking pipe",\n  "location_context": "kitchen",\n  "urgency_score": 0.9\n}''',
    ),
    AgentData(
      agentName: 'Agent 3: Provider Matching',
      description: 'Finds available providers based on the extracted entities.',
      inputJson: '''{\n  "service": "Plumber",\n  "issue": "Leaking pipe",\n  "location_context": "kitchen",\n  "urgency_score": 0.9\n}''',
      outputJson: '''{\n  "matched_providers": [\n    {"id": "p_101", "name": "Ali Plumbing", "rating": 4.8, "distance_km": 2.5},\n    {"id": "p_105", "name": "Quick Fix Services", "rating": 4.5, "distance_km": 3.1}\n  ],\n  "estimated_cost_range": "Rs. 1500 - 3000"\n}''',
    ),
    AgentData(
      agentName: 'Agent 4: Pricing Estimator',
      description: 'Calculates an accurate quote based on provider rates and issue severity.',
      inputJson: '''{\n  "matched_providers": [\n    {"id": "p_101", "name": "Ali Plumbing", "rating": 4.8, "distance_km": 2.5},\n    {"id": "p_105", "name": "Quick Fix Services", "rating": 4.5, "distance_km": 3.1}\n  ],\n  "estimated_cost_range": "Rs. 1500 - 3000"\n}''',
      outputJson: '''{\n  "selected_provider": {"id": "p_101", "name": "Ali Plumbing"},\n  "final_quote": {\n    "base_fee": 1000,\n    "labor_estimated": 1500,\n    "total": 2500,\n    "currency": "PKR"\n  }\n}''',
    ),
    AgentData(
      agentName: 'Agent 5: Response Generation',
      description: 'Formats the final data into a user-friendly response.',
      inputJson: '''{\n  "selected_provider": {"id": "p_101", "name": "Ali Plumbing"},\n  "final_quote": {\n    "base_fee": 1000,\n    "labor_estimated": 1500,\n    "total": 2500,\n    "currency": "PKR"\n  }\n}''',
      outputJson: '''{\n  "display_message": "We found Ali Plumbing near you! The estimated cost to fix your leaking pipe is Rs. 2500. Would you like to book them now?",\n  "action_required": "user_confirmation"\n}''',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _traceData = MockData.masterTrace;
  }

  @override
  Widget build(BuildContext context) {
    final roleState = context.watch<RoleState>();
    final accent = roleState.primaryColor;
    final isProvider = roleState.isProvider;

    final title = isProvider ? 'Job Match Reasoning' : 'Agent Reasoning Trace';
    final subtitle = isProvider ? 'AI ne aapko kyun choose kiya' : 'Dekhen AI ne kya socha';
    final agentRuns = (_traceData['agent_runs'] as List?) ?? [];
    final totalLatency = _traceData['total_latency_ms'] ?? 0;
    final traceId = _traceData['trace_id'] ?? 'N/A';
    final cost = _traceData['cost_estimate'] as Map<String, dynamic>? ?? {};
    final baseline = _traceData['baseline_comparison'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      backgroundColor: isProvider ? AppTheme.providerBackground : AppTheme.userBackground,
      appBar: AppBar(
        backgroundColor: accent,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text('TR-$traceId', style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
        ]),
        actions: [
          IconButton(
            icon: Icon(_showJson ? Icons.timeline : Icons.code, color: Colors.white),
            onPressed: () => setState(() => _showJson = !_showJson),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [accent.withValues(alpha: 0.2), accent.withValues(alpha: 0.05)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.psychology, color: accent, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(subtitle, style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w500))),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _miniStat('Agents', '${agentRuns.length}', accent),
                const SizedBox(width: 8),
                _miniStat('Latency', '${(totalLatency / 1000).toStringAsFixed(1)}s', accent),
                const SizedBox(width: 8),
                _miniStat('Cost', '${cost['cost_pkr_approximate'] ?? '—'} PKR', accent),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // Agent runs timeline
          ...List.generate(_staticAgents.length, (i) {
            return _buildAgentStep(_staticAgents[i], i, _staticAgents.length, accent, isProvider);
          }),
          const SizedBox(height: 20),

          // Cost breakdown
          if (cost.isNotEmpty) ...[
            Text('Cost Breakdown', style: TextStyle(color: accent, fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isProvider ? AppTheme.providerInputFill : AppTheme.userInputFill,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(children: [
                _costRow('Gemini Tokens', '${cost['gemini_tokens_used'] ?? 0}', accent),
                _costRow('Gemini Cost', '\$${cost['gemini_cost_usd'] ?? 0}', accent),
                _costRow('Firestore Reads', '${cost['firestore_reads'] ?? 0}', accent),
                _costRow('Firestore Writes', '${cost['firestore_writes'] ?? 0}', accent),
                const Divider(color: AppTheme.textMuted, height: 16),
                _costRow('Total Cost', 'PKR ${cost['cost_pkr_approximate'] ?? 0}', accent, bold: true),
              ]),
            ),
          ],
          const SizedBox(height: 16),

          // Baseline comparison
          if (baseline.isNotEmpty) ...[
            Text('AI vs Traditional', style: TextStyle(color: accent, fontSize: 15, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isProvider ? AppTheme.providerInputFill : AppTheme.userInputFill,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.2)),
              ),
              child: Column(children: [
                _compareRow('Time', '${baseline['traditional_time']}', '${baseline['agentic_time_seconds']}s', AppTheme.success, accent),
                _compareRow('Match Factors', '${baseline['matching_factors_traditional']}', '${baseline['matching_factors_agentic']}', AppTheme.success, accent),
                _compareRow('Price Transparency', 'None', '${baseline['price_transparency'] ?? 'Full'}', AppTheme.success, accent),
                _compareRow('Follow-up', 'Manual', '${baseline['follow_up'] ?? 'Automated'}', AppTheme.success, accent),
              ]),
            ),
          ],
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _buildAgentStep(AgentData agent, int index, int total, Color accent, bool isProvider) {
    final isExpanded = _expandedSteps.contains(index);

    return Column(children: [
      // Timeline connector
      if (index > 0) Container(width: 2, height: 16, color: Colors.grey.shade800, margin: const EdgeInsets.only(left: 15)),

      GestureDetector(
        onTap: () => setState(() => isExpanded ? _expandedSteps.remove(index) : _expandedSteps.add(index)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.black, // Black theme
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800, width: 1), // Black theme border
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header row
            Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade900),
                alignment: Alignment.center,
                child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(agent.agentName, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                Text(agent.description, style: TextStyle(color: Colors.grey.shade300, fontSize: 11)),
              ])),
              Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey.shade400, size: 20),
            ]),

            // Expanded content (Inputs and Outputs)
            if (isExpanded) ...[
              const SizedBox(height: 16),
              _buildJsonBox('Input JSON', agent.inputJson, false),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Center(child: Icon(Icons.arrow_downward, color: Colors.grey)),
              ),
              _buildJsonBox('Output JSON', agent.outputJson, true),
            ],
          ]),
        ),
      ),

      // Bottom connector
      if (index < total - 1) Container(width: 2, height: 16, color: Colors.grey.shade800, margin: const EdgeInsets.only(left: 15)),
    ]);
  }

  Widget _buildJsonBox(String title, String jsonString, bool isOutput) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black, // Black background for JSON
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
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
              color: Colors.grey.shade300,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            jsonString,
            style: GoogleFonts.firaCode(
              fontSize: 12,
              color: Colors.grey.shade200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color accent) {
    return Expanded(child: Column(children: [
      Text(value, style: TextStyle(color: accent, fontSize: 14, fontWeight: FontWeight.w600)),
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
    ]));
  }

  Widget _costRow(String label, String value, Color accent, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
        Text(value, style: TextStyle(color: bold ? accent : const Color(0xFF111827), fontSize: bold ? 14 : 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w400)),
      ]),
    );
  }

  Widget _compareRow(String label, String trad, String ai, Color winColor, Color accent) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(width: 100, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11))),
        Expanded(child: Text(trad, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11), textAlign: TextAlign.center)),
        const Text(' → ', style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        Expanded(child: Text(ai, style: TextStyle(color: winColor, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
      ]),
    );
  }
}
