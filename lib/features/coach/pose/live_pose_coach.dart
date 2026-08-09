import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/sport/app_sport.dart';
import '../data/coach_mock_data.dart';
import 'blazepose_to_coco.dart';
import 'pose_frame.dart';

/// Live coaching cue + metrics derived from the current [PoseFrame].
class LivePoseInsights {
  const LivePoseInsights({
    required this.cue,
    required this.metrics,
    this.hasPose = false,
  });

  final String cue;
  final List<CoachMetric> metrics;
  final bool hasPose;
}

/// Still-photo scores (0–1). Timing is omitted — a single frame has no rhythm.
class StillPoseScores {
  const StillPoseScores({
    required this.balance,
    required this.symmetry,
  });

  final double balance;
  final double symmetry;
}

/// Derives Balance / Symmetry / Timing (or soccer Plant / Contact / Follow)
/// and a short cue from live pose landmarks.
///
/// Keeps a short frame history so Timing reflects recent motion, not a still.
class LivePoseCoach {
  LivePoseCoach({this.historyLimit = 12});

  final int historyLimit;
  final List<PoseFrame> _history = [];

  /// Smoothed metric percentages (EMA) so HUD values don't flicker.
  final Map<String, double> _smoothed = {};

  PoseFrame? _lastFrame;
  LivePoseInsights? _lastInsights;

  LivePoseInsights analyze(
    PoseFrame? frame,
    AppSport sport, {
    bool stillImage = false,
  }) {
    if (frame == null) {
      _lastFrame = null;
      _lastInsights = LivePoseInsights(
        cue: stillImage
            ? 'I couldn’t find a full body in this photo. Try a clearer standing shot.'
            : 'Stand in frame so I can track your form — or import a clip.',
        metrics: stillImage ? _idleStillMetrics() : _idleMetrics(sport),
        hasPose: false,
      );
      return _lastInsights!;
    }

    // Cue + metrics builders may both call analyze for the same frame.
    if (!stillImage && identical(frame, _lastFrame) && _lastInsights != null) {
      return _lastInsights!;
    }

    if (!stillImage) {
      _history.add(frame);
      while (_history.length > historyLimit) {
        _history.removeAt(0);
      }
    }

    _lastFrame = frame;
    _lastInsights = stillImage
        ? _still(frame)
        : switch (sport) {
            AppSport.volleyball => _volleyball(frame),
            AppSport.soccer => _soccer(frame),
          };
    return _lastInsights!;
  }

  /// Balance + symmetry only — use for imported still photos.
  StillPoseScores stillScores(PoseFrame frame) {
    return StillPoseScores(
      balance: _balanceScore(frame),
      symmetry: _symmetryScore(frame),
    );
  }

  void reset() {
    _history.clear();
    _smoothed.clear();
    _lastFrame = null;
    _lastInsights = null;
  }

  LivePoseInsights _still(PoseFrame frame) {
    final balance = _balanceScore(frame);
    final symmetry = _symmetryScore(frame);
    final metrics = [
      CoachMetric(label: 'Balance', value: _pct(balance, 'still-balance')),
      CoachMetric(label: 'Symmetry', value: _pct(symmetry, 'still-symmetry')),
    ];
    final cue = _pickCue(
      scored: [
        (balance, 'Find a quieter base — stack hips under your shoulders.'),
        (symmetry, 'Match left and right — even out your arm and leg shapes.'),
      ],
      fallback: 'Solid still shape — hold that stack and even limbs.',
    );
    return LivePoseInsights(cue: cue, metrics: metrics, hasPose: true);
  }

  LivePoseInsights _volleyball(PoseFrame frame) {
    final balance = _balanceScore(frame);
    final symmetry = _symmetryScore(frame);
    final timing = _timingScore(frame);
    final elbow = _elbowElevationCue(frame);

    final metrics = [
      CoachMetric(label: 'Balance', value: _pct(balance, 'balance')),
      CoachMetric(label: 'Symmetry', value: _pct(symmetry, 'symmetry')),
      CoachMetric(label: 'Timing', value: _pct(timing, 'timing')),
    ];

    final cue = elbow ??
        _pickCue(
          scored: [
            (balance, 'Find a quieter base — stack hips under your shoulders.'),
            (symmetry, 'Match left and right — even out your arm and leg shapes.'),
            (timing, 'Smooth the rhythm — load, then explode through contact.'),
          ],
          fallback: 'Looking athletic — keep that posture through the swing.',
        );

    return LivePoseInsights(cue: cue, metrics: metrics, hasPose: true);
  }

