import 'package:flutter/material.dart';

/// Brand and semantic colors for SetPoint AI (from UI mockups).
abstract final class AppColors {
  static const Color primary = Color(0xFFFF7F32);
  static const Color background = Color(0xFFF8F8F8);
  static const Color surface = Colors.white;
  static const Color onPrimary = Colors.white;
  static const Color onBackground = Color(0xFF1A1A1A);
  static const Color onSurface = Color(0xFF1A1A1A);

  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF1C40F);
  static const Color info = Color(0xFF3498DB);

  /// Live Coach camera HUD background.
  static const Color coachDark = Color(0xFF121212);
  static const Color onCoachDark = Colors.white;
}
