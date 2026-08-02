import 'package:flutter/material.dart';

import '../../../core/sport/app_sport.dart';
import '../../../core/theme/sport_colors.dart';
import '../pose/blazepose_to_coco.dart';

/// Draws a 17-joint pose skeleton (COCO-style) for the Live Coach HUD.
///
/// When [confidence] is provided, bones/joints below [minVisibility] are skipped
/// so missing landmarks do not draw lines to the origin.
class PoseSkeletonPainter extends CustomPainter {
  const PoseSkeletonPainter({
    required this.joints,
    required this.lineColor,
    required this.jointColor,
    this.confidence,
    this.minVisibility = BlazePoseToCoco.minVisibility,
  });

  final List<Offset> joints;
  final Color lineColor;
  final Color jointColor;
  final List<double>? confidence;
  final double minVisibility;

  /// Volleyball follow-through stance.
  static const List<Offset> volleyballJoints = [
    Offset(0.50, 0.12),
    Offset(0.46, 0.10),
    Offset(0.54, 0.10),
    Offset(0.42, 0.12),
    Offset(0.58, 0.12),
    Offset(0.38, 0.24),
    Offset(0.62, 0.24),
    Offset(0.28, 0.36),
    Offset(0.78, 0.18),
    Offset(0.22, 0.48),
    Offset(0.88, 0.08),
    Offset(0.42, 0.48),
    Offset(0.58, 0.48),
    Offset(0.40, 0.68),
    Offset(0.60, 0.68),
    Offset(0.38, 0.88),
    Offset(0.62, 0.88),
  ];

  /// Soccer strike / follow-through stance (plant left, kick right).
  static const List<Offset> soccerJoints = [
    Offset(0.48, 0.11),
    Offset(0.44, 0.09),
    Offset(0.52, 0.09),
    Offset(0.40, 0.11),
    Offset(0.56, 0.11),
    Offset(0.36, 0.24),
    Offset(0.60, 0.24),
    Offset(0.30, 0.38),
    Offset(0.68, 0.36),
    Offset(0.26, 0.50),
    Offset(0.74, 0.48),
    Offset(0.40, 0.50),
    Offset(0.56, 0.50),
    Offset(0.38, 0.70), // plant knee
    Offset(0.72, 0.62), // strike knee raised
    Offset(0.36, 0.90), // plant ankle
    Offset(0.86, 0.78), // strike ankle follow-through
  ];

  static List<Offset> jointsFor(AppSport sport) => switch (sport) {
        AppSport.volleyball => volleyballJoints,
        AppSport.soccer => soccerJoints,
      };

  static const List<(int, int)> bones = [
    (0, 1),
    (0, 2),
    (1, 3),
    (2, 4),
    (0, 5),
    (0, 6),
    (5, 6),
    (5, 7),
    (7, 9),
    (6, 8),
    (8, 10),
    (5, 11),
    (6, 12),
    (11, 12),
    (11, 13),
    (13, 15),
    (12, 14),
    (14, 16),
  ];

  bool _visible(int index) {
    if (index < 0 || index >= joints.length) return false;
    final conf = confidence;
    if (conf == null || conf.length != joints.length) return true;
    return conf[index] >= minVisibility;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (joints.isEmpty) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final jointRingPaint = Paint()
      ..color = jointColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final scaled = [
      for (final p in joints) Offset(p.dx * size.width, p.dy * size.height),
    ];

    for (final (a, b) in bones) {
      if (a >= scaled.length || b >= scaled.length) continue;
      if (!_visible(a) || !_visible(b)) continue;
      canvas.drawLine(scaled[a], scaled[b], linePaint);
    }

    for (var i = 0; i < scaled.length; i++) {
      if (!_visible(i)) continue;
      final joint = scaled[i];
      canvas.drawCircle(joint, 5, jointPaint);
      canvas.drawCircle(joint, 7, jointRingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PoseSkeletonPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor ||
        oldDelegate.jointColor != jointColor ||
        oldDelegate.minVisibility != minVisibility ||
        oldDelegate.joints != joints ||
        oldDelegate.confidence != confidence;
  }
}

class FakeSkeletonOverlay extends StatelessWidget {
  const FakeSkeletonOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appSportController,
      builder: (context, _) {
        final sport = appSportController.sport;
        final colors = SportColors.of(sport);
        final width = MediaQuery.sizeOf(context).width;
        final aspect = width >= 900 ? 16 / 10 : 9 / 16;

        return AspectRatio(
          aspectRatio: aspect,
          child: CustomPaint(
            painter: PoseSkeletonPainter(
              joints: PoseSkeletonPainter.jointsFor(sport),
              lineColor: colors.coachLine,
              jointColor: colors.coachJoint,
            ),
          ),
        );
      },
    );
  }
}
