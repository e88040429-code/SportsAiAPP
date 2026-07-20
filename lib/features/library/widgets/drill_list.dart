import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/library_mock_data.dart';

class DrillList extends StatelessWidget {
  const DrillList({
    super.key,
    required this.drills,
    required this.onDrillTap,
  });

  final List<LibraryDrill> drills;
  final ValueChanged<LibraryDrill> onDrillTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (drills.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 40,
              color: AppColors.onSurface.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(
              'No drills match your filters',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Core Skills',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < drills.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _DrillTile(
            drill: drills[i],
            onTap: () => onDrillTap(drills[i]),
          ),
        ],
      ],
    );
  }
}

class _DrillTile extends StatelessWidget {
  const _DrillTile({required this.drill, required this.onTap});

  final LibraryDrill drill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.action.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(drill.icon, color: AppColors.action),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      drill.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      drill.subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${drill.durationMinutes} min',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right,
                color: AppColors.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
