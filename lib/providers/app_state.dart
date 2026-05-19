import 'package:flutter/material.dart';
import 'dart:math';

/// Application status enum
enum AppStatus { idle, loading, success, error }

/// Central application state using ChangeNotifier
class AppState extends ChangeNotifier {
  // ─── Status ────────────────────────────────────────────────
  AppStatus _status = AppStatus.idle;
  String _errorMessage = '';
  String _sessionId = _generateUUID();

  AppStatus get status => _status;
  String get errorMessage => _errorMessage;
  String get sessionId => _sessionId;

  // ─── Intent ────────────────────────────────────────────────
  Map<String, dynamic>? _currentIntent;
  Map<String, dynamic>? get currentIntent => _currentIntent;

  // ─── Providers ─────────────────────────────────────────────
  List<Map<String, dynamic>> _rankedProviders = [];
  List<Map<String, dynamic>> get rankedProviders => _rankedProviders;

  // ─── Selected Provider ─────────────────────────────────────
  Map<String, dynamic>? _selectedProvider;
  Map<String, dynamic>? get selectedProvider => _selectedProvider;

  // ─── Quote ─────────────────────────────────────────────────
  Map<String, dynamic>? _currentQuote;
  Map<String, dynamic>? get currentQuote => _currentQuote;

  // ─── Booking ───────────────────────────────────────────────
  String? _bookingId;
  String? _currentTraceId;
  String? get bookingId => _bookingId;
  String? get currentTraceId => _currentTraceId;

  // ─── Chat Messages ─────────────────────────────────────────
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> get messages => _messages;

  // ─── Status Setters ────────────────────────────────────────

  void setLoading() {
    _status = AppStatus.loading;
    notifyListeners();
  }

  void setError(String msg) {
    _status = AppStatus.error;
    _errorMessage = msg;
    notifyListeners();
  }

  void setSuccess() {
    _status = AppStatus.success;
    notifyListeners();
  }

  void setIdle() {
    _status = AppStatus.idle;
    notifyListeners();
  }

  // ─── Data Setters ──────────────────────────────────────────

  void setIntent(Map<String, dynamic> data) {
    _currentIntent = data;
    notifyListeners();
  }

  void setProviders(List<Map<String, dynamic>> data) {
    _rankedProviders = data;
    notifyListeners();
  }

  void selectProvider(Map<String, dynamic> data) {
    _selectedProvider = data;
    notifyListeners();
  }

  void setQuote(Map<String, dynamic> data) {
    _currentQuote = data;
    notifyListeners();
  }

  void setBooking(String id, String traceId) {
    _bookingId = id;
    _currentTraceId = traceId;
    notifyListeners();
  }

  // ─── Chat Message Management ───────────────────────────────

  void addMessage(Map<String, dynamic> message) {
    _messages.add(message);
    notifyListeners();
  }

  void clearMessages() {
    _messages = [];
    notifyListeners();
  }

  // ─── Reset ─────────────────────────────────────────────────

  void reset() {
    _status = AppStatus.idle;
    _errorMessage = '';
    _sessionId = _generateUUID();
    _currentIntent = null;
    _rankedProviders = [];
    _selectedProvider = null;
    _currentQuote = null;
    _bookingId = null;
    _currentTraceId = null;
    _messages = [];
    notifyListeners();
  }

  // ─── UUID Generator ────────────────────────────────────────
  static String _generateUUID() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40;
    values[8] = (values[8] & 0x3f) | 0x80;
    final hex = values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
