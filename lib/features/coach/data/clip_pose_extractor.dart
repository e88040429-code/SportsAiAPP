import 'clip_pose_extract_result.dart';
import 'clip_pose_extractor_stub.dart'
    if (dart.library.html) 'clip_pose_extractor_web.dart' as impl;

export 'clip_pose_extract_result.dart';

/// True on Flutter web (Chrome-first overlay). False on Windows / iOS / Android.
bool get isClipPoseOverlaySupported => impl.isClipPoseOverlaySupported;

/// Precomputes a timed pose track from a playable video URL (blob: / http).
///
/// On non-web platforms this returns [ClipPoseExtractResult.unsupported]
/// immediately — preview still plays without a skeleton.
Future<ClipPoseExtractResult> extractClipPoseTrack({
  required String videoUrl,
  required Duration duration,
  required ClipFramePoseDetector detect,
  required bool Function() isCancelled,
  void Function(double progress)? onProgress,
}) {
  return impl.extractClipPoseTrack(
    videoUrl: videoUrl,
    duration: duration,
    detect: detect,
    isCancelled: isCancelled,
    onProgress: onProgress,
  );
}
