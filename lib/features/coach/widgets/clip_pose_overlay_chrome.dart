import 'package:flutter/material.dart';

import '../../../core/sport/app_sport.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/sport_colors.dart';
import '../pose/pose_frame.dart';
import 'pose_skeleton_painter.dart';

/// Skeleton + status chip + optional toggle, layered on a clip video.
///
/// Place inside the same [AspectRatio] as [VideoPlayer] so normalized joints
/// stay aligned. Transport controls should sit above this in the [Stack].
class ClipPoseOverlayChrome extends StatelessWidget {
  const ClipPoseOverlayChrome({
    super.key,
    required this.sport,
    this.pose,
    this.progress,
    this.note,
    this.showSkeleton = true,
    this.onToggleSkeleton,
  });

  final AppSport sport;
  final PoseFrame? pose;

  /// 0–1 while extracting; null when idle.
  final double? progress;
  final String? note;
  final bool showSkeleton;
  final VoidCallback? onToggleSkeleton;

  @override
  Widget build(BuildContext context) {
    final colors = SportColors.of(sport);
    final theme = Theme.of(context);
    final showPainter = showSkeleton && pose != null;
    final progressValue = progress;
    final noteText = note?.trim();
    final showChip = progressValue != null ||
        (noteText != null && noteText.isNotEmpty);

    return Stack(
      fit: StackFit.expand,
      children: [
        if (showPainter)
          IgnorePointer(
            child: CustomPaint(
              key: const Key('clip-pose-skeleton'),
              painter: PoseSkeletonPainter(
                joints: pose!.joints,
                confidence: pose!.confidence,
                lineColor: colors.coachLine,
                jointColor: colors.coachJoint,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        if (showChip)
          Positioned(
            top: 8,
            left: 8,
            right: onToggleSkeleton != null ? 52 : 8,
            child: IgnorePointer(
              child: _OverlayStatusChip(
                progress: progressValue,
                note: noteText,
                textStyle: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.onCoachDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (onToggleSkeleton != null)
          Positioned(
            top: 2,
            right: 2,
            child: IconButton(
              tooltip: showSkeleton ? 'Hide skeleton' : 'Show skeleton',
              onPressed: onToggleSkeleton,
              icon: Icon(
                showSkeleton
                    ? Icons.accessibility_new
                    : Icons.accessibility_new_outlined,
                color: AppColors.onCoachDark,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black45,
              ),
            ),
          ),
      ],
    );
  }
}

class _OverlayStatusChip extends StatelessWidget {
  const _OverlayStatusChip({
    required this.progress,
    required this.note,
    required this.textStyle,
  });

  final double? progress;
  final String? note;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final progressValue = progress;
    final label = progressValue != null
        ? 'Reading poses… ${(progressValue.clamp(0, 1) * 100).round()}%'
        : (note ?? '');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        ),
      ),
    );
  }
}
