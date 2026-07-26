import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/sport/app_sport.dart';
import '../../core/theme/app_colors.dart';
import 'widgets/sport_option_card.dart';

/// Full-screen welcome / sport picker shown on launch.
class SportsScreen extends StatelessWidget {
  const SportsScreen({super.key});

  static const String athleteName = 'Emma';

  void _selectSport(BuildContext context, AppSport sport) {
    appSportController.select(sport);
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.lightTeal.withValues(alpha: 0.35),
              AppColors.warmSand,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  AppStrings.appName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.midTeal,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(flex: 2),
                Text(
                  'Welcome, $athleteName',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkestNavy,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'What sport would you like to practice today?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.7),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 36),
                SportOptionCard(
                  sport: AppSport.volleyball,
                  onTap: () => _selectSport(context, AppSport.volleyball),
                ),
                const SizedBox(height: 16),
                  SportOptionCard(
                    sport: AppSport.soccer,
                    onTap: () => _selectSport(context, AppSport.soccer),
                  ),
                const Spacer(flex: 3),
                Text(
                  'You can change this anytime from Home',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurface.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
