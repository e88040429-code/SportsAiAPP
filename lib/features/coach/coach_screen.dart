import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import 'data/coach_mock_data.dart';
import 'widgets/coach_camera_preview.dart';
import 'widgets/coach_metrics_bar.dart';
import 'widgets/cue_bubble.dart';
import 'widgets/pose_skeleton_painter.dart';
import 'widgets/record_button.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  bool _isRecording = false;

  void _onBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _toggleRecording() {
    setState(() => _isRecording = !_isRecording);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.coachDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Live camera (FaceTime / front cam when available)
          const CoachCameraPreview(),

          // Soft vignette so HUD text stays readable
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.darkestNavy.withValues(alpha: 0.60),
                    AppColors.darkestNavy.withValues(alpha: 0.20),
                    AppColors.darkestNavy.withValues(alpha: 0.60),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Stack(
              children: [
                // Pose overlay on top of the live feed
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 28, vertical: 72),
                    child: FakeSkeletonOverlay(),
                  ),
                ),

                // Top chrome: back + title
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: _onBack,
                          icon: const Icon(Icons.arrow_back),
                          color: AppColors.onCoachDark,
                          tooltip: 'Back',
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Live Coach',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.onCoachDark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        if (_isRecording)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.darkRed.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.onCoachDark,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'REC',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.onCoachDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Cue bubble near top
                Positioned(
                  top: 56,
                  left: 20,
                  right: 20,
                  child: CueBubble(message: CoachMockData.coachingCue),
                ),

                // Metrics + record at bottom
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CoachMetricsBar(metrics: CoachMockData.metrics),
                      const SizedBox(height: 20),
                      RecordButton(
                        isRecording: _isRecording,
                        onPressed: _toggleRecording,
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
