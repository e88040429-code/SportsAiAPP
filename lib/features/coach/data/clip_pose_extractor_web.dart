import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import '../pose/clip_pose_track.dart';
import 'clip_pose_extract_result.dart';

const bool isClipPoseOverlaySupported = true;

const int _maxCanvasDim = 640;
const int _jpegQualityPct = 72;

Future<ClipPoseExtractResult> extractClipPoseTrack({
  required String videoUrl,
  required Duration duration,
  required ClipFramePoseDetector detect,
  required bool Function() isCancelled,
  void Function(double progress)? onProgress,
}) async {
  if (videoUrl.isEmpty) {
    return ClipPoseExtractResult.failed();
  }

  web.HTMLVideoElement? video;
  try {
    video = web.HTMLVideoElement()
      ..src = videoUrl
      ..muted = true
      ..playsInline = true
      ..preload = 'auto'
      ..crossOrigin = 'anonymous';

    video.style
      ..setProperty('position', 'fixed')
      ..setProperty('left', '-10000px')
      ..setProperty('top', '0')
      ..setProperty('width', '16px')
      ..setProperty('height', '16px')
      ..setProperty('opacity', '0')
      ..setProperty('pointer-events', 'none');

    web.document.body?.appendChild(video);

    final ready = await _waitForMetadata(video);
    if (isCancelled()) return ClipPoseExtractResult.cancelled();
    if (!ready) {
      return ClipPoseExtractResult.failed(
        'Couldn’t read frames from this clip. Preview still plays.',
      );
    }

    try {
      await video.play().toDart;
    } catch (_) {
      // Autoplay may be blocked; seeking a blob URL usually still works.
    }
    video.pause();

    if (isCancelled()) return ClipPoseExtractResult.cancelled();

    var effectiveDuration = duration;
    if (effectiveDuration <= Duration.zero) {
      final seconds = video.duration;
      if (seconds.isFinite && seconds > 0) {
        effectiveDuration =
            Duration(milliseconds: (seconds * 1000).round());
      }
    }

    final times = sampleTimesForClip(duration: effectiveDuration);
    if (times.isEmpty) {
      return ClipPoseExtractResult.failed(
        'This clip is too short to overlay poses. Preview still plays.',
      );
    }

    final vw = video.videoWidth;
    final vh = video.videoHeight;
    if (vw <= 0 || vh <= 0) {
      return ClipPoseExtractResult.failed(
        'Couldn’t read frames from this clip. Preview still plays.',
      );
    }

    final canvasSize = _fitMaxDim(vw, vh, _maxCanvasDim);
    final canvas = web.HTMLCanvasElement()
      ..width = canvasSize.width
      ..height = canvasSize.height;
    final ctx = canvas.context2D;
    final imageSize = Size(
      canvasSize.width.toDouble(),
      canvasSize.height.toDouble(),
    );

    final samples = <ClipPoseSample>[];
    var decodedAny = false;
    for (var i = 0; i < times.length; i++) {
      if (isCancelled()) return ClipPoseExtractResult.cancelled();

      final t = times[i];
      final seeked = await _seekTo(video, t);
      if (isCancelled()) return ClipPoseExtractResult.cancelled();

      if (!seeked) {
        samples.add(ClipPoseSample(time: t));
        onProgress?.call((i + 1) / times.length);
        continue;
      }

      ctx.drawImage(
        video,
        0,
        0,
        canvasSize.width,
        canvasSize.height,
      );
      final bytes = _canvasToJpeg(canvas);
      if (bytes == null || bytes.isEmpty) {
        samples.add(ClipPoseSample(time: t));
        onProgress?.call((i + 1) / times.length);
        continue;
      }

      decodedAny = true;
      final pose = await detect(bytes, imageSize);
      if (isCancelled()) return ClipPoseExtractResult.cancelled();

      samples.add(ClipPoseSample(time: t, pose: pose));
      onProgress?.call((i + 1) / times.length);
    }

    if (!decodedAny) {
      return ClipPoseExtractResult.failed(
        'Couldn’t read frames from this clip. Preview still plays.',
      );
    }

    return ClipPoseExtractResult.ok(
      ClipPoseTrack(samples: samples, duration: effectiveDuration),
    );
  } catch (e) {
    debugPrint('extractClipPoseTrack: $e');
    return ClipPoseExtractResult.failed();
  } finally {
    final el = video;
    if (el != null) {
      try {
        el.pause();
        el.removeAttribute('src');
        el.load();
        el.remove();
      } catch (_) {}
    }
  }
}

({int width, int height}) _fitMaxDim(int width, int height, int maxDim) {
  if (width <= maxDim && height <= maxDim) {
    return (width: width, height: height);
  }
  final scale = maxDim / (width > height ? width : height);
  return (
    width: (width * scale).round().clamp(1, maxDim),
    height: (height * scale).round().clamp(1, maxDim),
  );
}

Uint8List? _canvasToJpeg(web.HTMLCanvasElement canvas) {
  try {
    final dataUrl =
        canvas.toDataUrl('image/jpeg', _jpegQualityPct / 100);
    final comma = dataUrl.indexOf(',');
    if (comma < 0 || comma == dataUrl.length - 1) return null;
    return base64Decode(dataUrl.substring(comma + 1));
  } catch (e) {
    debugPrint('extractClipPoseTrack jpeg: $e');
    return null;
  }
}

Future<bool> _waitForMetadata(web.HTMLVideoElement video) async {
  if (video.readyState >= web.HTMLMediaElement.HAVE_METADATA) {
    return true;
  }

  final done = Completer<bool>();
  late final StreamSubscription<web.Event> metaSub;
  late final StreamSubscription<web.Event> errorSub;

  void finish(bool ok) {
    if (done.isCompleted) return;
    done.complete(ok);
  }

  metaSub = video.onLoadedMetadata.listen((_) => finish(true));
  errorSub = video.onError.listen((_) => finish(false));
  video.load();

  try {
    return await done.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => false,
    );
  } finally {
    await metaSub.cancel();
    await errorSub.cancel();
  }
}

Future<bool> _seekTo(web.HTMLVideoElement video, Duration time) async {
  final seconds = time.inMilliseconds / 1000.0;
  if ((video.currentTime - seconds).abs() < 0.001 &&
      video.readyState >= web.HTMLMediaElement.HAVE_CURRENT_DATA) {
    return true;
  }

  final done = Completer<bool>();
  late final StreamSubscription<web.Event> seekSub;
  late final StreamSubscription<web.Event> errorSub;

  void finish(bool ok) {
    if (done.isCompleted) return;
    done.complete(ok);
  }

  seekSub = video.onSeeked.listen((_) => finish(true));
  errorSub = video.onError.listen((_) => finish(false));
  video.currentTime = seconds;

  try {
    return await done.future.timeout(
      const Duration(seconds: 4),
      onTimeout: () => false,
    );
  } finally {
    await seekSub.cancel();
    await errorSub.cancel();
  }
}
