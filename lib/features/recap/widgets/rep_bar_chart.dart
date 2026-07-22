import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/recap_mock_data.dart';

class RepBarChart extends StatelessWidget {
  const RepBarChart({super.key, required this.reps});

  final List<RepScore> reps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rep Quality',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Form score by rep this session',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.onSurface.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
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
              SizedBox(
                height: 160,
                width: double.infinity,
                child: CustomPaint(
                  painter: _RepBarsPainter(reps: reps),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  for (final rep in reps)
                    Expanded(
                      child: Text(
                        rep.label,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.onSurface.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w600,
                        ),
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

class _RepBarsPainter extends CustomPainter {
  const _RepBarsPainter({required this.reps});

  final List<RepScore> reps;

  @override
  void paint(Canvas canvas, Size size) {
    if (reps.isEmpty) return;

    final barPaint = Paint()
      ..color = AppColors.burntOrange
      ..style = PaintingStyle.fill;

    final trackPaint = Paint()
      ..color = AppColors.darkTeal.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    final slotWidth = size.width / reps.length;
    final barWidth = slotWidth * 0.48;
    const radius = Radius.circular(8);

    for (var i = 0; i < reps.length; i++) {
      final score = reps[i].score.clamp(0.0, 1.0);
      final centerX = slotWidth * i + slotWidth / 2;
      final left = centerX - barWidth / 2;
      final trackRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, 0, barWidth, size.height),
        radius,
      );
      canvas.drawRRect(trackRect, trackPaint);

      final barHeight = size.height * score;
      final top = size.height - barHeight;
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        radius,
      );
      canvas.drawRRect(barRect, barPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RepBarsPainter oldDelegate) {
    return oldDelegate.reps != reps;
  }
}