  LivePoseInsights _soccer(PoseFrame frame) {
    final plant = _plantScore(frame);
    final contact = _contactScore(frame);
    final follow = _followScore(frame);

    final metrics = [
      CoachMetric(label: 'Plant', value: _pct(plant, 'plant')),
      CoachMetric(label: 'Contact', value: _pct(contact, 'contact')),
      CoachMetric(label: 'Follow', value: _pct(follow, 'follow')),
    ];

    final cue = _pickCue(
      scored: [
        (
          plant,
          'Plant beside the ball — firmer plant knee, chest over the strike.'
        ),
        (
          contact,
          'Open the striking hip and whip the knee through the ball.'
        ),
        (
          follow,
          'Finish tall through the kick — don’t collapse after contact.'
        ),
      ],
      fallback: 'Solid shape — stay balanced over the plant foot.',
    );

    return LivePoseInsights(cue: cue, metrics: metrics, hasPose: true);
  }

  /// How centered the hips are under the shoulders (0–1).
  double _balanceScore(PoseFrame frame) {
    if (!_vis(frame, CocoJoints.leftShoulder) ||
        !_vis(frame, CocoJoints.rightShoulder) ||
        !_vis(frame, CocoJoints.leftHip) ||
        !_vis(frame, CocoJoints.rightHip)) {
      return 0.55;
    }
    final shoulderMid =
        _mid(frame, CocoJoints.leftShoulder, CocoJoints.rightShoulder);
    final hipMid = _mid(frame, CocoJoints.leftHip, CocoJoints.rightHip);
    final lean = (shoulderMid.dx - hipMid.dx).abs();
    return (1.0 - lean * 4.5).clamp(0.4, 0.98);
  }

  /// Left/right limb angle similarity (0–1).
  double _symmetryScore(PoseFrame frame) {
    final leftElbow =
        _angle(frame, CocoJoints.leftShoulder, CocoJoints.leftElbow, CocoJoints.leftWrist);
    final rightElbow =
        _angle(frame, CocoJoints.rightShoulder, CocoJoints.rightElbow, CocoJoints.rightWrist);
    final leftKnee =
        _angle(frame, CocoJoints.leftHip, CocoJoints.leftKnee, CocoJoints.leftAnkle);
    final rightKnee =
        _angle(frame, CocoJoints.rightHip, CocoJoints.rightKnee, CocoJoints.rightAnkle);

    final parts = <double>[];
    if (leftElbow != null && rightElbow != null) {
      parts.add(1.0 - ((leftElbow - rightElbow).abs() / 90.0).clamp(0.0, 1.0));
    }
    if (leftKnee != null && rightKnee != null) {
      parts.add(1.0 - ((leftKnee - rightKnee).abs() / 80.0).clamp(0.0, 1.0));
    }
    if (parts.isEmpty) return 0.55;
    return (parts.reduce((a, b) => a + b) / parts.length).clamp(0.4, 0.98);
  }

  /// Recent motion energy — some movement scores higher than frozen or frantic.
  double _timingScore(PoseFrame frame) {
    if (_history.length < 3) return 0.6;
    final energy = _motionEnergy();
    // Sweet spot around moderate motion (hitting / approach).
    final target = 0.045;
    final delta = (energy - target).abs();
    return (1.0 - delta * 12.0).clamp(0.45, 0.96);
  }

  double _plantScore(PoseFrame frame) {
    // Prefer the more extended (plant) knee.
    final left =
        _angle(frame, CocoJoints.leftHip, CocoJoints.leftKnee, CocoJoints.leftAnkle);
    final right =
        _angle(frame, CocoJoints.rightHip, CocoJoints.rightKnee, CocoJoints.rightAnkle);
    final plant = _maxOrNull(left, right);
    if (plant == null) return 0.55;
    // Ideal plant ~155–175°.
    final err = (plant - 165).abs();
    return (1.0 - err / 70.0).clamp(0.4, 0.98);
  }

  double _contactScore(PoseFrame frame) {
    final left =
        _angle(frame, CocoJoints.leftHip, CocoJoints.leftKnee, CocoJoints.leftAnkle);
    final right =
        _angle(frame, CocoJoints.rightHip, CocoJoints.rightKnee, CocoJoints.rightAnkle);
    if (left == null || right == null) return 0.55;
    // Striking leg more flexed than plant → larger knee delta is good.
    final delta = (left - right).abs();
    return (delta / 55.0).clamp(0.4, 0.97);
  }

