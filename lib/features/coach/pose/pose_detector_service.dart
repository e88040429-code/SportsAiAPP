import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pose_detection/pose_detection.dart';

import 'blazepose_to_coco.dart';
import 'pose_frame.dart';

/// Owns a [PoseDetector] and publishes the latest [PoseFrame] for Live Coach.
///
/// Web: feed JPEG/PNG bytes via [processImageBytes] (camera image streams are
/// unsupported by the package on web). Mobile: prefer [processCameraImage].
class PoseDetectorService {
  PoseDetector? _detector;
  bool _initializing = false;
  bool _disposed = false;
  bool _busy = false;

  final ValueNotifier<PoseFrame?> latestFrame = ValueNotifier<PoseFrame?>(null);
  final ValueNotifier<String?> statusMessage = ValueNotifier<String?>(null);

  /// BlazePose types aligned to the app's COCO-17 painter slots.
  static const List<PoseLandmarkType> _cocoTypes = [
    PoseLandmarkType.nose,
    PoseLandmarkType.leftEye,
    PoseLandmarkType.rightEye,
    PoseLandmarkType.leftEar,
    PoseLandmarkType.rightEar,
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle,
  ];

  bool get isReady => _detector != null && !_disposed;
  bool get isBusy => _busy;

  /// Creates the on-device / LiteRT.js detector (lite model for live FPS).
  Future<void> initialize() async {
    if (_disposed || _detector != null || _initializing) return;
    _initializing = true;
    statusMessage.value = 'Loading pose model…';
    try {
      final detector = await PoseDetector.create(
        mode: PoseMode.boxesAndLandmarks,
        landmarkModel: PoseLandmarkModel.lite,
      );
      if (_disposed) {
        await detector.dispose();
        return;
      }
      _detector = detector;
      statusMessage.value = null;
    } catch (e) {
      statusMessage.value = 'Pose model failed to load.';
      debugPrint('PoseDetectorService.initialize failed: $e');
    } finally {
      _initializing = false;
    }
  }

  /// Runs detection on encoded image bytes (required path on Flutter web).
  Future<void> processImageBytes(
    Uint8List bytes, {
    required Size imageSize,
    bool mirrorHorizontally = false,
  }) async {
    final detector = _detector;
    if (detector == null || _disposed || _busy || bytes.isEmpty) return;

    _busy = true;
    try {
      final poses = await detector.detect(bytes);
      if (_disposed) return;
      _publish(
        poses,
        fallbackImageSize: imageSize,
        mirrorHorizontally: mirrorHorizontally,
      );
    } catch (e) {
      debugPrint('PoseDetectorService.processImageBytes: $e');
    } finally {
      _busy = false;
    }
  }

  /// Native live-camera path. Throws [UnsupportedError] on web — use bytes.
  Future<void> processCameraImage(
    CameraImage image, {
    required Size detectionImageSize,
    required bool mirrorHorizontally,
    CameraFrameRotation? rotation,
    int maxDim = 640,
  }) async {
    final detector = _detector;
    if (detector == null || _disposed || _busy) return;
    if (kIsWeb) {
      throw UnsupportedError(
        'processCameraImage is unsupported on web; use processImageBytes.',
      );
    }

    _busy = true;
    try {
      final poses = await detector.detectFromCameraImage(
        image,
        rotation: rotation,
        maxDim: maxDim,
      );
      if (_disposed) return;
      _publish(
        poses,
        fallbackImageSize: detectionImageSize,
        mirrorHorizontally: mirrorHorizontally,
      );
    } catch (e) {
      debugPrint('PoseDetectorService.processCameraImage: $e');
    } finally {
      _busy = false;
    }
  }

  void clearFrame() {
    if (!_disposed) {
      latestFrame.value = null;
    }
  }

  void _publish(
    List<Pose> poses, {
    required Size fallbackImageSize,
    required bool mirrorHorizontally,
  }) {
    Pose? best;
    for (final pose in poses) {
      if (!pose.hasLandmarks) continue;
      if (best == null || pose.score > best.score) {
        best = pose;
      }
    }
    if (best == null) {
      latestFrame.value = null;
      return;
    }

    // Prefer detector-reported image size — landmarks are in that pixel space.
    final imageSize = (best.imageWidth > 0 && best.imageHeight > 0)
        ? Size(best.imageWidth.toDouble(), best.imageHeight.toDouble())
        : fallbackImageSize;

    final coco = <PixelLandmark?>[];
    for (final type in _cocoTypes) {
      final lm = best.getLandmark(type);
      coco.add(
        lm == null
            ? null
            : PixelLandmark(x: lm.x, y: lm.y, visibility: lm.visibility),
      );
    }

    final previous = latestFrame.value;
    latestFrame.value = BlazePoseToCoco.fromCocoLandmarks(
      coco,
      imageSize: imageSize,
      mirrorHorizontally: mirrorHorizontally,
      previousJoints: previous?.joints,
      previousConfidence: previous?.confidence,
      score: best.score,
    );
  }

  Future<void> dispose() async {
    _disposed = true;
    _busy = false;
    final detector = _detector;
    _detector = null;
    latestFrame.value = null;
    latestFrame.dispose();
    statusMessage.dispose();
    await detector?.dispose();
  }
}
