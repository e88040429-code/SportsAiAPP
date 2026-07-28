import 'package:flutter/material.dart';

import '../../../core/sport/app_sport.dart';
import '../../../core/theme/sport_colors.dart';
import 'recap_skeleton_painter.dart';

class YouVsCoachSection extends StatelessWidget {
  const YouVsCoachSection({
    super.key,
    required this.sport,
    this.athleteJoints,
    this.coachJoints,
    this.youLabel = 'You',
    this.coachLabel = 'Coach',
  });

  final AppSport sport;
  final List<Offset>? athleteJoints;
  final List<Offset>? coachJoints;
  final String youLabel;
  final String coachLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = SportColors.of(sport);

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
                label: youLabel,
                joints: athleteJoints ??
                    RecapSkeletonPainter.athleteJointsFor(sport),
                skeletonColor: colors.primary,
                labelColor: colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PoseCard(
                label: coachLabel,
                joints:
                    coachJoints ?? RecapSkeletonPainter.coachJointsFor(sport),
                skeletonColor: colors.action,
                labelColor: colors.action,
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
    final onBg = theme.colorScheme.onSurface;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
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
              color: onBg.withValues(alpha: 0.04),
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
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
