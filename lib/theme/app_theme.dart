import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// KhidmatAI Design System — Dual Theme Architecture
class AppTheme {
  // ─── Shared Semantic Colors ─────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color traceHeader = Color(0xFFF3F4F6);

  // ─── User Theme Colors ──────────────────────────────────────
  static const Color userPrimary = Colors.black;
  static const Color userPrimaryLight = Colors.black87;
  static const Color userBackground = Colors.white;
  static const Color userSurface = Colors.white;
  static const Color userInputFill = Color(0xFFF3F4F6);
  static const Color userBorder = Color(0xFFE5E7EB);

  // ─── Provider Theme Colors ──────────────────────────────────
  static const Color providerPrimary = Colors.black;
  static const Color providerPrimaryLight = Colors.black87;
  static const Color providerBackground = Colors.white;
  static const Color providerSurface = Colors.white;
  static const Color providerInputFill = Color(0xFFF3F4F6);
  static const Color providerBorder = Color(0xFFE5E7EB);

  // ─── Text Styles ────────────────────────────────────────────
  static const TextStyle heading1 = TextStyle(
    color: textPrimary, fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5,
  );
  static const TextStyle heading2 = TextStyle(
    color: textPrimary, fontSize: 22, fontWeight: FontWeight.w600,
  );
  static const TextStyle heading3 = TextStyle(
    color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600,
  );
  static const TextStyle bodyLarge = TextStyle(
    color: textPrimary, fontSize: 16, fontWeight: FontWeight.w400, height: 1.5,
  );
  static const TextStyle bodyMedium = TextStyle(
    color: textSecondary, fontSize: 14, fontWeight: FontWeight.w400, height: 1.4,
  );
  static const TextStyle bodySmall = TextStyle(
    color: textSecondary, fontSize: 12, fontWeight: FontWeight.w400,
  );
  static const TextStyle caption = TextStyle(
    color: textMuted, fontSize: 11, fontWeight: FontWeight.w400,
  );

  // ─── Build Theme ────────────────────────────────────────────
  static ThemeData _buildTheme({
    required Color primary,
    required Color primaryLight,
    required Color background,
    required Color surface,
    required Color inputFill,
    required Color border,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: primaryLight,
        surface: surface,
        error: danger,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: primary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: primary, fontSize: 18, fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(color: primary),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 0.5),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(color: primary, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        hintStyle: const TextStyle(color: textMuted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primary),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(color: textPrimary, fontSize: 32, fontWeight: FontWeight.w700),
        displayMedium: GoogleFonts.poppins(color: textPrimary, fontSize: 28, fontWeight: FontWeight.w700),
        displaySmall: GoogleFonts.poppins(color: textPrimary, fontSize: 24, fontWeight: FontWeight.w600),
        headlineMedium: GoogleFonts.poppins(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: GoogleFonts.poppins(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.poppins(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w500),
        titleMedium: GoogleFonts.poppins(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall: GoogleFonts.poppins(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
        bodyLarge: GoogleFonts.poppins(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w400),
        bodyMedium: GoogleFonts.poppins(color: textSecondary, fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: GoogleFonts.poppins(color: textMuted, fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: GoogleFonts.poppins(color: textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
        labelMedium: GoogleFonts.poppins(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: GoogleFonts.poppins(color: textMuted, fontSize: 10, fontWeight: FontWeight.w400),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 0.5, space: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.poppins(color: textPrimary, fontSize: 18, fontWeight: FontWeight.w600),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: GoogleFonts.poppins(color: textPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.poppins(color: textPrimary, fontSize: 12),
        side: BorderSide(color: border, width: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary.withValues(alpha: 0.3);
          return border;
        }),
      ),
    );
  }

  // ─── User Theme ─────────────────────────────────────────────
  static ThemeData get userTheme => _buildTheme(
    primary: userPrimary,
    primaryLight: userPrimaryLight,
    background: userBackground,
    surface: userSurface,
    inputFill: userInputFill,
    border: userBorder,
  );

  // ─── Provider Theme ─────────────────────────────────────────
  static ThemeData get providerTheme => _buildTheme(
    primary: providerPrimary,
    primaryLight: providerPrimaryLight,
    background: providerBackground,
    surface: providerSurface,
    inputFill: providerInputFill,
    border: providerBorder,
  );
}
