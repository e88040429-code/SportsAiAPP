import 'dart:typed_data';
import 'dart:ui';

import '../pose/clip_pose_track.dart';
import '../pose/pose_frame.dart';

/// Detect one extracted JPEG/PNG frame. Must not overlap in-flight calls.
typedef ClipFramePoseDetector = Future<PoseFrame?> Function(
  Uint8List bytes,
  Size imageSize,
);

/// Outcome of a clip pose extraction pass.
class ClipPoseExtractResult {
  const ClipPoseExtractResult({
    this.track,
    this.message,
    this.cancelled = false,
  });

  final ClipPoseTrack? track;

  /// Soft failure / unsupported note for the overlay chip. Null when OK.
  final String? message;

  final bool cancelled;

  factory ClipPoseExtractResult.ok(ClipPoseTrack track) {
    if (!track.hasAnyPose) {
      return ClipPoseExtractResult(
        track: track,
        message:
            'No person found in this clip. Overlay is off — preview still plays.',
      );
    }
    return ClipPoseExtractResult(track: track);
  }

  factory ClipPoseExtractResult.unsupported() => const ClipPoseExtractResult(
        message: 'Pose overlay is available in Chrome for now.',
      );

  factory ClipPoseExtractResult.failed([String? reason]) =>
      ClipPoseExtractResult(
        message: reason ??
            'Couldn’t read poses from this clip. Preview still plays.',
      );

  factory ClipPoseExtractResult.cancelled() =>
      const ClipPoseExtractResult(cancelled: true);
}
