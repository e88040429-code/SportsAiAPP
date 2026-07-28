import '../../../core/sport/app_sport.dart';

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

/// Sport-aware mock content for the Session Recap screen.
abstract final class RecapMockData {
  static int overallScoreFor(AppSport sport) => switch (sport) {
        AppSport.volleyball => 87,
        AppSport.soccer => 82,
      };

  static List<JointComparison> jointAnglesFor(AppSport sport) => switch (sport) {
        AppSport.volleyball => const [
            JointComparison(joint: 'Elbow', athleteDegrees: 142, coachDegrees: 155),
            JointComparison(joint: 'Shoulder', athleteDegrees: 88, coachDegrees: 95),
            JointComparison(joint: 'Hip', athleteDegrees: 172, coachDegrees: 180),
            JointComparison(joint: 'Knee', athleteDegrees: 163, coachDegrees: 170),
            JointComparison(joint: 'Wrist', athleteDegrees: 110, coachDegrees: 120),
          ],
        AppSport.soccer => const [
            JointComparison(joint: 'Plant knee', athleteDegrees: 155, coachDegrees: 165),
            JointComparison(joint: 'Strike hip', athleteDegrees: 118, coachDegrees: 130),
            JointComparison(joint: 'Strike knee', athleteDegrees: 142, coachDegrees: 155),
            JointComparison(joint: 'Ankle lock', athleteDegrees: 95, coachDegrees: 105),
            JointComparison(joint: 'Trunk lean', athleteDegrees: 12, coachDegrees: 8),
          ],
      };

  static List<RepScore> repScoresFor(AppSport sport) => switch (sport) {
        AppSport.volleyball => const [
            RepScore(label: 'Rep 1', score: 0.72),
            RepScore(label: 'Rep 2', score: 0.85),
            RepScore(label: 'Rep 3', score: 0.68),
            RepScore(label: 'Rep 4', score: 0.91),
            RepScore(label: 'Rep 5', score: 0.78),
            RepScore(label: 'Rep 6', score: 0.88),
          ],
        AppSport.soccer => const [
            RepScore(label: 'Rep 1', score: 0.70),
            RepScore(label: 'Rep 2', score: 0.76),
            RepScore(label: 'Rep 3', score: 0.83),
            RepScore(label: 'Rep 4', score: 0.69),
            RepScore(label: 'Rep 5', score: 0.88),
            RepScore(label: 'Rep 6', score: 0.81),
          ],
      };
}
