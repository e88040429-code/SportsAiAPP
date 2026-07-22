import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'recap_skeleton_painter.dart';

class YouVsCoachSection extends StatelessWidget {
  const YouVsCoachSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'You vs Coach',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PoseCard(
                label: 'You',
                joints: RecapSkeletonPainter.athleteJoints,
                skeletonColor: AppColors.burntOrange,
                labelColor: AppColors.burntOrange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PoseCard(
                label: 'Coach',
                joints: RecapSkeletonPainter.coachJoints,
                skeletonColor: AppColors.midTeal,
                labelColor: AppColors.midTeal,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PoseCard extends StatelessWidget {
  const _PoseCard({
    required this.label,
    required this.joints,
    required this.skeletonColor,
    required this.labelColor,
  });

  final String label;
  final List<Offset> joints;
  final Color skeletonColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.darkestNavy.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: RecapSkeletonFrame(
              joints: joints,
              color: skeletonColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
