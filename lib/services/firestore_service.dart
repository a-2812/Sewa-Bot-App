import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore service for direct database operations
class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Bookings ──────────────────────────────────────────────

  /// Save a booking and return the document ID
  static Future<String> saveBooking(Map<String, dynamic> data) async {
    try {
      final docRef = await _db.collection('bookings').add({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save booking: $e');
    }
  }

  /// Get a booking by its document ID
  static Future<Map<String, dynamic>?> getBooking(String id) async {
    try {
      final doc = await _db.collection('bookings').doc(id).get();
      if (doc.exists) {
        return {'id': doc.id, ...doc.data()!};
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get booking: $e');
    }
  }

  /// Get all bookings for a user
  static Future<List<Map<String, dynamic>>> getUserBookings(
      String userId) async {
    try {
      final snapshot = await _db
          .collection('bookings')
          .where('user_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      throw Exception('Failed to get user bookings: $e');
    }
  }

  // ─── Traces ────────────────────────────────────────────────

  /// Get a real-time stream of traces for a session
  static Stream<QuerySnapshot> traceStream(String sessionId) {
    return _db
        .collection('agent_traces')
        .where('session_id', isEqualTo: sessionId)
        .orderBy('timestamp_start', descending: true)
        .limit(1)
        .snapshots();
  }

  /// Save a trace document
  static Future<void> saveTrace(Map<String, dynamic> data) async {
    try {
      await _db.collection('agent_traces').add({
        ...data,
        'saved_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to save trace: $e');
    }
  }

  /// Get a specific trace by trace_id
  static Future<Map<String, dynamic>?> getTrace(String traceId) async {
    try {
      final snapshot = await _db
          .collection('agent_traces')
          .where('trace_id', isEqualTo: traceId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return {'id': snapshot.docs.first.id, ...snapshot.docs.first.data()};
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get trace: $e');
    }
  }

  // ─── Disputes ──────────────────────────────────────────────

  /// Save a dispute
  static Future<String> saveDispute(Map<String, dynamic> data) async {
    try {
      final docRef = await _db.collection('disputes').add({
        ...data,
        'created_at': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save dispute: $e');
    }
  }
}
