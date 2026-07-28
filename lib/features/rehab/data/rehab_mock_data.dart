import '../../../core/sport/app_sport.dart';

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

/// Sport-aware mock content for the Rehab Hub screen.
abstract final class RehabMockData {
  static int readinessPercentFor(AppSport sport) => switch (sport) {
        AppSport.volleyball => 78,
        AppSport.soccer => 74,
      };

  static String readinessMessageFor(AppSport sport) => switch (sport) {
        AppSport.volleyball =>
          'Your body is ready for light training today.',
        AppSport.soccer =>
          'Legs feel workable — keep finishing volume light and sharp.',
      };

  static RehabProgram activeProgramFor(AppSport sport) => switch (sport) {
        AppSport.volleyball => const RehabProgram(
            name: 'Shoulder Recovery Program',
            startedLabel: 'Started Jan 10',
            progress: 0.42,
          ),
        AppSport.soccer => const RehabProgram(
            name: 'Hamstring & Plant-Foot Program',
            startedLabel: 'Started Feb 3',
            progress: 0.55,
          ),
      };

  static List<RehabExercise> todaysExercisesFor(AppSport sport) =>
      switch (sport) {
        AppSport.volleyball => const [
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
          ],
        AppSport.soccer => const [
            RehabExercise(
              id: 'hip-opener',
              name: 'Hip opener walkouts',
              duration: '2 sets x 10/side',
            ),
            RehabExercise(
              id: 'nordic-eccentric',
              name: 'Nordic curl eccentrics',
              duration: '3 sets x 5 reps',
            ),
            RehabExercise(
              id: 'single-leg-balance',
              name: 'Single-leg plant holds',
              duration: '3 sets x 20 sec/side',
            ),
            RehabExercise(
              id: 'ankle-alphabet',
              name: 'Ankle alphabet',
              duration: '2 rounds/foot',
            ),
            RehabExercise(
              id: 'foam-roll-hamstring',
              name: 'Foam roll hamstrings',
              duration: '8 minutes',
            ),
          ],
      };
}
