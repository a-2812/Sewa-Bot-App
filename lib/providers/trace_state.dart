
import 'package:flutter/material.dart';

/// Manages agent trace state (previously used Firestore streaming).
/// Now reads from AgentService REST API — no Firebase dependency needed.
class TraceState extends ChangeNotifier {
  List<Map<String, dynamic>> _agentRuns = [];
  String? _traceId;
  int _totalLatencyMs = 0;
  bool _isStreaming = false;

  List<Map<String, dynamic>> get agentRuns => _agentRuns;
  String? get traceId => _traceId;
  int get totalLatencyMs => _totalLatencyMs;
  bool get isStreaming => _isStreaming;

  /// No-op — streaming now done via AgentService.getAgentLogs() in TraceViewerScreen.
  void startListening(String sessionId) {
    _isStreaming = true;
    notifyListeners();
  }

  void stopListening() {
    _isStreaming = false;
    notifyListeners();
  }

  void clearTrace() {
    _agentRuns = [];
    _traceId = null;
    _totalLatencyMs = 0;
    _isStreaming = false;
    notifyListeners();
  }

  void loadFromData(Map<String, dynamic> traceData) {
    _traceId = traceData['trace_id'] as String?;
    _totalLatencyMs = (traceData['total_latency_ms'] as num?)?.toInt() ?? 0;
    final runs = traceData['agent_runs'];
    if (runs is List) {
      _agentRuns = runs.map((r) => Map<String, dynamic>.from(r as Map)).toList();
    }
    notifyListeners();
  }


}
