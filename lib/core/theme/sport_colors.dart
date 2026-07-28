import 'package:flutter/material.dart';

import '../sport/app_sport.dart';
import 'app_colors.dart';

/// Sport-specific accent palette. Volleyball keeps the teal/sand brand;
/// soccer switches to a pitch-green field look.
class SportColors {
  const SportColors({
    required this.primary,
    required this.action,
    required this.cta,
    required this.accent,
    required this.highlight,
    required this.background,
    required this.surface,
    required this.onBackground,
    required this.coachLine,
    required this.coachJoint,
  });

  final Color primary;
  final Color action;
  final Color cta;
  final Color accent;
  final Color highlight;
  final Color background;
  final Color surface;
  final Color onBackground;
  final Color coachLine;
  final Color coachJoint;

  static const volleyball = SportColors(
    primary: AppColors.burntOrange,
    action: AppColors.midTeal,
    cta: AppColors.deepOrange,
    accent: AppColors.amber,
    highlight: AppColors.lightTeal,
    background: AppColors.warmSand,
    surface: Colors.white,
    onBackground: AppColors.darkestNavy,
    coachLine: AppColors.midTeal,
    coachJoint: AppColors.darkTeal,
  );

  /// Pitch / turf inspired soccer palette.
  static const soccer = SportColors(
    primary: Color(0xFF2D6A4F),
    action: Color(0xFF40916C),
    cta: Color(0xFF1B4332),
    accent: Color(0xFFFFB703),
    highlight: Color(0xFF95D5B2),
    background: Color(0xFFF1FAEE),
    surface: Colors.white,
    onBackground: Color(0xFF081C15),
    coachLine: Color(0xFF52B788),
    coachJoint: Color(0xFF2D6A4F),
  );

  static SportColors of(AppSport sport) => switch (sport) {
        AppSport.volleyball => volleyball,
        AppSport.soccer => soccer,
      };
}
