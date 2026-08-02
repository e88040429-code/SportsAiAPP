import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pose_detection/pose_detection.dart';

import '../../../core/theme/app_colors.dart';
import '../pose/live_pose_overlay.dart';
import '../pose/pose_frame.dart';

/// Encoded camera snapshot for web (and fallback) pose detection.
class CameraJpegFrame {
  const CameraJpegFrame({
    required this.bytes,
    required this.imageSize,
    required this.mirrorHorizontally,
  });

  final Uint8List bytes;
  final Size imageSize;
  final bool mirrorHorizontally;
}

/// Native camera stream frame for [PoseDetector.detectFromCameraImage].
class CameraStreamFrame {
  const CameraStreamFrame({
    required this.image,
    required this.detectionImageSize,
    required this.mirrorHorizontally,
    required this.rotation,
  });

  final CameraImage image;
  final Size detectionImageSize;
  final bool mirrorHorizontally;
  final CameraFrameRotation? rotation;
}

/// Live device camera feed for the Coach HUD (web + mobile).
///
/// Supports lens flip when multiple cameras exist, plus a wide zoom range
/// (pinch + on-screen controls). Falls back to a dark placeholder if unavailable.
///
/// When [poseEnabled] is true, frames are forwarded for pose detection:
/// - **Web:** throttled JPEG snapshots via [onJpegFrame]
/// - **Mobile/desktop:** [CameraImage] stream via [onStreamFrame] when supported
class CoachCameraPreview extends StatefulWidget {
  const CoachCameraPreview({
    super.key,
    this.poseEnabled = false,
    this.onJpegFrame,
    this.onStreamFrame,
    this.poseFrameListenable,
    this.canCaptureFrame,
  });

  /// When true, start feeding frames to the pose callbacks once the camera opens.
  final bool poseEnabled;

  /// Web / encoded-image path (~10–15 FPS, drops while busy).
  final ValueChanged<CameraJpegFrame>? onJpegFrame;

  /// Native image-stream path. Ignored on web.
  final ValueChanged<CameraStreamFrame>? onStreamFrame;

  /// Live skeleton drawn inside the letterboxed camera rect.
  final ValueListenable<PoseFrame?>? poseFrameListenable;

  /// Return false to skip a JPEG capture (e.g. detector still busy / not ready).
  final bool Function()? canCaptureFrame;

  @override
  State<CoachCameraPreview> createState() => _CoachCameraPreviewState();
}

