import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/sport/app_sport.dart';
import '../../core/theme/sport_colors.dart';
import 'widgets/sport_option_card.dart';

/// Full-screen welcome / sport picker shown on launch.
class SportsScreen extends StatelessWidget {
  const SportsScreen({super.key});

  static const String athleteName = 'Emma';

  void _selectSport(BuildContext context, AppSport sport) {
    appSportController.select(sport);
    final pending = appSportController.takePendingDeepLink();
    final target = (pending != null &&
            pending.isNotEmpty &&
            pending != '/sports' &&
            !pending.startsWith('/sports?'))
        ? pending
        : '/home';
    context.go(target);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = SportColors.of(appSportController.sport);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.background,
              colors.highlight.withValues(alpha: 0.45),
              colors.background,
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
                    color: colors.action,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                  ),
                ),
                const Spacer(flex: 2),
                Text(
                  'Welcome, $athleteName',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.onBackground,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'What sport would you like to practice today?',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onBackground.withValues(alpha: 0.7),
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
                    color: colors.onBackground.withValues(alpha: 0.45),
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
