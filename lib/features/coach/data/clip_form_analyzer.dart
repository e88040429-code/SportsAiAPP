import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/sport/app_sport.dart';
import '../../recap/data/recap_mock_data.dart';
import 'clip_analysis_session.dart';
import 'model_pose_library.dart';

/// Derives written coaching feedback from athlete vs model stick poses.
/// Joint math stays internal — athletes only see narrative text.
abstract final class ClipFormAnalyzer {
  static ClipAnalysisResult analyze({
    required String clipName,
    required AppSport sport,
    required SkillModelKind kind,
    required List<List<Offset>> athleteSeq,
    required List<List<Offset>> modelSeq,
  }) {
    final athletePeak = ModelPoseLibrary.poseAt(athleteSeq, 0.72);
    final modelPeak = ModelPoseLibrary.poseAt(modelSeq, 0.72);

    final joints = _jointComparisons(sport, kind, athletePeak, modelPeak);
    final similarity = _poseSimilarity(athletePeak, modelPeak);
    final score = (similarity * 100).round().clamp(55, 96);
    final phaseScores = _phaseScores(athleteSeq, modelSeq);
    final issues = _rankedIssues(joints);

    final motionDescription = _motionDescription(
      clipName: clipName,
      sport: sport,
      kind: kind,
      score: score,
      issues: issues,
      athleteSeq: athleteSeq,
      modelSeq: modelSeq,
    );

    final feedback = _writtenFeedback(
      sport: sport,
      kind: kind,
      score: score,
      issues: issues,
    );

    final headline = score >= 88
        ? 'Looking sharp — only fine-tuning left.'
        : score >= 75
            ? 'Good clip. A few form habits are holding you back.'
            : 'I can see clear form gaps — focus on the cues below.';

    return ClipAnalysisResult(
      clipName: clipName,
      sport: sport,
      kind: kind,
      analyzedAt: DateTime.now(),
      overallScore: score,
      headline: headline,
      motionDescription: motionDescription,
      athleteDescription: '',
      feedback: feedback,
      jointComparisons: joints,
      phaseScores: phaseScores,
      athletePeakJoints: athletePeak,
      modelPeakJoints: modelPeak,
    );
  }

  static double _poseSimilarity(List<Offset> a, List<Offset> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0.7;
    var total = 0.0;
    for (var i = 0; i < a.length; i++) {
      total += (a[i] - b[i]).distance;
    }
    final avg = total / a.length;
    return (1.0 - avg * 6.5).clamp(0.55, 0.96);
  }

  static List<JointComparison> _jointComparisons(
    AppSport sport,
    SkillModelKind kind,
    List<Offset> athlete,
    List<Offset> model,
  ) {
    final specs = sport == AppSport.volleyball
        ? (kind == SkillModelKind.receive
            ? const [
                _JointSpec('platform', 'forearm platform', 5, 7, 9),
                _JointSpec('knee', 'knee bend', 11, 13, 15),
                _JointSpec('hip', 'hip hinge', 5, 11, 13),
                _JointSpec('shoulder', 'shoulder line', 7, 5, 6),
                _JointSpec('base', 'base width', 15, 11, 16),
              ]
            : const [
                _JointSpec('elbow', 'hitting elbow', 6, 8, 10),
                _JointSpec('shoulder', 'shoulder open', 8, 6, 12),
                _JointSpec('hip', 'hip drive', 6, 12, 14),
                _JointSpec('knee', 'plant knee', 11, 13, 15),
                _JointSpec('wrist', 'wrist finish', 6, 8, 10),
              ])
        : (kind == SkillModelKind.receive
            ? const [
                _JointSpec('plant', 'plant leg', 11, 13, 15),
                _JointSpec('ankle', 'cushioning ankle', 12, 14, 16),
                _JointSpec('hip', 'hip set', 5, 11, 13),
                _JointSpec('trunk', 'trunk posture', 0, 11, 12),
                _JointSpec('arms', 'arm balance', 5, 7, 9),
              ]
            : const [
                _JointSpec('plant', 'plant leg', 11, 13, 15),
                _JointSpec('hip', 'strike hip', 6, 12, 14),
                _JointSpec('knee', 'strike knee', 12, 14, 16),
                _JointSpec('ankle', 'striking ankle', 12, 14, 16),
                _JointSpec('trunk', 'trunk posture', 0, 11, 12),
              ]);

    return [
      for (final s in specs)
        JointComparison(
          joint: s.key,
          athleteDegrees: _angleDeg(athlete, s.a, s.b, s.c),
          coachDegrees: _angleDeg(model, s.a, s.b, s.c),
        ),
    ];
  }

  static int _angleDeg(List<Offset> joints, int a, int b, int c) {
    if (joints.length <= math.max(a, math.max(b, c))) return 0;
    final ba = joints[a] - joints[b];
    final bc = joints[c] - joints[b];
    final dot = ba.dx * bc.dx + ba.dy * bc.dy;
    final mag = ba.distance * bc.distance;
    if (mag < 1e-6) return 0;
    final cos = (dot / mag).clamp(-1.0, 1.0);
    return (math.acos(cos) * 180 / math.pi).round();
  }

