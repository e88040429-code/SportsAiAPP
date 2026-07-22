import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Draws a fake 17-joint pose skeleton (COCO-style) for the Live Coach HUD.
class PoseSkeletonPainter extends CustomPainter {
  const PoseSkeletonPainter();

  /// Normalized joint positions in a volleyball follow-through stance.
  /// Order: nose, L/R eye, L/R ear, L/R shoulder, L/R elbow, L/R wrist,
  /// L/R hip, L/R knee, L/R ankle.
  static const List<Offset> _normalizedJoints = [
    Offset(0.50, 0.12), // 0 nose
    Offset(0.46, 0.10), // 1 left eye
    Offset(0.54, 0.10), // 2 right eye
    Offset(0.42, 0.12), // 3 left ear
    Offset(0.58, 0.12), // 4 right ear
    Offset(0.38, 0.24), // 5 left shoulder
    Offset(0.62, 0.24), // 6 right shoulder
    Offset(0.28, 0.36), // 7 left elbow
    Offset(0.78, 0.18), // 8 right elbow (raised)
    Offset(0.22, 0.48), // 9 left wrist
    Offset(0.88, 0.08), // 10 right wrist (follow-through)
    Offset(0.42, 0.48), // 11 left hip
    Offset(0.58, 0.48), // 12 right hip
    Offset(0.40, 0.68), // 13 left knee
    Offset(0.60, 0.68), // 14 right knee
    Offset(0.38, 0.88), // 15 left ankle
    Offset(0.62, 0.88), // 16 right ankle
  ];

  static const List<(int, int)> _bones = [
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

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppColors.midTeal
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()
      ..color = AppColors.midTeal
      ..style = PaintingStyle.fill;

    final jointRingPaint = Paint()
      ..color = AppColors.darkTeal
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final joints = [
      for (final p in _normalizedJoints)
        Offset(p.dx * size.width, p.dy * size.height),
    ];

    for (final (a, b) in _bones) {
      canvas.drawLine(joints[a], joints[b], linePaint);
    }

    for (final joint in joints) {
      canvas.drawCircle(joint, 5, jointPaint);
      canvas.drawCircle(joint, 7, jointRingPaint);
    }
  }

  @override
  bool shouldRepaint(covariant PoseSkeletonPainter oldDelegate) => false;
}

class FakeSkeletonOverlay extends StatelessWidget {
  const FakeSkeletonOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const AspectRatio(
      aspectRatio: 9 / 16,
      child: CustomPaint(
        painter: PoseSkeletonPainter(),
      ),
    );
  }
}
