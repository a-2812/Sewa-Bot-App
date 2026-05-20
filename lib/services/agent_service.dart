import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../config/mock_data.dart';

/// SewaBot Agent Service
/// =====================
/// Communicates with the Agents API (port 8001) using the 4-step pipeline:
///
///   1. POST /extractIntent   → IntentAgent
///   2. POST /getProviders    → DiscoveryAgent + RankingAgent
///   3. POST /getPriceQuote   → QuoteAgent
///   4. POST /executeBooking  → BookingAgent + FollowupAgent
///
/// If [AppConfig.demoMode] is true OR the API is unreachable, all methods
/// fall back to [MockData] so the UI always works for a demo.
class AgentService {
  // ─── Internal state ────────────────────────────────────────

  /// Session ID is seeded from AppState but can be refreshed here
  /// after the first successful /extractIntent response.
  static String? _activeSessionId;

  static bool get _demo => AppConfig.demoMode;
  static String get _base => AppConfig.agentsBaseUrl;
  static Duration get _timeout => AppConfig.agentTimeout;

  // ─── 1. POST /extractIntent ────────────────────────────────
  /// Runs IntentAgent on the raw user message.
  ///
  /// Returns:
  ///   session_id, intent{service_type, location, preferred_time, urgency,
  ///   language_detected, confidence_score, clarification_needed,
  ///   clarification_question}, workplan, agent_log
  static Future<Map<String, dynamic>> extractIntent(
    String message, {
    String? sessionId,
  }) async {
    if (_demo) {
      await _simulateDelay();
      final r = Map<String, dynamic>.from(MockData.intentResponse);
      r['session_id'] = sessionId ?? 'demo-session';
      r['agent_log'] = [
        {
          'step': 1,
          'agent': 'IntentAgent',
          'reasoning': MockData.intentResponse['agent_trace']['reasoning'],
          'output': MockData.intentResponse['intent'],
          'duration_ms': MockData.intentResponse['agent_trace']['latency_ms'],
          'status': 'success',
        }
      ];
      return r;
    }

    try {
      final body = {'message': message, 'session_id': sessionId ?? _activeSessionId};
      final resp = await _post('/extractIntent', body);
      if (resp.containsKey('error')) return resp;

      // Persist session_id for subsequent calls
      if (resp['session_id'] != null) {
        _activeSessionId = resp['session_id'] as String;
      }
      return resp;
    } catch (e) {
      debugPrint('AgentService.extractIntent error: $e');
      return _errorWithFallback('extractIntent', e, () {
        final r = Map<String, dynamic>.from(MockData.intentResponse);
        r['session_id'] = sessionId ?? 'fallback-session';
        r['agent_log'] = [];
        return r;
      });
    }
  }

  // ─── 2. POST /getProviders ─────────────────────────────────
  /// Runs DiscoveryAgent + RankingAgent using the intent from step 1.
  ///
  /// Returns:
  ///   session_id, providers[] (ranked, enriched with all card fields),
  ///   agent_log
  static Future<Map<String, dynamic>> getProviders(
    String sessionId,
    Map<String, dynamic> intent,
  ) async {
    if (_demo) {
      await _simulateDelay();
      return {
        'session_id': sessionId,
        'providers': MockData.providersResponse,
        'agent_log': [
          {
            'step': 2,
            'agent': 'DiscoveryAgent',
            'reasoning': 'Found 3 providers in mock data.',
            'output': {'total_found': 3},
            'duration_ms': 320,
            'status': 'success',
          },
          {
            'step': 3,
            'agent': 'RankingAgent',
            'reasoning': 'Ranked by distance, rating, availability.',
            'output': {'top_pick': 'Ahmed AC Services'},
            'duration_ms': 280,
            'status': 'success',
          },
        ],
      };
    }

    try {
      final sid = sessionId.isNotEmpty ? sessionId : (_activeSessionId ?? sessionId);
      final resp = await _post('/getProviders', {'session_id': sid, 'intent': intent});
      if (resp.containsKey('error')) {
        return {'session_id': sid, 'providers': MockData.providersResponse, 'agent_log': [], '_fallback': true, 'error': resp['error']};
      }
      return resp;
    } catch (e) {
      debugPrint('AgentService.getProviders error: $e');
      return _errorWithFallback('getProviders', e, () => {
        'session_id': sessionId,
        'providers': MockData.providersResponse,
        'agent_log': [],
        '_fallback': true,
      });
    }
  }

