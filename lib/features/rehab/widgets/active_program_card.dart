import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/rehab_mock_data.dart';

class ActiveProgramCard extends StatelessWidget {
  const ActiveProgramCard({super.key, required this.program});

  final RehabProgram program;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (program.progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Program',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.midTeal.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.healing_outlined,
                      color: AppColors.midTeal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          program.startedLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$percent%',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.midTeal,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 10,
                width: double.infinity,
                child: CustomPaint(
                  painter: _ProgramProgressPainter(progress: program.progress),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgramProgressPainter extends CustomPainter {
  const _ProgramProgressPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = AppColors.midTeal.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;

    final fillPaint = Paint()
      ..color = AppColors.midTeal
      ..style = PaintingStyle.fill;

    final track = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(6),
    );
    canvas.drawRRect(track, trackPaint);

    final fillWidth = size.width * progress.clamp(0.0, 1.0);
    if (fillWidth <= 0) return;

    final fill = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, fillWidth, size.height),
      const Radius.circular(6),
    );
    canvas.drawRRect(fill, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgramProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
