import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Voice input/output service using speech_to_text and flutter_tts
class VoiceService {
  static final SpeechToText _speech = SpeechToText();
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;

  // ─── Initialize ────────────────────────────────────────────
  static Future<bool> initialize() async {
    try {
      _initialized = await _speech.initialize(
        onError: (error) => debugPrint('Speech error: ${error.errorMsg}'),
        onStatus: (status) => debugPrint('Speech status: $status'),
      );

      await _tts.setLanguage('ur-PK');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      return _initialized;
    } catch (e) {
      debugPrint('VoiceService init error: $e');
      return false;
    }
  }

  // ─── Start Listening ───────────────────────────────────────
  static Future<void> startListening({
    required Function(String) onResult,
    required Function(double) onSoundLevel,
    String localeId = 'ur_PK',
  }) async {
    if (!_initialized) {
      final success = await initialize();
      if (!success) {
        debugPrint('VoiceService: Could not initialize speech recognition');
        return;
      }
    }

    await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: localeId,
      onSoundLevelChange: onSoundLevel,
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
        autoPunctuation: true,
      ),
    );
  }

  // ─── Stop Listening ────────────────────────────────────────
  static Future<void> stopListening() async {
    await _speech.stop();
  }

  // ─── Text to Speech ────────────────────────────────────────
  static Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  // ─── Stop Speaking ─────────────────────────────────────────
  static Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  // ─── Get Available Locales ─────────────────────────────────
  static Future<List<dynamic>> getAvailableLocales() async {
    return await _tts.getLanguages;
  }

  // ─── Check Availability ────────────────────────────────────
  static bool get isAvailable => _initialized;

  // ─── Set TTS Language ──────────────────────────────────────
  static Future<void> setLanguage(String languageCode) async {
    await _tts.setLanguage(languageCode);
  }

  // ─── Set TTS Speed ─────────────────────────────────────────
  static Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate);
  }
}
