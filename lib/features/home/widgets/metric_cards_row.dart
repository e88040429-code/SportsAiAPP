import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/home_mock_data.dart';

class MetricCardsRow extends StatelessWidget {
  const MetricCardsRow({super.key, required this.metrics});

  final List<HomeMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(child: _MetricCard(metric: metrics[i])),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final HomeMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, size: 18, color: AppColors.accent),
          const SizedBox(height: 10),
          Text(
            metric.value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            metric.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}
