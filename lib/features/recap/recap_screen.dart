import 'package:flutter/material.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Session Recap'),
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
              const SizedBox(height: 8),
              Center(
                child: ScoreCircle(score: RecapMockData.overallScore),
              ),
              const SizedBox(height: 28),
              const YouVsCoachSection(),
              const SizedBox(height: 28),
              const JointAnglesList(comparisons: RecapMockData.jointAngles),
              const SizedBox(height: 28),
              const RepBarChart(reps: RecapMockData.repScores),
            ],
          ),
        ),
      ),
    );
  }
}
