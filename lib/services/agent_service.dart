import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/mock_data.dart';

/// Service class for communicating with the KhidmatAI backend
class AgentService {
  // ─── CHANGE THIS to your Cloud Function URL ─────────────────
  static const String baseUrl = 'YOUR_CLOUD_FUNCTION_URL';

  // ─── Demo Mode (uses mock data when true) ───────────────────
  static bool demoMode = true;

  // ─── Timeout duration for HTTP requests ─────────────────────
  static const Duration _timeout = Duration(seconds: 30);

  // ─── Extract Intent ────────────────────────────────────────
  static Future<Map<String, dynamic>> extractIntent(String message) async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 1200));
      return Map<String, dynamic>.from(MockData.intentResponse);
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/extractIntent'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'message': message}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {'error': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'Connection error: $e'};
    }
  }

  // ─── Get Providers ─────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getProviders(
      Map<String, dynamic> intent) async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 1200));
      return MockData.providersResponse
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList();
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/getProviders'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'intent': intent}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded
              .map((p) => Map<String, dynamic>.from(p as Map))
              .toList();
        }
        return [];
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('getProviders error: $e');
      return [];
    }
  }

  // ─── Get Price Quote ───────────────────────────────────────
  static Future<Map<String, dynamic>> getPriceQuote(
      Map<String, dynamic> intent, Map<String, dynamic> provider) async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 1200));
      return Map<String, dynamic>.from(MockData.quoteResponse);
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/getPriceQuote'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'intent': intent, 'provider': provider}),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {'error': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'Connection error: $e'};
    }
  }

  // ─── Execute Booking ───────────────────────────────────────
  static Future<Map<String, dynamic>> executeBooking(
      Map<String, dynamic> intent,
      Map<String, dynamic> provider,
      Map<String, dynamic> quote) async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 1200));
      return Map<String, dynamic>.from(MockData.bookingResponse);
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/executeBooking'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'intent': intent,
              'provider': provider,
              'quote': quote,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {'error': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'Connection error: $e'};
    }
  }

  // ─── Submit Dispute ────────────────────────────────────────
  static Future<Map<String, dynamic>> submitDispute(
      String bookingId, String type, String details) async {
    if (demoMode) {
      await Future.delayed(const Duration(milliseconds: 1200));
      return {
        'status': 'received',
        'dispute_id': 'DSP-${DateTime.now().millisecondsSinceEpoch}',
        'message':
            'Your dispute has been received and will be reviewed within 24 hours.',
        'booking_id': bookingId,
        'type': type,
      };
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/submitDispute'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'booking_id': bookingId,
              'type': type,
              'details': details,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return {'error': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'error': 'Connection error: $e'};
    }
  }
}
