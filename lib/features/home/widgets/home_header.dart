import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/sport/app_sport.dart';
import '../../../core/theme/app_colors.dart';
import '../data/home_mock_data.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.user,
    required this.sport,
  });

  final HomeUser user;
  final AppSport sport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${user.greeting},',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'AI Coach',
              onPressed: () => context.push('/ai'),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.midTeal.withValues(alpha: 0.12),
              ),
              icon: const Icon(Icons.auto_awesome, color: AppColors.midTeal),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.15),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => context.push('/sports'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.midTeal.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(sport.icon, color: AppColors.midTeal, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Training sport',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                        Text(
                          sport.label,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Change',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.burntOrange,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.burntOrange,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
