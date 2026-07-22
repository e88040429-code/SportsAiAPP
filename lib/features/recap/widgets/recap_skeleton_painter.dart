import 'package:flutter/material.dart';

/// 17-joint COCO-style skeleton for Recap comparison cards.
class RecapSkeletonPainter extends CustomPainter {
  const RecapSkeletonPainter({
    required this.joints,
    required this.color,
  });

  final List<Offset> joints;
  final Color color;

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

  /// Athlete pose — elbow slightly lower on the follow-through.
  static const List<Offset> athleteJoints = [
    Offset(0.50, 0.12),
    Offset(0.46, 0.10),
    Offset(0.54, 0.10),
    Offset(0.42, 0.12),
    Offset(0.58, 0.12),
    Offset(0.38, 0.24),
    Offset(0.62, 0.24),
    Offset(0.28, 0.36),
    Offset(0.74, 0.26),
    Offset(0.22, 0.48),
    Offset(0.82, 0.18),
    Offset(0.42, 0.48),
    Offset(0.58, 0.48),
    Offset(0.40, 0.68),
    Offset(0.60, 0.68),
    Offset(0.38, 0.88),
    Offset(0.62, 0.88),
  ];

  /// Coach reference pose — higher elbow / cleaner extension.
  static const List<Offset> coachJoints = [
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

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final scaled = [
      for (final p in joints) Offset(p.dx * size.width, p.dy * size.height),
    ];

    for (final (a, b) in bones) {
      canvas.drawLine(scaled[a], scaled[b], linePaint);
    }

    for (final joint in scaled) {
      canvas.drawCircle(joint, 4, jointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RecapSkeletonPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.joints != joints;
  }
}

class RecapSkeletonFrame extends StatelessWidget {
  const RecapSkeletonFrame({
    super.key,
    required this.joints,
    required this.color,
  });

  final List<Offset> joints;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: CustomPaint(
        painter: RecapSkeletonPainter(joints: joints, color: color),
      ),
    );
  }
}
