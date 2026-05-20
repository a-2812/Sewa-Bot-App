import 'package:flutter/foundation.dart';

/// SewaBot API Configuration
///
/// All URLs are injected at build time via --dart-define.
/// Defaults point to Render production services.
///
/// ── Local dev (Flutter Web) ──────────────────────────────────────
///   flutter run --dart-define=AGENTS_BASE_URL=http://localhost:8001 \
///               --dart-define=BACKEND_BASE_URL=http://localhost:8000 \
///               --dart-define=DEMO_MODE=false
///
/// ── Android Emulator ────────────────────────────────────────────
///   Use 10.0.2.2 instead of localhost:
///   flutter run --dart-define=AGENTS_BASE_URL=http://10.0.2.2:8001 \
///               --dart-define=BACKEND_BASE_URL=http://10.0.2.2:8000
///
/// ── Production (Render) ─────────────────────────────────────────
///   flutter build apk \
///     --dart-define=AGENTS_BASE_URL=https://sewabot-agents.onrender.com \
///     --dart-define=BACKEND_BASE_URL=https://sewabot-backend.onrender.com \
///     --dart-define=DEMO_MODE=false
///
/// IMPORTANT: Production must always use HTTPS.
class AppConfig {
  // ── Injected at build time via --dart-define ──────────────────

  /// SewaBot Agents API (AI orchestration) — default: Render prod URL
  static const String agentsBaseUrl = String.fromEnvironment(
    'AGENTS_BASE_URL',
    defaultValue: 'https://sewabot-agents.onrender.com',
  );

  /// SewaBot Backend API (persistence / Firestore) — default: Render prod URL
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://sewabot-backend.onrender.com',
  );

  /// Demo mode — uses mock data when true, bypasses all API calls
  static const bool demoMode = bool.fromEnvironment(
    'DEMO_MODE',
    defaultValue: false,
  );

  // ── Timeouts ─────────────────────────────────────────────────
  /// Gemini-backed agents can take up to 10 s; give extra headroom
  static const Duration agentTimeout = Duration(seconds: 60);

  /// Direct backend calls (Firestore, bookings, disputes)
  static const Duration backendTimeout = Duration(seconds: 20);
}
