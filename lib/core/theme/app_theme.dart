import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../sport/app_sport.dart';
import 'app_colors.dart';
import 'sport_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => forSport(AppSport.volleyball);

  static ThemeData forSport(AppSport sport) {
    final colors = SportColors.of(sport);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: colors.primary,
      primary: colors.primary,
      onPrimary: AppColors.onPrimary,
      secondary: colors.action,
      onSecondary: AppColors.onPrimary,
      tertiary: colors.accent,
      onTertiary: colors.onBackground,
      error: AppColors.error,
      onError: AppColors.onPrimary,
      surface: colors.surface,
      onSurface: colors.onBackground,
      brightness: Brightness.light,
    );

    final textTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colors.background,
      textTheme: textTheme.apply(
        bodyColor: colors.onBackground,
        displayColor: colors.onBackground,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.onBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colors.onBackground,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.cta,
          foregroundColor: AppColors.onPrimary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.cta,
          foregroundColor: AppColors.onPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: colors.action.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? colors.action : colors.onBackground,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? colors.action : colors.onBackground,
          );
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colors.cta,
        foregroundColor: AppColors.onPrimary,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return colors.action;
          return null;
        }),
      ),
    );
  }
}
