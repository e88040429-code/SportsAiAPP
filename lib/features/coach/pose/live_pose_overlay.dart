import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/sport/app_sport.dart';
import '../../../core/theme/sport_colors.dart';
import '../widgets/pose_skeleton_painter.dart';
import 'pose_frame.dart';

/// Draws the latest live [PoseFrame] with [PoseSkeletonPainter].
///
/// Place this inside the same letterboxed camera rect as [CameraPreview] so
/// normalized joints align with the video.
class LivePoseOverlay extends StatelessWidget {
  const LivePoseOverlay({
    super.key,
    required this.listenable,
  });

  final ValueListenable<PoseFrame?> listenable;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([listenable, appSportController]),
      builder: (context, _) {
        final frame = listenable.value;
        if (frame == null) return const SizedBox.expand();

        final colors = SportColors.of(appSportController.sport);
        return CustomPaint(
          painter: PoseSkeletonPainter(
            joints: frame.joints,
            confidence: frame.confidence,
            lineColor: colors.coachLine,
            jointColor: colors.coachJoint,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}
