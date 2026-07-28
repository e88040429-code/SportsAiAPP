import 'package:flutter/material.dart';

import '../../../core/sport/app_sport.dart';

enum SkillModelKind { receive, hitting }

extension SkillModelKindX on SkillModelKind {
  String get label => switch (this) {
        SkillModelKind.receive => 'Perfect receive',
        SkillModelKind.hitting => 'Perfect hit',
      };

  String labelFor(AppSport sport) => switch ((this, sport)) {
        (SkillModelKind.receive, AppSport.volleyball) => 'Perfect pass / receive',
        (SkillModelKind.hitting, AppSport.volleyball) => 'Perfect spike / hit',
        (SkillModelKind.receive, AppSport.soccer) => 'Perfect first touch',
        (SkillModelKind.hitting, AppSport.soccer) => 'Perfect strike',
      };
}

/// Reference stick-figure poses for model examples + clip conversion.
abstract final class ModelPoseLibrary {
  /// Ideal volleyball forearm pass / receive.
  static const List<Offset> volleyballReceive = [
    Offset(0.50, 0.14),
    Offset(0.46, 0.12),
    Offset(0.54, 0.12),
    Offset(0.42, 0.14),
    Offset(0.58, 0.14),
    Offset(0.36, 0.28),
    Offset(0.64, 0.28),
    Offset(0.30, 0.42),
    Offset(0.70, 0.42),
    Offset(0.38, 0.54), // platform wrists together-ish
    Offset(0.62, 0.54),
    Offset(0.42, 0.52),
    Offset(0.58, 0.52),
    Offset(0.40, 0.72),
    Offset(0.60, 0.72),
    Offset(0.38, 0.92),
    Offset(0.62, 0.92),
  ];

  /// Ideal volleyball spike contact.
  static const List<Offset> volleyballHit = [
    Offset(0.50, 0.10),
    Offset(0.46, 0.08),
    Offset(0.54, 0.08),
    Offset(0.42, 0.10),
    Offset(0.58, 0.10),
    Offset(0.38, 0.22),
    Offset(0.62, 0.22),
    Offset(0.28, 0.34),
    Offset(0.78, 0.14),
    Offset(0.22, 0.46),
    Offset(0.90, 0.06),
    Offset(0.42, 0.46),
    Offset(0.58, 0.46),
    Offset(0.40, 0.66),
    Offset(0.60, 0.66),
    Offset(0.38, 0.88),
    Offset(0.62, 0.88),
  ];

  /// Ideal soccer first-touch receive.
  static const List<Offset> soccerReceive = [
    Offset(0.50, 0.12),
    Offset(0.46, 0.10),
    Offset(0.54, 0.10),
    Offset(0.42, 0.12),
    Offset(0.58, 0.12),
    Offset(0.38, 0.26),
    Offset(0.62, 0.26),
    Offset(0.32, 0.40),
    Offset(0.68, 0.40),
    Offset(0.28, 0.52),
    Offset(0.72, 0.52),
    Offset(0.44, 0.50),
    Offset(0.56, 0.50),
    Offset(0.42, 0.70),
    Offset(0.62, 0.68),
    Offset(0.40, 0.90),
    Offset(0.68, 0.86), // cushioning foot slightly raised
  ];

  /// Ideal soccer strike.
  static const List<Offset> soccerHit = [
    Offset(0.48, 0.11),
    Offset(0.44, 0.09),
    Offset(0.52, 0.09),
    Offset(0.40, 0.11),
    Offset(0.56, 0.11),
    Offset(0.36, 0.24),
    Offset(0.60, 0.24),
    Offset(0.30, 0.38),
    Offset(0.68, 0.36),
    Offset(0.26, 0.50),
    Offset(0.74, 0.48),
    Offset(0.40, 0.50),
    Offset(0.56, 0.50),
    Offset(0.38, 0.70),
    Offset(0.72, 0.62),
    Offset(0.36, 0.90),
    Offset(0.86, 0.78),
  ];

