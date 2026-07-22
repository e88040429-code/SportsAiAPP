class CoachMetric {
  const CoachMetric({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

/// Static mock content for the Live Coach HUD shell.
abstract final class CoachMockData {
  static const String coachingCue =
      'Keep your elbow higher on the follow-through.';

  static const List<CoachMetric> metrics = [
    CoachMetric(label: 'Balance', value: '87%'),
    CoachMetric(label: 'Symmetry', value: '92%'),
    CoachMetric(label: 'Timing', value: '78%'),
  ];
}
