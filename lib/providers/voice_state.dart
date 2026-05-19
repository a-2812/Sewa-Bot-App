import 'dart:convert';
import 'package:flutter/material.dart';

/// Manages voice input/output state for the chat
class VoiceState extends ChangeNotifier {
  bool _isListening = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  String _transcribedText = '';
  double _soundLevel = 0.0;
  String _statusMessage = '';
  final List<String> _conversationHistory = [];

  // ─── Getters ───────────────────────────────────────────────
  bool get isListening => _isListening;
  bool get isProcessing => _isProcessing;
  bool get isSpeaking => _isSpeaking;
  String get transcribedText => _transcribedText;
  double get soundLevel => _soundLevel;
  String get statusMessage => _statusMessage;
  List<String> get conversationHistory => _conversationHistory;

  // ─── Setters ───────────────────────────────────────────────
  void setListening(bool value) {
    _isListening = value;
    notifyListeners();
  }

  void setProcessing(bool value) {
    _isProcessing = value;
    notifyListeners();
  }

  void setSpeaking(bool value) {
    _isSpeaking = value;
    notifyListeners();
  }

  void setTranscribed(String text) {
    _transcribedText = text;
    notifyListeners();
  }

  void setSoundLevel(double level) {
    _soundLevel = level;
    notifyListeners();
  }

  void setStatus(String msg) {
    _statusMessage = msg;
    notifyListeners();
  }

  // ─── History ───────────────────────────────────────────────
  void addToHistory(String text, bool isUser) {
    _conversationHistory.add(jsonEncode({
      'text': text,
      'isUser': isUser,
      'time': DateTime.now().toIso8601String(),
    }));
    notifyListeners();
  }

  void clearHistory() {
    _conversationHistory.clear();
    notifyListeners();
  }

  // ─── Reset ─────────────────────────────────────────────────
  void reset() {
    _isListening = false;
    _isProcessing = false;
    _isSpeaking = false;
    _transcribedText = '';
    _soundLevel = 0.0;
    _statusMessage = '';
    notifyListeners();
  }
}
