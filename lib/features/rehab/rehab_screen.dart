import 'package:flutter/material.dart';

import 'data/rehab_mock_data.dart';
import 'widgets/active_program_card.dart';
import 'widgets/body_highlight_section.dart';
import 'widgets/complete_session_button.dart';
import 'widgets/readiness_card.dart';
import 'widgets/todays_exercises_checklist.dart';

class RehabScreen extends StatefulWidget {
  const RehabScreen({super.key});

  @override
  State<RehabScreen> createState() => _RehabScreenState();
}

class _RehabScreenState extends State<RehabScreen> {
  final Set<String> _completedIds = {};

  void _toggleExercise(String id) {
    setState(() {
      if (_completedIds.contains(id)) {
        _completedIds.remove(id);
      } else {
        _completedIds.add(id);
      }
    });
  }

  void _onCompleteSession() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Great work! Session logged.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Rehab Hub',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Recovery readiness and daily rehab plan',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 20),
              const ReadinessCard(
                percent: RehabMockData.readinessPercent,
                message: RehabMockData.readinessMessage,
              ),
              const SizedBox(height: 28),
              const BodyHighlightSection(),
              const SizedBox(height: 28),
              const ActiveProgramCard(program: RehabMockData.activeProgram),
              const SizedBox(height: 28),
              TodaysExercisesChecklist(
                exercises: RehabMockData.todaysExercises,
                completedIds: _completedIds,
                onToggle: _toggleExercise,
              ),
              const SizedBox(height: 24),
              CompleteSessionButton(onPressed: _onCompleteSession),
            ],
          ),
        ),
      ),
    );
  }
}
