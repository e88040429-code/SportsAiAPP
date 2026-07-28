import 'package:flutter/material.dart';

import '../../../core/sport/app_sport.dart';
import '../../recap/data/recap_mock_data.dart';
import 'model_pose_library.dart';

/// Latest imported-clip analysis shared with Live Coach + Recap.
final ClipAnalysisController clipAnalysisController = ClipAnalysisController();

class ClipAnalysisResult {
  const ClipAnalysisResult({
    required this.clipName,
    required this.sport,
    required this.kind,
    required this.analyzedAt,
    required this.overallScore,
    required this.headline,
    required this.motionDescription,
    this.athleteDescription = '',
    required this.feedback,
    required this.jointComparisons,
    required this.phaseScores,
    required this.athletePeakJoints,
    required this.modelPeakJoints,
  });

  final String clipName;
  final AppSport sport;
  final SkillModelKind kind;
  final DateTime analyzedAt;
  final int overallScore;
  final String headline;

  /// Written “what I see in this clip” narrative for the athlete + AI context.
  final String motionDescription;

  /// Athlete-written description of what happens in the clip.
  final String athleteDescription;

  /// Actionable coaching cues (no joint-angle numbers).
  final List<String> feedback;

  /// Internal pose math — not shown in the UI.
  final List<JointComparison> jointComparisons;
  final List<RepScore> phaseScores;
  final List<Offset> athletePeakJoints;
  final List<Offset> modelPeakJoints;

  String get skillLabel => kind.labelFor(sport);

  bool get hasAthleteDescription => athleteDescription.trim().isNotEmpty;

  ClipAnalysisResult copyWith({
    SkillModelKind? kind,
    int? overallScore,
    String? headline,
    String? motionDescription,
    String? athleteDescription,
    List<String>? feedback,
    List<JointComparison>? jointComparisons,
    List<RepScore>? phaseScores,
    List<Offset>? athletePeakJoints,
    List<Offset>? modelPeakJoints,
  }) {
    return ClipAnalysisResult(
      clipName: clipName,
      sport: sport,
      kind: kind ?? this.kind,
      analyzedAt: analyzedAt,
      overallScore: overallScore ?? this.overallScore,
      headline: headline ?? this.headline,
      motionDescription: motionDescription ?? this.motionDescription,
      athleteDescription: athleteDescription ?? this.athleteDescription,
      feedback: feedback ?? this.feedback,
      jointComparisons: jointComparisons ?? this.jointComparisons,
      phaseScores: phaseScores ?? this.phaseScores,
      athletePeakJoints: athletePeakJoints ?? this.athletePeakJoints,
      modelPeakJoints: modelPeakJoints ?? this.modelPeakJoints,
    );
  }

  /// Compact block for Ask AI / coach prompts.
  String get aiContextBlock {
    final athleteBlock = hasAthleteDescription
        ? 'Athlete’s own description of the clip:\n${athleteDescription.trim()}\n\n'
        : 'Athlete has not written a clip description yet.\n\n';

    return '''
Athlete just imported clip "$clipName" ($skillLabel).
$athleteBlock
What the coach system sees in the motion:
$motionDescription

Coach cues already given:
${feedback.map((f) => '- $f').join('\n')}
Overall form score: $overallScore/100.
Respond as if you clearly watched this clip. Prefer the athlete’s description when they wrote one. Do not invent unrelated mistakes, and do not quote joint angles in degrees.
''';
  }
}

class ClipAnalysisController extends ChangeNotifier {
  ClipAnalysisResult? _latest;

  ClipAnalysisResult? get latest => _latest;
  bool get hasAnalysis => _latest != null;

  void publish(ClipAnalysisResult result) {
    _latest = result;
    notifyListeners();
  }

  void updateAthleteDescription(String description) {
    final current = _latest;
    if (current == null) return;
    _latest = current.copyWith(athleteDescription: description);
    notifyListeners();
  }

  void clear() {
    if (_latest == null) return;
    _latest = null;
    notifyListeners();
  }
}