  static List<Offset> modelPose(AppSport sport, SkillModelKind kind) {
    return switch ((sport, kind)) {
      (AppSport.volleyball, SkillModelKind.receive) => volleyballReceive,
      (AppSport.volleyball, SkillModelKind.hitting) => volleyballHit,
      (AppSport.soccer, SkillModelKind.receive) => soccerReceive,
      (AppSport.soccer, SkillModelKind.hitting) => soccerHit,
    };
  }

  /// Keyframe sequence for a model skill (0→1 through the motion).
  static List<List<Offset>> modelSequence(AppSport sport, SkillModelKind kind) {
    final end = modelPose(sport, kind);
    final start = _readyStance(sport);
    final mid = _lerpPose(start, end, 0.55);
    return [start, mid, end, end];
  }

  static List<Offset> _readyStance(AppSport sport) {
    if (sport == AppSport.soccer) {
      return const [
        Offset(0.50, 0.12),
        Offset(0.46, 0.10),
        Offset(0.54, 0.10),
        Offset(0.42, 0.12),
        Offset(0.58, 0.12),
        Offset(0.38, 0.26),
        Offset(0.62, 0.26),
        Offset(0.32, 0.40),
        Offset(0.68, 0.40),
        Offset(0.28, 0.52),
        Offset(0.72, 0.52),
        Offset(0.44, 0.52),
        Offset(0.56, 0.52),
        Offset(0.42, 0.72),
        Offset(0.58, 0.72),
        Offset(0.40, 0.92),
        Offset(0.60, 0.92),
      ];
    }
    return const [
      Offset(0.50, 0.14),
      Offset(0.46, 0.12),
      Offset(0.54, 0.12),
      Offset(0.42, 0.14),
      Offset(0.58, 0.14),
      Offset(0.38, 0.28),
      Offset(0.62, 0.28),
      Offset(0.32, 0.42),
      Offset(0.68, 0.42),
      Offset(0.28, 0.54),
      Offset(0.72, 0.54),
      Offset(0.44, 0.54),
      Offset(0.56, 0.54),
      Offset(0.42, 0.72),
      Offset(0.58, 0.72),
      Offset(0.40, 0.92),
      Offset(0.60, 0.92),
    ];
  }

  static List<Offset> _lerpPose(List<Offset> a, List<Offset> b, double t) {
    return [
      for (var i = 0; i < a.length; i++) Offset.lerp(a[i], b[i], t)!,
    ];
  }

  /// Build an "athlete from clip" sequence: like the model, with form errors.
  static List<List<Offset>> athleteSequenceFromClip({
    required AppSport sport,
    required SkillModelKind kind,
    required String clipName,
  }) {
    final model = modelSequence(sport, kind);
    // Deterministic offsets from clip name so different clips look different.
    final seed = clipName.hashCode;
    final dx = ((seed % 17) - 8) / 220.0;
    final dy = (((seed ~/ 17) % 13) - 6) / 220.0;

    return [
      for (final frame in model)
        [
          for (var i = 0; i < frame.length; i++)
            Offset(
              (frame[i].dx + dx + _jointBias(i, seed).dx).clamp(0.05, 0.95),
              (frame[i].dy + dy + _jointBias(i, seed).dy).clamp(0.05, 0.95),
            ),
        ],
    ];
  }

  static Offset _jointBias(int joint, int seed) {
    // Emphasize common errors: elbow/plant/strike joints drift more.
    final amplify = switch (joint) {
      7 || 8 || 9 || 10 => 1.8, // arms
      13 || 14 || 15 || 16 => 1.6, // legs
      _ => 0.7,
    };
    final bx = (((seed + joint * 31) % 11) - 5) / 260.0 * amplify;
    final by = (((seed + joint * 17) % 9) - 4) / 260.0 * amplify;
    return Offset(bx, by);
  }

  static List<Offset> poseAt(List<List<Offset>> sequence, double t) {
    if (sequence.isEmpty) return const [];
    if (sequence.length == 1) return sequence.first;
    final clamped = t.clamp(0.0, 1.0);
    final scaled = clamped * (sequence.length - 1);
    final i = scaled.floor().clamp(0, sequence.length - 2);
    final localT = scaled - i;
    return _lerpPose(sequence[i], sequence[i + 1], localT);
  }
}
