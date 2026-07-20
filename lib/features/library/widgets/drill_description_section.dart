import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/drill_detail_mock_data.dart';

class DrillDescriptionSection extends StatelessWidget {
  const DrillDescriptionSection({super.key, required this.detail});

  final DrillDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          detail.subtitle,
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          detail.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Description',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          detail.description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurface.withValues(alpha: 0.75),
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
