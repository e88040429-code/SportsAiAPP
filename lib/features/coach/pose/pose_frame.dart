import 'package:flutter/material.dart';

/// One detected pose frame in the app's shared skeleton format.
///
/// [joints] are 17 COCO-style landmarks in normalized overlay space (0–1),
/// matching [PoseSkeletonPainter]. Origin is top-left; +x right, +y down.
class PoseFrame {
  const PoseFrame({
    required this.joints,
    required this.imageSize,
    this.timestamp,
    this.confidence,
    this.score = 0,
  }) : assert(joints.length == 17);

  /// COCO-17 joint positions in normalized 0–1 coordinates.
  final List<Offset> joints;

  /// Pixel size of the image the landmarks were detected in.
  final Size imageSize;

  final DateTime? timestamp;

  /// Per-joint visibility/confidence when available (length 17).
  final List<double>? confidence;

  /// Overall detector score for the chosen person (0–1).
  final double score;

  static const int jointCount = 17;

  /// Whether joint [index] should be drawn (confidence at/above [minVisibility]).
  bool isJointVisible(int index, {double minVisibility = 0.35}) {
    if (index < 0 || index >= joints.length) return false;
    final conf = confidence;
    if (conf == null || conf.length != joints.length) return true;
    return conf[index] >= minVisibility;
  }
}
