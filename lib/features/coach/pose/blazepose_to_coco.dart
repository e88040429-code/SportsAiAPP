import 'package:flutter/material.dart';

import 'pose_frame.dart';

/// One landmark in absolute image-pixel coordinates.
class PixelLandmark {
  const PixelLandmark({
    required this.x,
    required this.y,
    this.visibility = 1,
  });

  final double x;
  final double y;
  final double visibility;
}

/// COCO-17 joint indices shared by Live Coach + Recap painters.
abstract final class CocoJoints {
  static const int nose = 0;
  static const int leftEye = 1;
  static const int rightEye = 2;
  static const int leftEar = 3;
  static const int rightEar = 4;
  static const int leftShoulder = 5;
  static const int rightShoulder = 6;
  static const int leftElbow = 7;
  static const int rightElbow = 8;
  static const int leftWrist = 9;
  static const int rightWrist = 10;
  static const int leftHip = 11;
  static const int rightHip = 12;
  static const int leftKnee = 13;
  static const int rightKnee = 14;
  static const int leftAnkle = 15;
  static const int rightAnkle = 16;
}

/// Maps BlazePose-style landmarks into the app's COCO-17 joint layout.
///
/// Callers supply already-selected COCO slots (length 17) in this order:
/// 0 nose, 1 L eye, 2 R eye, 3 L ear, 4 R ear,
/// 5 L shoulder, 6 R shoulder, 7 L elbow, 8 R elbow, 9 L wrist, 10 R wrist,
/// 11 L hip, 12 R hip, 13 L knee, 14 R knee, 15 L ankle, 16 R ankle.
///
/// Kept free of `pose_detection` types so mapping is unit-testable without
/// native LiteRT/OpenCV assets.
abstract final class BlazePoseToCoco {
  /// Landmarks below this visibility are treated as missing.
  static const double minVisibility = 0.35;

  /// Converts 17 optional pixel landmarks into a normalized [PoseFrame].
  ///
  /// When [mirrorHorizontally] is true (front-camera preview), x is flipped so
  /// the overlay matches the mirrored camera texture.
  ///
  /// Missing / low-visibility joints keep [previousJoints] when available;
  /// otherwise they stay at [Offset.zero] with confidence `0` so the painter
  /// can skip them.
  static PoseFrame? fromCocoLandmarks(
    List<PixelLandmark?> cocoLandmarks, {
    required Size imageSize,
    bool mirrorHorizontally = false,
    DateTime? timestamp,
    List<Offset>? previousJoints,
    List<double>? previousConfidence,
    double score = 0,
    double visibilityFloor = BlazePoseToCoco.minVisibility,
  }) {
    assert(cocoLandmarks.length == PoseFrame.jointCount);
    if (imageSize.width <= 0 || imageSize.height <= 0) return null;

    final hasAny = cocoLandmarks.any(
      (l) => l != null && l.visibility >= visibilityFloor,
    );
    if (!hasAny) return null;

    final joints = <Offset>[];
    final confidence = <double>[];

    for (var i = 0; i < PoseFrame.jointCount; i++) {
      final lm = cocoLandmarks[i];
      final usable = lm != null && lm.visibility >= visibilityFloor;

      if (!usable) {
        final hadPrevious = previousJoints != null &&
            previousJoints.length == PoseFrame.jointCount &&
            previousConfidence != null &&
            previousConfidence.length == PoseFrame.jointCount &&
            previousConfidence[i] >= visibilityFloor;
        if (hadPrevious) {
          joints.add(previousJoints[i]);
          confidence.add(previousConfidence[i] * 0.85); // decay carry-forward
        } else {
          joints.add(Offset.zero);
          confidence.add(0);
        }
        continue;
      }

      var nx = (lm.x / imageSize.width).clamp(0.0, 1.0);
      final ny = (lm.y / imageSize.height).clamp(0.0, 1.0);
      if (mirrorHorizontally) {
        nx = 1.0 - nx;
      }
      joints.add(Offset(nx, ny));
      confidence.add(lm.visibility);
    }

    return PoseFrame(
      joints: joints,
      imageSize: imageSize,
      timestamp: timestamp ?? DateTime.now(),
      confidence: confidence,
      score: score,
    );
  }
}
