import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../data/rehab_mock_data.dart';

class TodaysExercisesChecklist extends StatelessWidget {
  const TodaysExercisesChecklist({
    super.key,
    required this.exercises,
    required this.completedIds,
    required this.onToggle,
  });

  final List<RehabExercise> exercises;
  final Set<String> completedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final doneCount = exercises.where((e) => completedIds.contains(e.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                "Today's Exercises",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              '$doneCount / ${exercises.length}',
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.midTeal,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
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
              for (var i = 0; i < exercises.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.onSurface.withValues(alpha: 0.06),
                  ),
                _ExerciseTile(
                  exercise: exercises[i],
                  isDone: completedIds.contains(exercises[i].id),
                  onToggle: () => onToggle(exercises[i].id),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    required this.exercise,
    required this.isDone,
    required this.onToggle,
  });

  final RehabExercise exercise;
  final bool isDone;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Checkbox(
              value: isDone,
              onChanged: (_) => onToggle(),
              activeColor: AppColors.midTeal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone
                          ? AppColors.onSurface.withValues(alpha: 0.45)
                          : AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exercise.duration,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
