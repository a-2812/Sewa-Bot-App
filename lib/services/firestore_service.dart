/// FirestoreService — stub only.
/// All data persistence is handled by the backend REST API (port 8000).
/// This file is retained for structural compatibility only.
class FirestoreService {
  static Future<String> saveBooking(Map<String, dynamic> data) async => '';
  static Future<Map<String, dynamic>?> getBooking(String id) async => null;
  static Future<List<Map<String, dynamic>>> getUserBookings(String userId) async => [];
  static Future<void> saveTrace(Map<String, dynamic> data) async {}
  static Future<Map<String, dynamic>?> getTrace(String traceId) async => null;
  static Future<String> saveDispute(Map<String, dynamic> data) async => '';
}
