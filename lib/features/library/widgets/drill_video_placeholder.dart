import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class DrillVideoPlaceholder extends StatelessWidget {
  const DrillVideoPlaceholder({
    super.key,
    required this.durationMinutes,
  });

  final int durationMinutes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.85),
                    AppColors.cta,
                  ],
                ),
              ),
            ),
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                size: 72,
                color: AppColors.onPrimary,
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$durationMinutes min',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
