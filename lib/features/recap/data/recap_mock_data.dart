class JointComparison {
  const JointComparison({
    required this.joint,
    required this.athleteDegrees,
    required this.coachDegrees,
  });

  final String joint;
  final int athleteDegrees;
  final int coachDegrees;
}

class RepScore {
  const RepScore({
    required this.label,
    required this.score,
  });

  final String label;

  /// 0.0 – 1.0 quality score for the bar height.
  final double score;
}

/// Static mock content for the Session Recap screen.
abstract final class RecapMockData {
  static const int overallScore = 87;

  static const List<JointComparison> jointAngles = [
    JointComparison(joint: 'Elbow', athleteDegrees: 142, coachDegrees: 155),
    JointComparison(joint: 'Shoulder', athleteDegrees: 88, coachDegrees: 95),
    JointComparison(joint: 'Hip', athleteDegrees: 172, coachDegrees: 180),
    JointComparison(joint: 'Knee', athleteDegrees: 163, coachDegrees: 170),
    JointComparison(joint: 'Wrist', athleteDegrees: 110, coachDegrees: 120),
  ];

  static const List<RepScore> repScores = [
    RepScore(label: 'Rep 1', score: 0.72),
    RepScore(label: 'Rep 2', score: 0.85),
    RepScore(label: 'Rep 3', score: 0.68),
    RepScore(label: 'Rep 4', score: 0.91),
    RepScore(label: 'Rep 5', score: 0.78),
    RepScore(label: 'Rep 6', score: 0.88),
  ];
}
