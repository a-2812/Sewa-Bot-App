import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../providers/role_state.dart';
import '../../theme/app_theme.dart';
import '../../services/agent_service.dart';
import 'package:google_fonts/google_fonts.dart';

class TraceViewerScreen extends StatefulWidget {
  const TraceViewerScreen({super.key});

  @override
  State<TraceViewerScreen> createState() => _TraceViewerScreenState();
}

class _TraceViewerScreenState extends State<TraceViewerScreen> {
  final Set<int> _expandedSteps = {0, 1, 2, 3, 4};
  bool _isRefreshing = false;

  // Agent icons by name
  IconData _agentIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('intent'))    return Icons.psychology_rounded;
    if (n.contains('discovery')) return Icons.search_rounded;
    if (n.contains('ranking'))   return Icons.leaderboard_rounded;
    if (n.contains('booking'))   return Icons.calendar_today_rounded;
    if (n.contains('followup') || n.contains('follow')) return Icons.notifications_active_rounded;
    return Icons.smart_toy_rounded;
  }

  Color _agentColor(int index, Color accent) {
    final colors = [
      const Color(0xFF6C63FF),
      const Color(0xFF00BCD4),
      const Color(0xFFFF9800),
      const Color(0xFF4CAF50),
      const Color(0xFFE91E63),
    ];
    return colors[index % colors.length];
  }

  Future<void> _refreshLogs(BuildContext context, AppState appState) async {
    setState(() => _isRefreshing = true);
    final result = await AgentService.getAgentLogs(appState.sessionId);
    if (!mounted) return;
    setState(() => _isRefreshing = false);
    if (!result.containsKey('error')) {
      final flow = result['flow'] as List? ?? [];
      appState.setAgentLog(flow);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roleState = context.watch<RoleState>();
    final appState  = context.watch<AppState>();
    final accent    = roleState.primaryColor;
    final isProvider = roleState.isProvider;

    final agentLog = appState.agentLog;
    final sessionId = appState.sessionId;
    final bookingId = appState.bookingId ?? '—';

    final title    = isProvider ? 'Job Match Reasoning' : 'Agent Reasoning Trace';
    final subtitle = isProvider ? 'AI ne aapko kyun choose kiya' : 'Dekhen AI ne kya socha';

    // Sum up total latency
    int totalMs = 0;
    for (final step in agentLog) {
      totalMs += (step['duration_ms'] as num? ?? 0).toInt();
    }

    return Scaffold(
      backgroundColor: isProvider ? AppTheme.providerBackground : AppTheme.userBackground,
      appBar: AppBar(
        backgroundColor: accent,
        leading: Navigator.canPop(context)
            ? Center(
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.4),
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(36, 36),
                    fixedSize: const Size(36, 36),
                    shape: const CircleBorder(),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              )
            : null,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          Text(bookingId == '—' ? sessionId.substring(0, 12) : 'BK: $bookingId',
              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
        ]),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => _refreshLogs(context, appState),
              tooltip: 'Refresh logs',
            ),
        ],
      ),
      body: agentLog.isEmpty
          ? _buildEmptyState(context, appState, accent)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── Header stats ───────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      accent.withValues(alpha: 0.2),
                      accent.withValues(alpha: 0.05)
                    ]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Icon(Icons.psychology, color: accent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(subtitle,
                              style: TextStyle(
                                  color: accent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500))),
                    ]),
                    const SizedBox(height: 10),
                    Row(children: [
                      _miniStat('Agents', '${agentLog.length}', accent),
                      const SizedBox(width: 8),
                      _miniStat(
                          'Latency', '${(totalMs / 1000).toStringAsFixed(1)}s', accent),
                      const SizedBox(width: 8),
                      _miniStat('Session', sessionId.substring(0, 8), accent),
                    ]),
                  ]),
                ),
                const SizedBox(height: 20),

                // ── Agent steps ────────────────────────────────────
                ...List.generate(agentLog.length, (i) {
                  return _buildAgentStep(agentLog[i], i, agentLog.length, accent);
                }),
                const SizedBox(height: 20),

                // ── AI vs Traditional comparison ───────────────────
                Text('AI vs Traditional',
                    style: TextStyle(
                        color: accent, fontSize: 15, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isProvider
                        ? AppTheme.providerInputFill
                        : AppTheme.userInputFill,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.2)),
                  ),
                  child: Column(children: [
                    _compareRow('Time to match', '~30 min', '${(totalMs / 1000).toStringAsFixed(1)}s', AppTheme.success),
                    _compareRow('Match factors', '1–2', '${agentLog.length * 3}+', AppTheme.success),
                    _compareRow('Transparency', 'None', 'Full trace', AppTheme.success),
                    _compareRow('Follow-up', 'Manual', 'Automated', AppTheme.success),
                    _compareRow('Languages', 'One', 'Urdu/Roman/EN', AppTheme.success),
                  ]),
                ),
                const SizedBox(height: 32),
              ]),
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppState appState, Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.psychology_outlined, color: AppTheme.textMuted, size: 64),
          const SizedBox(height: 16),
          const Text('No agent trace yet',
              style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text(
            'Start a service request in the Chat screen to see the AI reasoning steps here.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _refreshLogs(context, appState),
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(backgroundColor: accent),
          ),
        ]),
      ),
    );
  }

  Widget _buildAgentStep(Map<String, dynamic> step, int index, int total, Color accent) {
    final isExpanded = _expandedSteps.contains(index);
    final agentName = step['agent'] as String? ?? 'Agent ${index + 1}';
    final reasoning = step['reasoning'] as String? ?? '';
    final statusStr = step['status'] as String? ?? 'success';
    final durationMs = (step['duration_ms'] as num? ?? 0).toInt();
    final isSuccess = statusStr == 'success';
    final color = _agentColor(index, accent);

    // Format input and output as pretty JSON
    String inputJson  = '';
    String outputJson = '';
    try {
      inputJson  = const JsonEncoder.withIndent('  ').convert(step['input']);
      outputJson = const JsonEncoder.withIndent('  ').convert(step['output']);
    } catch (_) {
      inputJson  = step['input']?.toString()  ?? '{}';
      outputJson = step['output']?.toString() ?? '{}';
    }

    return Column(children: [
      if (index > 0)
        Container(
            width: 2, height: 16, color: Colors.grey.shade800,
            margin: const EdgeInsets.only(left: 15)),

      GestureDetector(
        onTap: () => setState(() =>
            isExpanded ? _expandedSteps.remove(index) : _expandedSteps.add(index)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade800, width: 1),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.2)),
                alignment: Alignment.center,
                child: Icon(_agentIcon(agentName), color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(agentName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Row(children: [
                  Icon(isSuccess ? Icons.check_circle : Icons.error,
                      color: isSuccess ? AppTheme.success : AppTheme.danger,
                      size: 12),
                  const SizedBox(width: 4),
                  Text(
                    '${isSuccess ? "success" : "error"} • ${durationMs}ms',
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 11),
                  ),
                ]),
              ])),
              Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: Colors.grey.shade400,
                  size: 20),
            ]),

            // Reasoning (always visible)
            if (reasoning.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Text(reasoning,
                    style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 11,
                        height: 1.5)),
              ),
            ],

            // Expanded: Input + Output JSON
            if (isExpanded) ...[
              const SizedBox(height: 14),
              _buildJsonBox('Input', inputJson),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Center(
                    child: Icon(Icons.arrow_downward,
                        color: Colors.grey, size: 18)),
              ),
              _buildJsonBox('Output', outputJson),
            ],
          ]),
        ),
      ),

      if (index < total - 1)
        Container(
            width: 2, height: 16, color: Colors.grey.shade800,
            margin: const EdgeInsets.only(left: 15)),
    ]);
  }

  Widget _buildJsonBox(String title, String jsonStr) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade800),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade400)),
        const SizedBox(height: 6),
        Text(jsonStr,
            style: GoogleFonts.firaCode(
                fontSize: 11, color: Colors.grey.shade200)),
      ]),
    );
  }

  Widget _miniStat(String label, String value, Color accent) {
    return Expanded(
        child: Column(children: [
      Text(value,
          style: TextStyle(
              color: accent, fontSize: 14, fontWeight: FontWeight.w600)),
      Text(label,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
    ]));
  }

  Widget _compareRow(String label, String trad, String ai, Color winColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary, fontSize: 11))),
        Expanded(
            child: Text(trad,
                style:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 11),
                textAlign: TextAlign.center)),
        const Text(' → ',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 11)),
        Expanded(
            child: Text(ai,
                style: TextStyle(
                    color: winColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center)),
      ]),
    );
  }
}
