import 'package:flutter/material.dart';

/// Utility for showing styled snackbars
class SnackHelper {
  static void show(BuildContext context, String message, {
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor ?? Colors.white, size: 20),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor ?? Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor ?? const Color(0xFF1E1E30),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static void success(BuildContext context, String message) {
    show(context, message,
      backgroundColor: const Color(0xFF34D399).withValues(alpha: 0.15),
      textColor: const Color(0xFF34D399),
      icon: Icons.check_circle_outline,
    );
  }

  static void error(BuildContext context, String message) {
    show(context, message,
      backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.15),
      textColor: const Color(0xFFEF4444),
      icon: Icons.error_outline,
    );
  }

  static void warning(BuildContext context, String message) {
    show(context, message,
      backgroundColor: const Color(0xFFFBBF24).withValues(alpha: 0.15),
      textColor: const Color(0xFFFBBF24),
      icon: Icons.warning_amber_outlined,
    );
  }

  static void info(BuildContext context, String message) {
    show(context, message,
      backgroundColor: const Color(0xFF6C63FF).withValues(alpha: 0.15),
      textColor: const Color(0xFF6C63FF),
      icon: Icons.info_outline,
    );
  }
}