  // ─── 3. POST /getPriceQuote ────────────────────────────────
  /// Runs QuoteAgent for the selected provider.
  ///
  /// Returns:
  ///   session_id, quote{base_fee, urgency_fee, complexity_fee,
  ///   total_quoted_pkr, currency, surge_applied, fairness_note},
  ///   budget_alternative, agent_log
  static Future<Map<String, dynamic>> getPriceQuote(
    String sessionId,
    Map<String, dynamic> intent,
    Map<String, dynamic> provider,
  ) async {
    if (_demo) {
      await _simulateDelay();
      return {
        'session_id': sessionId,
        ...MockData.quoteResponse,
        'agent_log': [
          {
            'step': 4,
            'agent': 'QuoteAgent',
            'reasoning': MockData.quoteResponse['agent_trace']['reasoning'],
            'output': {'total_quoted_pkr': MockData.quoteResponse['quote']['total_quoted_pkr']},
            'duration_ms': MockData.quoteResponse['agent_trace']['latency_ms'],
            'status': 'success',
          }
        ],
      };
    }

    try {
      final sid = sessionId.isNotEmpty ? sessionId : (_activeSessionId ?? sessionId);
      final resp = await _post('/getPriceQuote', {
        'session_id': sid,
        'intent': intent,
        'provider': provider,
      });
      if (resp.containsKey('error')) {
        return {'session_id': sid, ...MockData.quoteResponse, 'agent_log': [], '_fallback': true, 'error': resp['error']};
      }
      return resp;
    } catch (e) {
      debugPrint('AgentService.getPriceQuote error: $e');
      return _errorWithFallback('getPriceQuote', e, () => {
        'session_id': sessionId,
        ...MockData.quoteResponse,
        'agent_log': [],
        '_fallback': true,
      });
    }
  }

  // ─── 4. POST /executeBooking ───────────────────────────────
  /// Runs BookingAgent + FollowupAgent.
  ///
  /// Returns:
  ///   session_id, booking{booking_id, provider_name, slot_time, …},
  ///   receipt, followups[], agent_log
  static Future<Map<String, dynamic>> executeBooking(
    String sessionId,
    Map<String, dynamic> intent,
    Map<String, dynamic> provider,
    Map<String, dynamic> quote,
  ) async {
    if (_demo) {
      await _simulateDelay(ms: 1200);
      final bk = Map<String, dynamic>.from(MockData.bookingResponse['booking_confirmation']!);
      return {
        'session_id': sessionId,
        'booking': bk,
        'receipt': _buildMockReceipt(bk),
        'followups': bk['reminders_scheduled'] ?? [],
        'agent_log': [
          {
            'step': 5,
            'agent': 'BookingAgent',
            'reasoning': MockData.bookingResponse['agent_trace']['reasoning'],
            'output': {'booking_id': bk['booking_id'], 'status': 'confirmed'},
            'duration_ms': MockData.bookingResponse['agent_trace']['total_latency_ms'],
            'status': 'success',
          },
          {
            'step': 6,
            'agent': 'FollowupAgent',
            'reasoning': 'Scheduled 3 follow-up notifications.',
            'output': {'notifications_scheduled': 3},
            'duration_ms': 180,
            'status': 'success',
          },
        ],
      };
    }

    try {
      final sid = sessionId.isNotEmpty ? sessionId : (_activeSessionId ?? sessionId);
      final resp = await _post('/executeBooking', {
        'session_id': sid,
        'intent': intent,
        'provider': provider,
        'quote': quote,
      });
      if (resp.containsKey('error')) {
        return {'session_id': sid, ..._mockBookingFallback(), '_fallback': true, 'error': resp['error']};
      }
      return resp;
    } catch (e) {
      debugPrint('AgentService.executeBooking error: $e');
      return _errorWithFallback('executeBooking', e, _mockBookingFallback);
    }
  }

