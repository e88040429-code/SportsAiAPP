import 'pose_frame.dart';

/// One sampled pose at a playback timestamp.
class ClipPoseSample {
  const ClipPoseSample({required this.time, this.pose});

  final Duration time;

  /// Null when no person was found in that frame.
  final PoseFrame? pose;
}

/// Precomputed pose samples synced to [VideoPlayerController] position.
class ClipPoseTrack {
  const ClipPoseTrack({required this.samples, required this.duration});

  /// Sorted ascending by [ClipPoseSample.time].
  final List<ClipPoseSample> samples;
  final Duration duration;

  bool get isEmpty => samples.isEmpty;

  bool get hasAnyPose => samples.any((s) => s.pose != null);

  /// Nearest sample to [t]. Returns null when the track is empty or that
  /// sample had no person.
  PoseFrame? poseAt(Duration t) {
    if (samples.isEmpty) return null;

    if (t <= samples.first.time) return samples.first.pose;
    if (t >= samples.last.time) return samples.last.pose;

    var lo = 0;
    var hi = samples.length - 1;
    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final midTime = samples[mid].time;
      if (midTime == t) return samples[mid].pose;
      if (midTime < t) {
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }

    // [hi] is last sample at or before [t]; [lo] is first after [t].
    final before = samples[hi];
    final after = samples[lo];
    final nearer =
        (t - before.time) <= (after.time - t) ? before : after;
    return nearer.pose;
  }
}

/// Timestamp grid for clip pose extraction (~8–12 FPS, capped).
///
/// Does not touch LiteRT — safe to unit-test on VM.
List<Duration> sampleTimesForClip({
  required Duration duration,
  double targetFps = 10,
  int maxSamples = 180,
}) {
  if (duration <= Duration.zero || targetFps <= 0 || maxSamples <= 0) {
    return const [];
  }

  final totalMs = duration.inMilliseconds;
  if (totalMs <= 0) return const [];

  if (maxSamples == 1) return const [Duration.zero];

  // ~8–12 FPS → 80–120ms. Default 10 FPS is 100ms.
  var stepMs = (1000 / targetFps).round().clamp(80, 120);

  var count = (totalMs / stepMs).floor() + 1;
  if (count > maxSamples) {
    stepMs = (totalMs / (maxSamples - 1)).ceil().clamp(1, totalMs);
    count = maxSamples;
  }

  return [
    for (var i = 0; i < count; i++)
      Duration(milliseconds: (i * stepMs).clamp(0, totalMs)),
  ];
}