class _CoachCameraPreviewState extends State<CoachCameraPreview>
    with WidgetsBindingObserver {
  static const double _minZoom = 0.25;
  static const double _maxZoom = 5.0;
  static const Duration _webCaptureInterval = Duration(milliseconds: 150);

  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;

  String? _errorMessage;
  bool _initializing = true;

  double _zoom = 1.0;
  double _pinchBaseZoom = 1.0;

  Timer? _webCaptureTimer;
  bool _capturingJpeg = false;
  bool _streaming = false;

  bool get _isFrontCamera {
    if (_cameras.isEmpty) return true;
    return _cameras[_cameraIndex].lensDirection == CameraLensDirection.front;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void didUpdateWidget(covariant CoachCameraPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.poseEnabled != widget.poseEnabled) {
      if (widget.poseEnabled) {
        _startPoseFeed();
      } else {
        _stopPoseFeed();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_stopPoseFeed());
    final controller = _controller;
    _controller = null;
    controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      unawaited(_stopPoseFeed());
      _controller = null;
      if (mounted) setState(() {});
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_cameras.isNotEmpty) {
        _openCamera(_cameras[_cameraIndex]);
      } else {
        _bootstrap();
      }
    }
  }

  Future<void> _bootstrap() async {
    setState(() {
      _initializing = true;
      _errorMessage = null;
    });

    try {
      final cameras = await availableCameras();
      if (!mounted) return;

      if (cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _errorMessage = 'No camera found on this device.';
        });
        return;
      }

      _cameras = cameras;
      final frontIndex = cameras.indexWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
      );
      _cameraIndex = frontIndex >= 0 ? frontIndex : 0;
      await _openCamera(cameras[_cameraIndex]);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _errorMessage = _messageForCameraException(e);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _errorMessage =
            'Camera unavailable. Allow camera access and try again.';
      });
    }
  }

  Future<void> _openCamera(CameraDescription camera) async {
    setState(() {
      _initializing = true;
      _errorMessage = null;
    });

    await _stopPoseFeed();

    final previous = _controller;
    // Drop the disposed controller from the tree before releasing it.
    if (previous != null) {
      _controller = null;
      if (mounted) setState(() {});
    }

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: kIsWeb ? null : ImageFormatGroup.yuv420,
    );

    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      await previous?.dispose();
      // Helps web release the previous MediaStream before opening another.
      await Future<void>.delayed(const Duration(milliseconds: 80));

      if (!mounted) {
        await controller.dispose();
        return;
      }

      setState(() {
        _controller = controller;
        _zoom = 1.0;
        _initializing = false;
      });

      // Best-effort hardware zoom reset on mobile; ignored on web if unsupported.
      try {
        final min = await controller.getMinZoomLevel();
        await controller.setZoomLevel(min);
      } catch (_) {}

      if (widget.poseEnabled) {
        await _startPoseFeed();
      }
    } on CameraException catch (e) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _errorMessage = _messageForCameraException(e);
      });
    } catch (_) {
      await controller.dispose();
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _errorMessage =
            'Camera unavailable. Allow camera access and try again.';
      });
    }
  }

  Future<void> _startPoseFeed() async {
    final controller = _controller;
    if (!widget.poseEnabled ||
        controller == null ||
        !controller.value.isInitialized) {
      return;
    }

    if (kIsWeb || widget.onStreamFrame == null) {
      _webCaptureTimer?.cancel();
      _webCaptureTimer = Timer.periodic(_webCaptureInterval, (_) {
        unawaited(_captureJpegFrame());
      });
      return;
    }

    if (_streaming || controller.value.isStreamingImages) return;
    try {
      await controller.startImageStream(_onCameraImage);
      _streaming = true;
    } catch (e) {
      debugPrint('Image stream unavailable, falling back to JPEG: $e');
      _webCaptureTimer?.cancel();
      _webCaptureTimer = Timer.periodic(_webCaptureInterval, (_) {
        unawaited(_captureJpegFrame());
      });
    }
  }

  Future<void> _stopPoseFeed() async {
    _webCaptureTimer?.cancel();
    _webCaptureTimer = null;
    _capturingJpeg = false;

    final controller = _controller;
    if (_streaming &&
        controller != null &&
        controller.value.isStreamingImages) {
      try {
        await controller.stopImageStream();
      } catch (_) {}
    }
    _streaming = false;
  }

  Future<void> _captureJpegFrame() async {
    if (_capturingJpeg || !widget.poseEnabled || !mounted) return;
    if (widget.canCaptureFrame?.call() == false) return;

    final controller = _controller;
    final callback = widget.onJpegFrame;
    if (callback == null ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }

    _capturingJpeg = true;
    try {
      final file = await controller.takePicture();
      if (!mounted || !identical(_controller, controller)) return;

      final bytes = await file.readAsBytes();
      if (!mounted || !identical(_controller, controller) || bytes.isEmpty) {
        return;
      }

      final preview = controller.value.previewSize;
      final fromJpeg = _jpegPixelSize(bytes);
      final imageSize = fromJpeg ??
          Size(
            preview?.width ?? 1280,
            preview?.height ?? 720,
          );

      callback(
        CameraJpegFrame(
          bytes: bytes,
          imageSize: imageSize,
          mirrorHorizontally: _isFrontCamera,
        ),
      );
    } on CameraException catch (e) {
      // Common during flip/dispose — ignore disposed-controller races.
      if (e.code.contains('Disposed') || e.code.contains('disposed')) return;
      debugPrint('JPEG pose capture failed: $e');
    } catch (e) {
      debugPrint('JPEG pose capture failed: $e');
    } finally {
      _capturingJpeg = false;
    }
  }

  /// Reads SOF dimensions from a JPEG without a full decode.
  Size? _jpegPixelSize(Uint8List bytes) {
    if (bytes.length < 4 || bytes[0] != 0xFF || bytes[1] != 0xD8) return null;
    var i = 2;
    while (i + 9 < bytes.length) {
      if (bytes[i] != 0xFF) return null;
      final marker = bytes[i + 1];
      // Soften: skip fill bytes
      if (marker == 0xFF) {
        i++;
        continue;
      }
      // Standalone markers without length
      if (marker == 0xD8 || marker == 0xD9 || (marker >= 0xD0 && marker <= 0xD7)) {
        i += 2;
        continue;
      }
      final length = (bytes[i + 2] << 8) | bytes[i + 3];
      if (length < 2 || i + 2 + length > bytes.length) return null;
      // SOF0–SOF3, SOF5–SOF7, SOF9–SOF11, SOF13–SOF15
      final isSof = (marker >= 0xC0 && marker <= 0xC3) ||
          (marker >= 0xC5 && marker <= 0xC7) ||
          (marker >= 0xC9 && marker <= 0xCB) ||
          (marker >= 0xCD && marker <= 0xCF);
      if (isSof) {
        final height = (bytes[i + 5] << 8) | bytes[i + 6];
        final width = (bytes[i + 7] << 8) | bytes[i + 8];
        if (width > 0 && height > 0) {
          return Size(width.toDouble(), height.toDouble());
        }
        return null;
      }
      i += 2 + length;
    }
    return null;
  }

  void _onCameraImage(CameraImage image) {
    final controller = _controller;
    final callback = widget.onStreamFrame;
    if (!widget.poseEnabled || controller == null || callback == null) return;

    final rotation = rotationForFrame(
      width: image.width,
      height: image.height,
      sensorOrientation: controller.description.sensorOrientation,
      isFrontCamera: _isFrontCamera,
      deviceOrientation: controller.value.deviceOrientation,
    );

    final size = detectionSize(
      width: image.width,
      height: image.height,
      rotation: rotation,
      maxDim: 640,
    );

    callback(
      CameraStreamFrame(
        image: image,
        detectionImageSize: Size(size.width, size.height),
        mirrorHorizontally: _isFrontCamera,
        rotation: rotation,
      ),
    );
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _initializing) return;
    final next = (_cameraIndex + 1) % _cameras.length;
    _cameraIndex = next;
    await _openCamera(_cameras[next]);
  }

  void _setZoom(double value) {
    setState(() => _zoom = value.clamp(_minZoom, _maxZoom));
  }

  void _nudgeZoom(double delta) => _setZoom(_zoom + delta);

  String _messageForCameraException(CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
      case 'permissionDenied':
        return 'Camera permission denied. Allow access in browser or system settings.';
      case 'cameraNotReadable':
        return 'Camera is in use by another app. Close FaceTime or other camera apps and retry.';
      default:
        return e.description ?? 'Could not open the camera.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initializing) {
      return const ColoredBox(
        color: AppColors.coachDark,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.midTeal),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return _CameraFallback(
        message: _errorMessage ?? 'Camera unavailable.',
        onRetry: _bootstrap,
      );
    }

    return ColoredBox(
      color: AppColors.coachDark,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GestureDetector(
            onScaleStart: (_) => _pinchBaseZoom = _zoom,
            onScaleUpdate: (details) {
              _setZoom(_pinchBaseZoom * details.scale);
            },
            child: _DesktopCameraStage(
              controller: controller,
              zoom: _zoom,
              poseFrameListenable: widget.poseFrameListenable,
            ),
          ),
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: _CameraControls(
                zoom: _zoom,
                minZoom: _minZoom,
                maxZoom: _maxZoom,
                canFlip: _cameras.length > 1,
                lensLabel: _cameras.isEmpty
                    ? ''
                    : _cameras[_cameraIndex].lensDirection ==
                            CameraLensDirection.front
                        ? 'Front'
                        : 'Back',
                onFlip: _flipCamera,
                onZoomIn: () => _nudgeZoom(0.35),
                onZoomOut: () => _nudgeZoom(-0.35),
                onZoomChanged: _setZoom,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-window desktop/webcam stage — landscape frame, not a phone crop.
class _DesktopCameraStage extends StatelessWidget {
  const _DesktopCameraStage({
    required this.controller,
    required this.zoom,
    this.poseFrameListenable,
  });

  final CameraController controller;
  final double zoom;
  final ValueListenable<PoseFrame?>? poseFrameListenable;

  @override
  Widget build(BuildContext context) {
    final preview = controller.value.previewSize;
    // Use native landscape sensor size (do NOT swap like a phone portrait crop).
    final rawW = preview?.width ?? 1280;
    final rawH = preview?.height ?? 720;

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewW = constraints.maxWidth;
        final viewH = constraints.maxHeight;
        final viewAspect = viewW / viewH;
        final camAspect = rawW / rawH;

        // Fit the FULL webcam frame inside the window (room view / surroundings).
        late final double baseW;
        late final double baseH;
        if (viewAspect > camAspect) {
          // Window is wider than camera — fit to height, letterbox sides.
          baseH = viewH;
          baseW = baseH * camAspect;
        } else {
          // Window is taller — fit to width, letterbox top/bottom.
          baseW = viewW;
          baseH = baseW / camAspect;
        }

        return ClipRect(
          child: ColoredBox(
            color: AppColors.coachDark,
            child: Center(
              child: Transform.scale(
                scale: zoom,
                child: SizedBox(
                  width: baseW,
                  height: baseH,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      FittedBox(
                        fit: BoxFit.fill,
                        child: SizedBox(
                          width: rawW,
                          height: rawH,
                          child: CameraPreview(controller),
                        ),
                      ),
                      if (poseFrameListenable != null)
                        IgnorePointer(
                          child: LivePoseOverlay(
                            listenable: poseFrameListenable!,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CameraControls extends StatelessWidget {
  const _CameraControls({
    required this.zoom,
    required this.minZoom,
    required this.maxZoom,
    required this.canFlip,
    required this.lensLabel,
    required this.onFlip,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onZoomChanged,
  });

  final double zoom;
  final double minZoom;
  final double maxZoom;
  final bool canFlip;
  final String lensLabel;
  final VoidCallback onFlip;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final ValueChanged<double> onZoomChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.darkestNavy.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.midTeal.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (canFlip) ...[
            _ControlIconButton(
              tooltip: 'Flip camera',
              icon: Icons.cameraswitch_outlined,
              onPressed: onFlip,
            ),
            if (lensLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  lensLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.onCoachDark.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              const SizedBox(height: 8),
          ],
          _ControlIconButton(
            tooltip: 'Zoom in',
            icon: Icons.add,
            onPressed: zoom >= maxZoom - 0.01 ? null : onZoomIn,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              '${zoom.toStringAsFixed(1)}x',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(
            height: 120,
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 7),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: AppColors.midTeal,
                  inactiveTrackColor: AppColors.darkTeal,
                  thumbColor: AppColors.amber,
                ),
                child: Slider(
                  value: zoom.clamp(minZoom, maxZoom),
                  min: minZoom,
                  max: maxZoom,
                  onChanged: onZoomChanged,
                ),
              ),
            ),
          ),
          _ControlIconButton(
            tooltip: 'Zoom out',
            icon: Icons.remove,
            onPressed: zoom <= minZoom + 0.01 ? null : onZoomOut,
          ),
        ],
      ),
    );
  }
}

class _ControlIconButton extends StatelessWidget {
  const _ControlIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon),
      color: AppColors.onCoachDark,
      disabledColor: AppColors.onCoachDark.withValues(alpha: 0.3),
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.midTeal.withValues(alpha: 0.2),
      ),
    );
  }
}

class _CameraFallback extends StatelessWidget {
  const _CameraFallback({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: AppColors.coachDark,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.videocam_off_outlined,
                size: 48,
                color: AppColors.midTeal,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.onCoachDark.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onRetry,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.action,
                  foregroundColor: AppColors.onPrimary,
                ),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
