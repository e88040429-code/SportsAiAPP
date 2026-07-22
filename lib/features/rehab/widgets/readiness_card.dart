import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class ReadinessCard extends StatelessWidget {
  const ReadinessCard({
    super.key,
    required this.percent,
    required this.message,
  });

  final int percent;
  final String message;

  bool get _isHighReadiness => percent >= 80;

  Color get _scoreColor =>
      _isHighReadiness ? AppColors.midTeal : AppColors.burntOrange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Today's Readiness",
            style: theme.textTheme.labelLarge?.copyWith(
              color: _scoreColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '$percent%',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: _scoreColor,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.65),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
