import '../../../core/sport/app_sport.dart';

class CoachMetric {
  const CoachMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

/// Sport-aware mock content for the Live Coach HUD.
abstract final class CoachMockData {
  static String coachingCueFor(AppSport sport) => switch (sport) {
        AppSport.volleyball => 'Keep your elbow higher on the follow-through.',
        AppSport.soccer => 'Plant beside the ball and keep your chest over it.',
      };

  static List<CoachMetric> metricsFor(AppSport sport) => switch (sport) {
        AppSport.volleyball => const [
            CoachMetric(label: 'Balance', value: '87%'),
            CoachMetric(label: 'Symmetry', value: '92%'),
            CoachMetric(label: 'Timing', value: '78%'),
          ],
        AppSport.soccer => const [
            CoachMetric(label: 'Plant', value: '84%'),
            CoachMetric(label: 'Contact', value: '79%'),
            CoachMetric(label: 'Follow', value: '88%'),
          ],
      };
}
