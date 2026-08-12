import 'clip_pose_extract_result.dart';

const bool isClipPoseOverlaySupported = false;

Future<ClipPoseExtractResult> extractClipPoseTrack({
  required String videoUrl,
  required Duration duration,
  required ClipFramePoseDetector detect,
  required bool Function() isCancelled,
  void Function(double progress)? onProgress,
}) async {
  return ClipPoseExtractResult.unsupported();
}
