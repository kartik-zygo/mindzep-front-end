import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Brand
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9D97FF);
  static const Color primaryDark = Color(0xFF4A42D6);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6C63FF), Color(0xFF9D97FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Semantic
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF007AFF);

  // Availability dots
  static const Color available = Color(0xFF34C759);
  static const Color busy = Color(0xFFFF9500);
  static const Color offline = Color(0xFFFF3B30);

  // Surface
  static const Color background = Color(0xFFF2F2F7);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFEFEFF4);

  // Text
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6C6C70);
  static const Color textTertiary = Color(0xFFAEAEB2);

  // Border
  static const Color border = Color(0xFFC6C6C8);

  // Call controls
  static const Color callEndRed = Color(0xFFFF3B30);
  static const Color callControlBackground = Color(0x99000000);
}
