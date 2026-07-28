import 'package:flutter/material.dart';

import '../../../core/sport/app_sport.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/sport_colors.dart';

/// Front / back body silhouettes with attention highlights.
class BodyHighlightSection extends StatelessWidget {
  const BodyHighlightSection({super.key, required this.sport});

  final AppSport sport;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = SportColors.of(sport);
    final soccer = sport == AppSport.soccer;

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
          soccer
              ? 'Plant leg, hamstrings, and ankles need attention today'
              : 'Highlighted regions need attention today',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
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
              Row(
                children: [
                  Expanded(
                    child: _SilhouetteCard(
                      label: 'Front',
                      painter: BodySilhouettePainter(
                        view: BodyView.front,
                        highlightShoulders: !soccer,
                        highlightHips: soccer,
                        highlightKnees: soccer,
                        highlightColor: colors.accent,
                        bodyColor: colors.action,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _SilhouetteCard(
                      label: 'Back',
                      painter: BodySilhouettePainter(
                        view: BodyView.back,
                        highlightShoulders: !soccer,
                        highlightUpperBack: !soccer,
                        highlightHamstrings: soccer,
                        highlightColor: colors.accent,
                        bodyColor: colors.action,
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
                      color: colors.accent,
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
    required this.highlightColor,
    required this.bodyColor,
    this.highlightShoulders = false,
    this.highlightUpperBack = false,
    this.highlightHips = false,
    this.highlightKnees = false,
    this.highlightHamstrings = false,
  });

  final BodyView view;
  final Color highlightColor;
  final Color bodyColor;
  final bool highlightShoulders;
  final bool highlightUpperBack;
  final bool highlightHips;
  final bool highlightKnees;
  final bool highlightHamstrings;

  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = bodyColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = bodyColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final highlightPaint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    final headCenter = Offset(cx, h * 0.10);
    final headRadius = w * 0.11;
    canvas.drawCircle(headCenter, headRadius, bodyPaint);
    canvas.drawCircle(headCenter, headRadius, outlinePaint);

    final neck = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx, h * 0.18),
        width: w * 0.08,
        height: h * 0.05,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(neck, bodyPaint);

    final torso = Path()
      ..moveTo(cx - w * 0.18, h * 0.22)
      ..lineTo(cx + w * 0.18, h * 0.22)
      ..lineTo(cx + w * 0.14, h * 0.52)
      ..lineTo(cx - w * 0.14, h * 0.52)
      ..close();
    canvas.drawPath(torso, bodyPaint);
    canvas.drawPath(torso, outlinePaint);

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

    if (highlightShoulders) {
      canvas.drawCircle(Offset(cx - w * 0.22, h * 0.26), w * 0.08, highlightPaint);
      canvas.drawCircle(Offset(cx + w * 0.22, h * 0.26), w * 0.08, highlightPaint);
    }

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

    if (highlightHips) {
      canvas.drawCircle(Offset(cx - w * 0.10, h * 0.52), w * 0.07, highlightPaint);
      canvas.drawCircle(Offset(cx + w * 0.10, h * 0.52), w * 0.07, highlightPaint);
    }

    if (highlightKnees) {
      canvas.drawCircle(Offset(cx - w * 0.08, h * 0.72), w * 0.06, highlightPaint);
      canvas.drawCircle(Offset(cx + w * 0.08, h * 0.72), w * 0.06, highlightPaint);
    }

    if (view == BodyView.back && highlightHamstrings) {
      final leftHam = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - w * 0.14, h * 0.56, w * 0.11, h * 0.18),
        const Radius.circular(8),
      );
      final rightHam = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + w * 0.03, h * 0.56, w * 0.11, h * 0.18),
        const Radius.circular(8),
      );
      canvas.drawRRect(leftHam, highlightPaint);
      canvas.drawRRect(rightHam, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BodySilhouettePainter oldDelegate) {
    return oldDelegate.view != view ||
        oldDelegate.highlightShoulders != highlightShoulders ||
        oldDelegate.highlightUpperBack != highlightUpperBack ||
        oldDelegate.highlightHips != highlightHips ||
        oldDelegate.highlightKnees != highlightKnees ||
        oldDelegate.highlightHamstrings != highlightHamstrings ||
        oldDelegate.highlightColor != highlightColor ||
        oldDelegate.bodyColor != bodyColor;
  }
}
