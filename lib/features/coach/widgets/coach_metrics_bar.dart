import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/coach_mock_data.dart';

class CoachMetricsBar extends StatelessWidget {
  const CoachMetricsBar({super.key, required this.metrics});

  final List<CoachMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.darkTeal.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.burntOrange.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < metrics.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _MetricTile(metric: metrics[i])),
          ],
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric});

  final CoachMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          metric.value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          metric.label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.onCoachDark.withValues(alpha: 0.75),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
