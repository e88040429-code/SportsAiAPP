class RehabExercise {
  const RehabExercise({
    required this.id,
    required this.name,
    required this.duration,
  });

  final String id;
  final String name;
  final String duration;
}

class RehabProgram {
  const RehabProgram({
    required this.name,
    required this.startedLabel,
    required this.progress,
  });

  final String name;
  final String startedLabel;

  /// 0.0 – 1.0 progress through the program.
  final double progress;
}

/// Static mock content for the Rehab Hub screen.
abstract final class RehabMockData {
  static const int readinessPercent = 78;
  static const String readinessMessage =
      'Your body is ready for light training today.';

  static const RehabProgram activeProgram = RehabProgram(
    name: 'Shoulder Recovery Program',
    startedLabel: 'Started Jan 10',
    progress: 0.42,
  );

  static const List<RehabExercise> todaysExercises = [
    RehabExercise(
      id: 'shoulder-circles',
      name: 'Shoulder circles',
      duration: '2 sets x 15 reps',
    ),
    RehabExercise(
      id: 'band-pull',
      name: 'Resistance band pull',
      duration: '3 sets x 12 reps',
    ),
    RehabExercise(
      id: 'wall-slide',
      name: 'Wall slide',
      duration: '3 sets x 10 reps',
    ),
    RehabExercise(
      id: 'ice-compress',
      name: 'Ice and compress',
      duration: '15 minutes',
    ),
    RehabExercise(
      id: 'foam-roll',
      name: 'Foam roll upper back',
      duration: '10 minutes',
    ),
  ];
}