  static List<RepScore> _phaseScores(
    List<List<Offset>> athleteSeq,
    List<List<Offset>> modelSeq,
  ) {
    const labels = ['Ready', 'Load', 'Contact', 'Follow'];
    return [
      for (var i = 0; i < labels.length; i++)
        RepScore(
          label: labels[i],
          score: _poseSimilarity(
            ModelPoseLibrary.poseAt(athleteSeq, i / (labels.length - 1)),
            ModelPoseLibrary.poseAt(modelSeq, i / (labels.length - 1)),
          ),
        ),
    ];
  }

  static List<_Issue> _rankedIssues(List<JointComparison> joints) {
    final issues = <_Issue>[
      for (final j in joints)
        _Issue(
          key: j.joint,
          delta: j.athleteDegrees - j.coachDegrees,
          magnitude: (j.athleteDegrees - j.coachDegrees).abs(),
        ),
    ]..sort((a, b) => b.magnitude.compareTo(a.magnitude));
    return issues;
  }

  /// Rich narrative so coaches / AI clearly “see” the clip.
  static String _motionDescription({
    required String clipName,
    required AppSport sport,
    required SkillModelKind kind,
    required int score,
    required List<_Issue> issues,
    required List<List<Offset>> athleteSeq,
    required List<List<Offset>> modelSeq,
  }) {
    final skill = kind.labelFor(sport).toLowerCase();
    final ready = _poseSimilarity(
      ModelPoseLibrary.poseAt(athleteSeq, 0.0),
      ModelPoseLibrary.poseAt(modelSeq, 0.0),
    );
    final load = _poseSimilarity(
      ModelPoseLibrary.poseAt(athleteSeq, 0.35),
      ModelPoseLibrary.poseAt(modelSeq, 0.35),
    );
    final contact = _poseSimilarity(
      ModelPoseLibrary.poseAt(athleteSeq, 0.72),
      ModelPoseLibrary.poseAt(modelSeq, 0.72),
    );
    final follow = _poseSimilarity(
      ModelPoseLibrary.poseAt(athleteSeq, 1.0),
      ModelPoseLibrary.poseAt(modelSeq, 1.0),
    );

    final startFeel = ready >= 0.85
        ? 'You start balanced and athletic'
        : ready >= 0.72
            ? 'Your ready stance is usable but a little rushed'
            : 'Your ready stance looks narrow and upright';

    final loadFeel = load >= 0.85
        ? 'the load phase builds cleanly'
        : load >= 0.72
            ? 'the load is okay but a bit late'
            : 'the load phase looks rushed and shallow';

    final contactFeel = contact >= 0.85
        ? 'contact shape is close to the model'
        : contact >= 0.72
            ? 'contact is close but not fully connected'
            : 'contact drifts away from the ideal shape';

    final followFeel = follow >= 0.85
        ? 'follow-through finishes with good control.'
        : follow >= 0.72
            ? 'follow-through fades a little early.'
            : 'follow-through cuts off before the motion fully finishes.';

    final top = issues.isEmpty ? null : issues.first;
    final bodyNote = _bodyLanguage(sport, kind, top);

    return 'In "$clipName" I’m watching a $skill. $startFeel, $loadFeel, '
        '$contactFeel, and $followFeel $bodyNote '
        'Overall this reads as a ${score >= 85 ? 'high-quality' : score >= 75 ? 'solid training' : 'developing'} '
        'rep that the coach AI can coach from clearly.';
  }

  static String _bodyLanguage(
    AppSport sport,
    SkillModelKind kind,
    _Issue? top,
  ) {
    if (top == null || top.magnitude < 6) {
      return 'Body lines stay fairly close to the model through the swing.';
    }

    final open = top.delta > 0;
    if (sport == AppSport.volleyball) {
      if (kind == SkillModelKind.receive) {
        return switch (top.key) {
          'platform' => open
              ? 'Your platform looks a little broken — elbows aren’t presenting as flat as the model.'
              : 'Your platform looks pinched; the forearms need a flatter, wider shelf.',
          'knee' || 'hip' => open
              ? 'Your hips stay higher than the model, so you’re not getting under the ball enough.'
              : 'You’re sitting deeper than needed and arriving late to the ball line.',
          'base' => 'Your base looks tight; a wider athletic stance would stabilize the pass.',
          _ => 'Shoulder and platform alignment drift compared with the perfect receive model.',
        };
      }
      return switch (top.key) {
        'elbow' => open
            ? 'The hitting elbow stays too open and late into contact.'
            : 'The hitting elbow looks cramped, so the swing doesn’t fully whip through.',
        'shoulder' || 'hip' => open
            ? 'You’re not rotating the hips and shoulders through as freely as the model.'
            : 'Rotation is a bit forced; the swing loses a smooth whip.',
        'knee' => 'The plant leg isn’t setting a firm base before the arm swing.',
        _ => 'The arm path finishes short of the ideal high follow-through.',
      };
    }

    if (kind == SkillModelKind.receive) {
      return switch (top.key) {
        'ankle' || 'plant' =>
          'The receiving foot isn’t softening early enough, so the first touch looks bouncy.',
        'hip' || 'trunk' =>
          'Your posture over the ball is upright; the model stays lower and calmer on contact.',
        _ => 'Balance through the first touch drifts compared with the model.',
      };
    }

    return switch (top.key) {
      'plant' =>
        'The plant leg looks soft, so the strike doesn’t have a firm base.',
      'hip' || 'knee' => open
          ? 'The striking leg isn’t swinging through freely enough at contact.'
          : 'The striking path feels cramped — hip and knee aren’t opening through the ball.',
      'ankle' =>
        'The striking ankle looks unlocked, so contact won’t feel crisp.',
      _ => 'Trunk posture leans off the ideal striking line.',
    };
  }

