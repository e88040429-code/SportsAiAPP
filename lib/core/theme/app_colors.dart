import 'package:flutter/material.dart';

/// Brand and semantic colors for SetPoint AI.
abstract final class AppColors {
  // Raw palette
  static const Color darkestNavy = Color(0xFF001219);
  static const Color darkTeal = Color(0xFF005F73);
  static const Color midTeal = Color(0xFF0A9396);
  static const Color lightTeal = Color(0xFF94D2BD);
  static const Color warmSand = Color(0xFFE9D8A6);
  static const Color amber = Color(0xFFEE9B00);
  static const Color burntOrange = Color(0xFFCA6702);
  static const Color deepOrange = Color(0xFFBB3E03);
  static const Color darkRed = Color(0xFFAE2012);
  static const Color darkestRed = Color(0xFF9B2226);

  /// Primary brand color (replaces former `#FF7F32`).
  static const Color primary = burntOrange;

  /// Primary actions and active / selected states.
  static const Color action = midTeal;

  /// Buttons and CTAs.
  static const Color cta = deepOrange;

  /// Accents and metric highlights.
  static const Color accent = amber;

  /// Subtle highlights and chips.
  static const Color highlight = lightTeal;

  static const Color background = warmSand;
  static const Color surface = Colors.white;
  static const Color onPrimary = Colors.white;
  static const Color onBackground = darkestNavy;
  static const Color onSurface = darkestNavy;

  static const Color success = midTeal;
  static const Color warning = darkRed;
  static const Color info = midTeal;
  static const Color error = darkestRed;

  /// Live Coach camera HUD background.
  static const Color coachDark = darkestNavy;
  static const Color onCoachDark = Colors.white;
}
