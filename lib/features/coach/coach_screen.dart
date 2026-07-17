import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class CoachScreen extends StatelessWidget {
  const CoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.coachDark,
      appBar: AppBar(
        backgroundColor: AppColors.coachDark,
        foregroundColor: AppColors.onCoachDark,
        title: const Text('Live Coach'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.videocam_outlined, size: 56, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Coach',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.onCoachDark,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pose tracking camera HUD coming soon.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onCoachDark.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
