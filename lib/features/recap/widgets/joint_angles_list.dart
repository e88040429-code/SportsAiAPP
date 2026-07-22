import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/recap_mock_data.dart';

class JointAnglesList extends StatelessWidget {
  const JointAnglesList({super.key, required this.comparisons});

  final List<JointComparison> comparisons;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Joint Angles',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        'Joint',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.onSurface.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'You',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.burntOrange,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Coach',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.midTeal,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              for (var i = 0; i < comparisons.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.onSurface.withValues(alpha: 0.06),
                  ),
                _JointAngleRow(comparison: comparisons[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _JointAngleRow extends StatelessWidget {
  const _JointAngleRow({required this.comparison});

  final JointComparison comparison;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              comparison.joint,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${comparison.athleteDegrees}°',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.burntOrange,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${comparison.coachDegrees}°',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.midTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