  static List<String> _writtenFeedback({
    required AppSport sport,
    required SkillModelKind kind,
    required int score,
    required List<_Issue> issues,
  }) {
    final tips = <String>[];
    for (final issue in issues.take(3)) {
      tips.add(_cueForIssue(sport, kind, issue));
    }
    tips.add(_closingCue(sport, kind, score));
    return tips.where((t) => t.trim().isNotEmpty).toList();
  }

  static String _cueForIssue(
    AppSport sport,
    SkillModelKind kind,
    _Issue issue,
  ) {
    if (issue.magnitude < 5) {
      return 'Keep repeating this rhythm — you’re already close on this piece.';
    }

    if (sport == AppSport.volleyball) {
      if (kind == SkillModelKind.receive) {
        return switch (issue.key) {
          'platform' =>
            'Flatten the forearms into one shelf and point the platform where you want the ball to go.',
          'knee' || 'hip' =>
            'Drop the hips earlier and meet the ball out in front instead of under your chin.',
          'base' =>
            'Widen your feet and stay light so you can shuffle to the ball before you swing the arms.',
          _ =>
            'Square the shoulders to the target and finish the pass with quiet hands.',
        };
      }
      return switch (issue.key) {
        'elbow' =>
          'Load the hitting elbow high and early, then whip through contact instead of pushing.',
        'shoulder' || 'hip' =>
          'Lead with the hips, then let the shoulders and arm follow so the swing stays connected.',
        'knee' =>
          'Plant hard, pause a beat, then swing — don’t jump and hit in one blur.',
        _ =>
          'Finish the hand high past the ball and hold the open shoulder a little longer.',
      };
    }

    if (kind == SkillModelKind.receive) {
      return switch (issue.key) {
        'ankle' || 'plant' =>
          'Arrive early, then soften the ankle on contact so the ball dies at your feet.',
        'hip' || 'trunk' =>
          'Stay slightly over the ball with calm posture — don’t lean back as it arrives.',
        _ =>
          'Use your arms for balance and keep the first touch simple and close.',
      };
    }

    return switch (issue.key) {
      'plant' =>
        'Set a firm plant first, then swing — power starts from that still leg.',
      'hip' || 'knee' =>
        'Drive the striking hip through the ball and let the knee whip naturally after contact.',
      'ankle' =>
        'Lock the striking ankle so the foot feels like a firm surface at contact.',
      _ =>
        'Keep your chest over the ball through follow-through instead of falling away.',
    };
  }

  static String _closingCue(AppSport sport, SkillModelKind kind, int score) {
    if (sport == AppSport.volleyball) {
      if (kind == SkillModelKind.receive) {
        return score >= 80
            ? 'Next reps: quiet feet early, flat platform, eyes on the target after contact.'
            : 'Next reps: wider base, earlier hips, flatter platform — film one more pass after that.';
      }
      return score >= 80
          ? 'Next reps: high elbow load, hip first, long finish through the ball.'
          : 'Next reps: plant, pause, then swing — chase a higher finish on every contact.';
    }
    if (kind == SkillModelKind.receive) {
      return score >= 80
          ? 'Next reps: early plant, soft ankle, ball stays within a step.'
          : 'Next reps: get there sooner and cushion — don’t stab at the ball.';
    }
    return score >= 80
        ? 'Next reps: firm plant, locked ankle, chest staying over the strike.'
        : 'Next reps: plant first, then swing through — don’t fall off the ball.';
  }
}

class _JointSpec {
  const _JointSpec(this.key, this.label, this.a, this.b, this.c);
  final String key;
  final String label;
  final int a;
  final int b;
  final int c;
}

class _Issue {
  const _Issue({
    required this.key,
    required this.delta,
    required this.magnitude,
  });

  final String key;
  final int delta;
  final int magnitude;
}
