import 'package:flutter/material.dart';

/// User roles in the KhidmatAI app
enum UserRole { user, provider, none }

/// Role-based color configuration
class RoleConfig {
  // ─── Primary Colors ────────────────────────────────────────
  static Color primaryColor(UserRole role) {
    switch (role) {
      case UserRole.user:
        return Colors.black;
      case UserRole.provider:
        return Colors.black;
      case UserRole.none:
        return Colors.black;
    }
  }

  static Color secondaryColor(UserRole role) {
    switch (role) {
      case UserRole.user:
        return Colors.grey;
      case UserRole.provider:
        return Colors.grey;
      case UserRole.none:
        return Colors.grey;
    }
  }

  // ─── Background Colors ─────────────────────────────────────
  static Color backgroundColor(UserRole role) {
    switch (role) {
      case UserRole.user:
        return Colors.white;
      case UserRole.provider:
        return Colors.white;
      case UserRole.none:
        return Colors.white;
    }
  }

  static Color surfaceColor(UserRole role) {
    switch (role) {
      case UserRole.user:
        return Colors.white;
      case UserRole.provider:
        return Colors.white;
      case UserRole.none:
        return Colors.white;
    }
  }

  static Color cardColor(UserRole role) {
    switch (role) {
      case UserRole.user:
        return const Color(0xFFF3F4F6);
      case UserRole.provider:
        return const Color(0xFFF3F4F6);
      case UserRole.none:
        return const Color(0xFFF3F4F6);
    }
  }

  static Color borderColor(UserRole role) {
    switch (role) {
      case UserRole.user:
        return const Color(0xFFE5E7EB);
      case UserRole.provider:
        return const Color(0xFFE5E7EB);
      case UserRole.none:
        return const Color(0xFFE5E7EB);
    }
  }

  // ─── Semantic Colors (shared) ──────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
}
