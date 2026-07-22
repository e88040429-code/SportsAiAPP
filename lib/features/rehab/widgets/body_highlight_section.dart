import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Front / back body silhouettes with attention highlights.
class BodyHighlightSection extends StatelessWidget {
  const BodyHighlightSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Body Focus',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Highlighted regions need attention today',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
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
              Row(
                children: [
                  Expanded(
                    child: _SilhouetteCard(
                      label: 'Front',
                      painter: const BodySilhouettePainter(
                        view: BodyView.front,
                        highlightShoulders: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SilhouetteCard(
                      label: 'Back',
                      painter: const BodySilhouettePainter(
                        view: BodyView.back,
                        highlightShoulders: true,
                        highlightUpperBack: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.amber,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Needs attention',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SilhouetteCard extends StatelessWidget {
  const _SilhouetteCard({
    required this.label,
    required this.painter,
  });

  final String label;
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 2 / 3,
          child: CustomPaint(painter: painter),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

enum BodyView { front, back }

class BodySilhouettePainter extends CustomPainter {
  const BodySilhouettePainter({
    required this.view,
    this.highlightShoulders = false,
    this.highlightUpperBack = false,
  });

  final BodyView view;
  final bool highlightShoulders;
  final bool highlightUpperBack;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = AppColors.darkTeal.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = AppColors.darkTeal.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final highlightPaint = Paint()
      ..color = AppColors.amber
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Head
    final headCenter = Offset(cx, h * 0.10);
    final headRadius = w * 0.11;
    canvas.drawCircle(headCenter, headRadius, bodyPaint);
    canvas.drawCircle(headCenter, headRadius, outlinePaint);

    // Neck
    final neck = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, h * 0.18),
        width: w * 0.08,
        height: h * 0.05,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(neck, bodyPaint);

    // Torso
    final torso = Path()
      ..moveTo(cx - w * 0.18, h * 0.22)
      ..lineTo(cx + w * 0.18, h * 0.22)
      ..lineTo(cx + w * 0.14, h * 0.52)
      ..lineTo(cx - w * 0.14, h * 0.52)
      ..close();
    canvas.drawPath(torso, bodyPaint);
    canvas.drawPath(torso, outlinePaint);

    // Arms
    final leftArm = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - w * 0.38, h * 0.24, w * 0.12, h * 0.28),
      const Radius.circular(8),
    );
    final rightArm = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx + w * 0.26, h * 0.24, w * 0.12, h * 0.28),
      const Radius.circular(8),
    );
    canvas.drawRRect(leftArm, bodyPaint);
    canvas.drawRRect(rightArm, bodyPaint);
    canvas.drawRRect(leftArm, outlinePaint);
    canvas.drawRRect(rightArm, outlinePaint);

    // Legs
    final leftLeg = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - w * 0.14, h * 0.52, w * 0.11, h * 0.40),
      const Radius.circular(8),
    );
    final rightLeg = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx + w * 0.03, h * 0.52, w * 0.11, h * 0.40),
      const Radius.circular(8),
    );
    canvas.drawRRect(leftLeg, bodyPaint);
    canvas.drawRRect(rightLeg, bodyPaint);
    canvas.drawRRect(leftLeg, outlinePaint);
    canvas.drawRRect(rightLeg, outlinePaint);

    // Highlights — shoulders (both views)
    if (highlightShoulders) {
      canvas.drawCircle(Offset(cx - w * 0.22, h * 0.26), w * 0.08, highlightPaint);
      canvas.drawCircle(Offset(cx + w * 0.22, h * 0.26), w * 0.08, highlightPaint);
    }

    // Upper back highlight (back view only)
    if (view == BodyView.back && highlightUpperBack) {
      final upperBack = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, h * 0.34),
          width: w * 0.22,
          height: h * 0.10,
        ),
        const Radius.circular(10),
      );
      canvas.drawRRect(upperBack, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BodySilhouettePainter oldDelegate) {
    return oldDelegate.view != view ||
        oldDelegate.highlightShoulders != highlightShoulders ||
        oldDelegate.highlightUpperBack != highlightUpperBack;
  }
}