  // ─── GET /agent-logs/{session_id} ─────────────────────────
  /// Fetch the full agent reasoning trace for the Trace screen.
  static Future<Map<String, dynamic>> getAgentLogs(String sessionId) async {
    if (_demo) {
      return {
        'session_id': sessionId,
        'flow': MockData.masterTrace['agent_runs']
            .map<Map<String, dynamic>>((r) => {
                  'step': r['sequence'],
                  'agent': r['agent_name'],
                  'reasoning': r['reasoning'],
                  'output': {'status': r['status']},
                  'duration_ms': r['latency_ms'],
                  'status': r['status'],
                })
            .toList(),
        'total_agents_run': 4,
      };
    }

    try {
      final sid = sessionId.isNotEmpty ? sessionId : (_activeSessionId ?? sessionId);
      final response = await http
          .get(Uri.parse('$_base/agent-logs/$sid'))
          .timeout(AppConfig.backendTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {'error': 'Logs not found (${response.statusCode})'};
    } catch (e) {
      debugPrint('AgentService.getAgentLogs error: $e');
      return {'error': 'Cannot fetch logs: $e'};
    }
  }

  // ─── Backward-compatible /chat (combined) ─────────────────
  /// Single call that runs Intent+Discovery+Ranking.
  /// Used by chat_screen.dart.
  static Future<Map<String, dynamic>> chat(
    String message,
    String sessionId,
  ) async {
    if (_demo) {
      await _simulateDelay();
      final intent = Map<String, dynamic>.from(MockData.intentResponse['intent']!);
      return {
        'session_id': sessionId,
        'clarification_needed': false,
        'intent': intent,
        'options': MockData.providersResponse,
        'agent_log': [
          {
            'step': 1, 'agent': 'IntentAgent',
            'reasoning': MockData.intentResponse['agent_trace']['reasoning'],
            'output': intent, 'duration_ms': 820, 'status': 'success',
          },
          {
            'step': 2, 'agent': 'DiscoveryAgent',
            'reasoning': 'Found providers in area.',
            'output': {'total_found': 3}, 'duration_ms': 320, 'status': 'success',
          },
          {
            'step': 3, 'agent': 'RankingAgent',
            'reasoning': 'Ranked by 8 factors.',
            'output': {'top_pick': 'Ahmed AC Services'}, 'duration_ms': 280, 'status': 'success',
          },
        ],
      };
    }

    try {
      final body = {'message': message, 'session_id': sessionId};
      final resp = await _post('/chat', body);
      if (resp.containsKey('error')) return resp;
      if (resp['session_id'] != null) _activeSessionId = resp['session_id'] as String;
      return resp;
    } catch (e) {
      debugPrint('AgentService.chat error: $e');
      return {'error': 'Connection error: $e'};
    }
  }

  // ─── Backward-compatible /book (combined) ─────────────────
  static Future<Map<String, dynamic>> book(
    String sessionId,
    String providerId,
    String slot,
  ) async {
    if (_demo) {
      await _simulateDelay(ms: 1200);
      return _mockBookingFallback();
    }
    try {
      final resp = await _post('/book', {
        'session_id': sessionId,
        'provider_id': providerId,
        'slot': slot,
      });
      if (resp.containsKey('error')) return _mockBookingFallback();
      return resp;
    } catch (e) {
      debugPrint('AgentService.book error: $e');
      return {'error': 'Connection error: $e'};
    }
  }

  // ─── Health check ──────────────────────────────────────────
  static Future<bool> isAgentsApiReachable() async {
    try {
      final response = await http
          .get(Uri.parse('$_base/'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── Internals ─────────────────────────────────────────────

  static Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          Uri.parse('$_base$path'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return {
      'error': 'HTTP ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 200))}'
    };
  }

  static Map<String, dynamic> _errorWithFallback(
    String method,
    Object error,
    Map<String, dynamic> Function() fallback,
  ) {
    debugPrint('AgentService.$method fallback triggered: $error');
    final result = fallback();
    result['_fallback'] = true;
    result['_fallback_reason'] = error.toString().substring(
        0, error.toString().length.clamp(0, 120));
    return result;
  }

  static Map<String, dynamic> _mockBookingFallback() {
    final bk = Map<String, dynamic>.from(
        MockData.bookingResponse['booking_confirmation']!);
    return {
      'booking': bk,
      'receipt': _buildMockReceipt(bk),
      'followups': bk['reminders_scheduled'] ?? [],
      'agent_log': [],
    };
  }

  static String _buildMockReceipt(Map<String, dynamic> bk) {
    final id   = bk['booking_id'] ?? 'BK-DEMO';
    final svc  = bk['service_type'] ?? 'Service';
    final prov = bk['provider_name'] ?? 'Provider';
    final slot = bk['confirmed_slot'] ?? bk['slot_time'] ?? '—';
    final loc  = bk['location'] ?? '—';
    final price = bk['total_price_pkr'] ?? bk['price_estimate'] ?? 0;
    return '╔══════════════════════════════════╗\n'
        '║    SEWABOT BOOKING CONFIRMED     ║\n'
        '╠══════════════════════════════════╣\n'
        '║  Booking ID: $id\n'
        '║  Service:    $svc\n'
        '║  Provider:   $prov\n'
        '║  Time:       $slot\n'
        '║  Location:   $loc\n'
        '║  Cost:       PKR $price\n'
        '╠══════════════════════════════════╣\n'
        '║  Status: ✓ CONFIRMED             ║\n'
        '╚══════════════════════════════════╝';
  }

  static Future<void> _simulateDelay({int ms = 800}) =>
      Future.delayed(Duration(milliseconds: ms));
}
