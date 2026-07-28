import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/sport/app_sport.dart';
import '../../../core/theme/sport_colors.dart';
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
    final colors = SportColors.of(sport);

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
                      color: colors.onBackground.withValues(alpha: 0.6),
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
                backgroundColor: colors.action.withValues(alpha: 0.12),
              ),
              icon: Icon(Icons.auto_awesome, color: colors.action),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: colors.primary.withValues(alpha: 0.15),
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: () => context.push('/sports'),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colors.action.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(sport.icon, color: colors.action, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Training sport',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colors.onBackground.withValues(alpha: 0.55),
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
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    color: colors.primary,
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