  double _followScore(PoseFrame frame) {
    if (!_vis(frame, CocoJoints.nose) ||
        !_vis(frame, CocoJoints.leftHip) ||
        !_vis(frame, CocoJoints.rightHip)) {
      return 0.55;
    }
    final hipMid = _mid(frame, CocoJoints.leftHip, CocoJoints.rightHip);
    final nose = frame.joints[CocoJoints.nose];
    // Slight forward lean (nose ahead of hips in image-x after mirror) is fine;
    // large collapse (nose much lower / far offset) hurts.
    final verticalStack = (nose.dy - hipMid.dy).abs();
    final upright = (verticalStack / 0.55).clamp(0.0, 1.0);
    return (0.45 + upright * 0.5).clamp(0.4, 0.97);
  }

  String? _elbowElevationCue(PoseFrame frame) {
    final rightElbowY = _vis(frame, CocoJoints.rightElbow)
        ? frame.joints[CocoJoints.rightElbow].dy
        : null;
    final rightShoulderY = _vis(frame, CocoJoints.rightShoulder)
        ? frame.joints[CocoJoints.rightShoulder].dy
        : null;
    final leftElbowY = _vis(frame, CocoJoints.leftElbow)
        ? frame.joints[CocoJoints.leftElbow].dy
        : null;
    final leftShoulderY = _vis(frame, CocoJoints.leftShoulder)
        ? frame.joints[CocoJoints.leftShoulder].dy
        : null;

    // In image space, smaller y = higher on screen.
    if (rightElbowY != null &&
        rightShoulderY != null &&
        rightElbowY > rightShoulderY + 0.06) {
      return 'Keep your elbow higher on the follow-through.';
    }
    if (leftElbowY != null &&
        leftShoulderY != null &&
        leftElbowY > leftShoulderY + 0.06) {
      return 'Lift the hitting elbow — stay above the shoulder line.';
    }
    return null;
  }

  double _motionEnergy() {
    if (_history.length < 2) return 0;
    var total = 0.0;
    var samples = 0;
    const tracked = [
      CocoJoints.leftWrist,
      CocoJoints.rightWrist,
      CocoJoints.leftAnkle,
      CocoJoints.rightAnkle,
      CocoJoints.nose,
    ];
    for (var i = 1; i < _history.length; i++) {
      final prev = _history[i - 1];
      final curr = _history[i];
      for (final j in tracked) {
        if (!_vis(prev, j) || !_vis(curr, j)) continue;
        total += (curr.joints[j] - prev.joints[j]).distance;
        samples++;
      }
    }
    if (samples == 0) return 0;
    return total / samples;
  }

  String _pct(double score01, String key) {
    final previous = _smoothed[key];
    final smoothed =
        previous == null ? score01 : previous * 0.65 + score01 * 0.35;
    _smoothed[key] = smoothed;
    return '${(smoothed * 100).round()}%';
  }

  String _pickCue({
    required List<(double score, String cue)> scored,
    required String fallback,
  }) {
    scored.sort((a, b) => a.$1.compareTo(b.$1));
    final worst = scored.first;
    if (worst.$1 < 0.72) return worst.$2;
    return fallback;
  }

  List<CoachMetric> _idleMetrics(AppSport sport) => switch (sport) {
        AppSport.volleyball => const [
            CoachMetric(label: 'Balance', value: '—'),
            CoachMetric(label: 'Symmetry', value: '—'),
            CoachMetric(label: 'Timing', value: '—'),
          ],
        AppSport.soccer => const [
            CoachMetric(label: 'Plant', value: '—'),
            CoachMetric(label: 'Contact', value: '—'),
            CoachMetric(label: 'Follow', value: '—'),
          ],
      };

  List<CoachMetric> _idleStillMetrics() => const [
        CoachMetric(label: 'Balance', value: '—'),
        CoachMetric(label: 'Symmetry', value: '—'),
      ];

  static bool _vis(PoseFrame frame, int index) =>
      frame.isJointVisible(index, minVisibility: BlazePoseToCoco.minVisibility);

  static Offset _mid(PoseFrame frame, int a, int b) =>
      Offset(
        (frame.joints[a].dx + frame.joints[b].dx) / 2,
        (frame.joints[a].dy + frame.joints[b].dy) / 2,
      );

  static double? _angle(PoseFrame frame, int a, int b, int c) {
    if (!_vis(frame, a) || !_vis(frame, b) || !_vis(frame, c)) return null;
    final ba = frame.joints[a] - frame.joints[b];
    final bc = frame.joints[c] - frame.joints[b];
    final mag = ba.distance * bc.distance;
    if (mag < 1e-6) return null;
    final cos = ((ba.dx * bc.dx + ba.dy * bc.dy) / mag).clamp(-1.0, 1.0);
    return math.acos(cos) * 180 / math.pi;
  }

  static double? _maxOrNull(double? a, double? b) {
    if (a == null) return b;
    if (b == null) return a;
    return math.max(a, b);
  }
}
