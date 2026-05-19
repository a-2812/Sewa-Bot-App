import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Manages real-time agent trace streaming from Firestore
class TraceState extends ChangeNotifier {
  // ─── Trace Data ────────────────────────────────────────────
  List<Map<String, dynamic>> _agentRuns = [];
  String? _traceId;
  int _totalLatencyMs = 0;
  bool _isStreaming = false;
  StreamSubscription? _subscription;

  List<Map<String, dynamic>> get agentRuns => _agentRuns;
  String? get traceId => _traceId;
  int get totalLatencyMs => _totalLatencyMs;
  bool get isStreaming => _isStreaming;

  // ─── Start Listening ───────────────────────────────────────
  void startListening(String sessionId) {
    // Cancel any existing subscription
    stopListening();

    _isStreaming = true;
    notifyListeners();

    try {
      _subscription = FirebaseFirestore.instance
          .collection('agent_traces')
          .where('session_id', isEqualTo: sessionId)
          .orderBy('timestamp_start', descending: true)
          .limit(1)
          .snapshots()
          .listen(
        (QuerySnapshot snapshot) {
          if (snapshot.docs.isNotEmpty) {
            final doc = snapshot.docs.first;
            final data = doc.data() as Map<String, dynamic>;

            _traceId = data['trace_id'] as String?;
            _totalLatencyMs = (data['total_latency_ms'] as num?)?.toInt() ?? 0;

            // Extract agent_runs array
            final runs = data['agent_runs'];
            if (runs is List) {
              _agentRuns = runs
                  .map((r) => Map<String, dynamic>.from(r as Map))
                  .toList();
            }

            notifyListeners();
          }
        },
        onError: (error) {
          debugPrint('TraceState stream error: $error');
          _isStreaming = false;
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('TraceState startListening error: $e');
      _isStreaming = false;
      notifyListeners();
    }
  }

  // ─── Stop Listening ────────────────────────────────────────
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isStreaming = false;
    notifyListeners();
  }

  // ─── Clear Trace ───────────────────────────────────────────
  void clearTrace() {
    _agentRuns = [];
    _traceId = null;
    _totalLatencyMs = 0;
    _isStreaming = false;
    _subscription?.cancel();
    _subscription = null;
    notifyListeners();
  }

  // ─── Load from local data (demo mode) ─────────────────────
  void loadFromData(Map<String, dynamic> traceData) {
    _traceId = traceData['trace_id'] as String?;
    _totalLatencyMs = (traceData['total_latency_ms'] as num?)?.toInt() ?? 0;

    final runs = traceData['agent_runs'];
    if (runs is List) {
      _agentRuns = runs
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
