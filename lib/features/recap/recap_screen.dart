import 'package:flutter/material.dart';

import '../../core/sport/app_sport.dart';
import '../../core/theme/sport_colors.dart';
import '../coach/data/clip_analysis_session.dart';
import 'data/recap_mock_data.dart';
import 'widgets/joint_angles_list.dart';
import 'widgets/rep_bar_chart.dart';
import 'widgets/score_circle.dart';
import 'widgets/you_vs_coach_section.dart';

class RecapScreen extends StatelessWidget {
  const RecapScreen({super.key});

  void _onShare(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        appSportController,
        clipAnalysisController,
      ]),
      builder: (context, _) {
        final sport = appSportController.sport;
        final analysis = clipAnalysisController.latest;
        final fromClip = analysis != null && analysis.sport == sport;
        final colors = SportColors.of(sport);
        final theme = Theme.of(context);

        final score = fromClip
            ? analysis.overallScore
            : RecapMockData.overallScoreFor(sport);
        final reps = fromClip
            ? analysis.phaseScores
            : RecapMockData.repScoresFor(sport);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              fromClip ? '${sport.label} Review' : '${sport.label} Recap',
            ),
            actions: [
              IconButton(
                onPressed: () => _onShare(context),
                icon: const Icon(Icons.ios_share),
                tooltip: 'Share',
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (fromClip) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: colors.action.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colors.action.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            analysis.clipName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (analysis.hasAthleteDescription) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Your description',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: colors.action,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              analysis.athleteDescription.trim(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                height: 1.45,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Text(
                            'What I see in your clip',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.action,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            analysis.motionDescription,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else ...[
                    Text(
                      'Import a clip in Live Coach to fill this review with your analysis.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  const SizedBox(height: 8),
                  Center(child: ScoreCircle(score: score)),
                  if (fromClip) ...[
                    const SizedBox(height: 12),
                    Text(
                      analysis.headline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Written coach feedback',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final tip in analysis.feedback)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              size: 18,
                              color: colors.action,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                tip,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ] else ...[
                    const SizedBox(height: 28),
                    YouVsCoachSection(sport: sport),
                    const SizedBox(height: 28),
                    JointAnglesList(
                      comparisons: RecapMockData.jointAnglesFor(sport),
                    ),
                  ],
                  const SizedBox(height: 28),
                  RepBarChart(
                    reps: reps,
                    title: fromClip ? 'Phase quality' : 'Rep quality',
                    subtitle: fromClip
                        ? 'How each part of the motion compared to the model'
                        : 'Form score by rep this session',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
