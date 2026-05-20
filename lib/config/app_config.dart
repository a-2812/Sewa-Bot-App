import 'package:flutter/foundation.dart';

/// Central API configuration for SewaBot.
///
/// ── Switching targets ──────────────────────────────────────────
///   Web / desktop / local browser  →  set [target] = AppTarget.web
///   Android emulator               →  set [target] = AppTarget.emulator
///   Physical device on LAN         →  set [target] = AppTarget.device
///                                     and set [lanIp] to your machine's IP
/// ───────────────────────────────────────────────────────────────
enum AppTarget { web, emulator, device }

class AppConfig {
  // ─── ★ CHANGE THIS to switch between targets ───────────────
  static const AppTarget _target = AppTarget.web;

  /// Only used when target == AppTarget.device
  /// Set this to your machine's LAN IP (e.g. '192.168.1.5')
  static const String _lanIp = '192.168.1.5';

  // ─── Demo / Mock mode ──────────────────────────────────────
  /// Set to true to use mock data without a running API server.
  /// Set to false for live integrated demo.
  static const bool demoMode = false;

  // ─── Resolved host ────────────────────────────────────────
  static String get _host {
    // Auto-detect: on web kIsWeb == true → use localhost
    if (kIsWeb) return 'localhost';
    switch (_target) {
      case AppTarget.web:
        return 'localhost';
      case AppTarget.emulator:
        return '10.0.2.2';
      case AppTarget.device:
        return _lanIp;
    }
  }

  /// SewaBot Agents API (orchestration layer) — port 8001
  static String get agentsBaseUrl => 'http://$_host:8001';

  /// SewaBot Backend API (persistence layer) — port 8000
  static String get backendBaseUrl => 'http://$_host:8000';

  /// Timeout for agent calls (Gemini can take up to 10 s)
  static const Duration agentTimeout = Duration(seconds: 60);

  /// Timeout for direct backend calls
  static const Duration backendTimeout = Duration(seconds: 15);
}
