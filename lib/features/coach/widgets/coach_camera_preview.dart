import 'dart:async';
import 'dart:ui' show ViewFocusEvent, ViewFocusState;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pose_detection/pose_detection.dart';

import '../../../core/sport/shell_tab_scope.dart';
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
/// Zoom is digital crop-in only (min 1x = full frame). Zooming out past the
/// fitted frame is disabled so you never get empty letterbox “zoom”.
///
/// Camera only starts while the Coach bottom-nav tab is active — the shell uses
/// an IndexedStack, so this widget can stay mounted on other tabs.
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
  /// 1x = full camera frame fitted in the window. No zoom-out below that.
  static const double _fitZoom = 1.0;
  static const double _defaultMaxZoom = 3.0;
  static const Duration _webCaptureInterval = Duration(milliseconds: 150);

  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;

  String? _errorMessage;
  bool _permissionBlocked = false;
  bool _initializing = false;
  bool _tabActive = false;

  double _zoom = _fitZoom;
  double _minZoom = _fitZoom;
  double _maxZoom = _defaultMaxZoom;
  double _pinchBaseZoom = _fitZoom;
  bool _useHardwareZoom = false;

  Timer? _webCaptureTimer;
  bool _capturingJpeg = false;
  bool _streaming = false;

  /// Bumped on every open/release so stale async camera work is ignored.
  int _cameraOp = 0;
  bool _windowFocused = true;

  bool get _isFrontCamera {
    if (_cameras.isEmpty) return true;
    return _cameras[_cameraIndex].lensDirection == CameraLensDirection.front;
  }

  bool get _shouldHoldCamera => _tabActive && _windowFocused;

  CameraController? _usableController([CameraController? candidate]) {
    final controller = candidate ?? _controller;
    if (controller == null || !identical(_controller, controller)) return null;
    try {
      if (!controller.value.isInitialized || controller.value.hasError) {
        return null;
      }
      return controller;
    } catch (_) {
      // Disposed controllers throw if you touch [value].
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final index = ShellTabScope.indexOf(context);
    final active = index == kCoachShellBranchIndex;
    if (active == _tabActive) return;
    _tabActive = active;
    if (active) {
      if (_windowFocused) {
        unawaited(_bootstrap());
      }
    } else {
      unawaited(_releaseCamera());
    }
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
    _cameraOp++;
    unawaited(_stopPoseFeed());
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      controller.removeListener(_onControllerUpdated);
      unawaited(controller.dispose());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_tabActive) return;

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        // Drop the device before another app can steal it (Windows crash path).
        unawaited(_releaseCamera());
      case AppLifecycleState.resumed:
        if (_windowFocused) unawaited(_reopenIfNeeded());
    }
  }

  @override
  void didChangeViewFocus(ViewFocusEvent event) {
    _windowFocused = event.state == ViewFocusState.focused;
    if (!_tabActive) return;

    if (!_windowFocused) {
      unawaited(_releaseCamera());
    } else {
      unawaited(_reopenIfNeeded());
    }
  }

  void _onControllerUpdated() {
    final controller = _controller;
    if (controller == null) return;
    try {
      if (!controller.value.hasError) return;
    } catch (_) {
      unawaited(_releaseCamera());
      return;
    }
    unawaited(_handleCameraLost(controller.value.errorDescription));
  }

  Future<void> _handleCameraLost(String? description) async {
    await _releaseCamera();
    if (!mounted || !_tabActive) return;
    setState(() {
      _initializing = false;
      _permissionBlocked = false;
      _errorMessage = _messageForLostCamera(description);
    });
  }

  Future<void> _reopenIfNeeded() async {
    if (!_shouldHoldCamera || _initializing) return;
    if (_usableController() != null) return;
    if (_cameras.isNotEmpty) {
      await _openCamera(_cameras[_cameraIndex]);
    } else {
      await _bootstrap();
    }
  }

  Future<void> _releaseCamera() async {
    final op = ++_cameraOp;
    await _stopPoseFeed();

    final deadline = DateTime.now().add(const Duration(milliseconds: 500));
    while (_capturingJpeg && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
    _capturingJpeg = false;

    if (op != _cameraOp) return;

    final previous = _controller;
    _controller = null;
    if (mounted) {
      setState(() {
        _initializing = false;
      });
    }
    if (previous != null) {
      previous.removeListener(_onControllerUpdated);
      try {
        await previous.dispose();
      } catch (_) {}
    }
  }

  Future<void> _bootstrap() async {
    if (!_shouldHoldCamera) return;

    setState(() {
      _initializing = true;
      // Keep prior permission copy until a new result arrives.
    });

    try {
      final cameras = await availableCameras();
      if (!mounted || !_shouldHoldCamera) return;

      if (cameras.isEmpty) {
        setState(() {
          _initializing = false;
          _permissionBlocked = false;
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
      if (!mounted || !_shouldHoldCamera) return;
      _applyCameraFailure(e);
    } catch (_) {
      if (!mounted || !_shouldHoldCamera) return;
      setState(() {
        _initializing = false;
        _permissionBlocked = false;
        _errorMessage =
            'Camera unavailable. Allow camera access and try again.';
      });
    }
  }

  Future<void> _openCamera(CameraDescription camera) async {
    if (!_shouldHoldCamera) return;

    final op = ++_cameraOp;
    setState(() {
      _initializing = true;
    });

    await _stopPoseFeed();

    final previous = _controller;
    // Drop the disposed controller from the tree before releasing it.
    if (previous != null) {
      previous.removeListener(_onControllerUpdated);
      _controller = null;
      if (mounted) setState(() {});
    }

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      // YUV stream path is mobile-oriented; web/Windows use JPEG snapshots.
      imageFormatGroup: (!kIsWeb &&
              defaultTargetPlatform != TargetPlatform.windows)
          ? ImageFormatGroup.yuv420
          : null,
    );

    try {
      await controller.initialize();
      if (op != _cameraOp || !mounted || !_shouldHoldCamera) {
        await controller.dispose();
        return;
      }

      if (previous != null) {
        try {
          await previous.dispose();
        } catch (_) {}
      }
      // Helps web release the previous MediaStream before opening another.
      await Future<void>.delayed(const Duration(milliseconds: 80));

      if (op != _cameraOp || !mounted || !_shouldHoldCamera) {
        await controller.dispose();
        return;
      }

      var minZoom = _fitZoom;
      var maxZoom = _defaultMaxZoom;
      var useHardware = false;

      try {
        final hwMin = await controller.getMinZoomLevel();
        final hwMax = await controller.getMaxZoomLevel();
        // Only use hardware zoom when the device actually offers a range.
        if (hwMax > hwMin + 0.01) {
          minZoom = hwMin;
          maxZoom = hwMax;
          useHardware = true;
          await controller.setZoomLevel(hwMin);
        }
      } catch (_) {
        // Web / unsupported — digital crop-in from 1x.
      }

      if (op != _cameraOp || !mounted || !_shouldHoldCamera) {
        await controller.dispose();
        return;
      }

      controller.addListener(_onControllerUpdated);
      setState(() {
        _controller = controller;
        _minZoom = useHardware ? minZoom : _fitZoom;
        _maxZoom = useHardware ? maxZoom : _defaultMaxZoom;
        _useHardwareZoom = useHardware;
        _zoom = _minZoom;
        _initializing = false;
        _errorMessage = null;
        _permissionBlocked = false;
      });

      if (op != _cameraOp) {
        controller.removeListener(_onControllerUpdated);
        _controller = null;
        await controller.dispose();
        return;
      }

      if (widget.poseEnabled) {
        await _startPoseFeed();
      }
    } on CameraException catch (e) {
      try {
        await controller.dispose();
      } catch (_) {}
      if (op != _cameraOp || !mounted || !_shouldHoldCamera) return;
      _applyCameraFailure(e);
    } catch (_) {
      try {
        await controller.dispose();
      } catch (_) {}
      if (op != _cameraOp || !mounted || !_shouldHoldCamera) return;
      setState(() {
        _initializing = false;
        _permissionBlocked = false;
        _errorMessage =
            'Camera unavailable. Allow camera access and try again.';
      });
    }
  }

  Future<void> _startPoseFeed() async {
    final live = _usableController();
    if (!widget.poseEnabled || live == null) return;

    if (kIsWeb || widget.onStreamFrame == null) {
      _webCaptureTimer?.cancel();
      _webCaptureTimer = Timer.periodic(_webCaptureInterval, (_) {
        unawaited(_captureJpegFrame());
      });
      return;
    }

    try {
      if (_streaming || live.value.isStreamingImages) return;
      await live.startImageStream(_onCameraImage);
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

    final controller = _controller;
    if (_streaming && controller != null) {
      try {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
      } catch (_) {}
    }
    _streaming = false;
  }

  Future<void> _captureJpegFrame() async {
    if (_capturingJpeg || !widget.poseEnabled || !mounted || !_shouldHoldCamera) {
      return;
    }
    if (widget.canCaptureFrame?.call() == false) return;

    final live = _usableController();
    final callback = widget.onJpegFrame;
    if (callback == null || live == null) return;
    try {
      if (live.value.isTakingPicture) return;
    } catch (_) {
      return;
    }

    _capturingJpeg = true;
    try {
      final file = await live.takePicture();
      if (!mounted || !identical(_controller, live)) return;

      final bytes = await file.readAsBytes();
      if (!mounted || !identical(_controller, live) || bytes.isEmpty) {
        return;
      }

      final preview = live.value.previewSize;
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
      if (_isDisposedCameraError(e.code, e.description)) {
        await _stopPoseFeed();
        return;
      }
      if (_isCameraInUseError(e.code, e.description)) {
        await _handleCameraLost(e.description);
        return;
      }
      debugPrint('JPEG pose capture failed: $e');
    } catch (e) {
      if (_isDisposedCameraError('', e.toString())) {
        await _stopPoseFeed();
        return;
      }
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
    final live = _usableController();
    final callback = widget.onStreamFrame;
    if (!widget.poseEnabled || live == null || callback == null) {
      return;
    }

    final rotation = rotationForFrame(
      width: image.width,
      height: image.height,
      sensorOrientation: live.description.sensorOrientation,
      isFrontCamera: _isFrontCamera,
      deviceOrientation: live.value.deviceOrientation,
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

  void _applyCameraFailure(CameraException e) {
    final blocked = _isPermissionDenial(e);
    setState(() {
      _initializing = false;
      _permissionBlocked = blocked;
      _errorMessage = blocked
          ? _permissionBlockedMessage()
          : _messageForCameraException(e);
    });
  }

  bool _isPermissionDenial(CameraException e) {
    switch (e.code) {
      case 'CameraAccessDenied':
      case 'CameraAccessDeniedWithoutPrompt':
      case 'CameraAccessRestricted':
      case 'permissionDenied':
      case 'SecurityError':
        return true;
      default:
        final desc = (e.description ?? '').toLowerCase();
        return desc.contains('permission') ||
            desc.contains('not allowed') ||
            desc.contains('denied');
    }
  }

  String _permissionBlockedMessage() {
    if (kIsWeb) {
      return 'Camera is blocked for this site. Chrome won’t ask again until you allow it in site settings.';
    }
    return 'Camera permission denied. Allow access in system settings, then tap Try again.';
  }

  String _messageForCameraException(CameraException e) {
    if (_isCameraInUseError(e.code, e.description)) {
      return _messageForLostCamera(e.description);
    }
    switch (e.code) {
      case 'cameraNotReadable':
        return 'Camera is in use by another app. Close other camera apps and retry.';
      default:
        return e.description ?? 'Could not open the camera.';
    }
  }

  String _messageForLostCamera(String? description) {
    if (_isCameraInUseError('', description)) {
      return 'Camera is in use by another app. Close that app, then tap Try again.';
    }
    if (description != null && description.trim().isNotEmpty) {
      return description;
    }
    return 'Camera disconnected. Tap Try again.';
  }

  bool _isDisposedCameraError(String code, String? description) {
    final text = '$code ${description ?? ''}'.toLowerCase();
    return text.contains('disposed') || text.contains('used after');
  }

  bool _isCameraInUseError(String code, String? description) {
    final text = '$code ${description ?? ''}'.toLowerCase();
    return text.contains('in use') ||
        text.contains('notreadable') ||
        text.contains('not readable') ||
        text.contains('cameraexclusive') ||
        text.contains('exclusive') ||
        text.contains('already in use') ||
        text.contains('device busy');
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2 || _initializing) return;
    final next = (_cameraIndex + 1) % _cameras.length;
    _cameraIndex = next;
    await _openCamera(_cameras[next]);
  }

  Future<void> _setZoom(double value) async {
    final next = value.clamp(_minZoom, _maxZoom);
    if ((next - _zoom).abs() < 0.001) return;

    setState(() => _zoom = next);

    if (_useHardwareZoom) {
      final controller = _controller;
      if (controller == null || !controller.value.isInitialized) return;
      try {
        await controller.setZoomLevel(next);
      } catch (_) {
        // Keep UI zoom; hardware may reject edge values.
      }
    }
  }

  void _nudgeZoom(double delta) => _setZoom(_zoom + delta);

  @override
  Widget build(BuildContext context) {
    if (!_tabActive) {
      return const ColoredBox(color: AppColors.coachDark);
    }

    if (_initializing) {
      // Static placeholder (not CircularProgressIndicator) so IndexedStack
      // offstage ticks don't block widget-test pumpAndSettle.
      return const ColoredBox(
        color: AppColors.coachDark,
        child: Center(
          child: Icon(
            Icons.videocam_outlined,
            size: 40,
            color: AppColors.midTeal,
          ),
        ),
      );
    }

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return _CameraFallback(
        message: _errorMessage ?? 'Camera unavailable.',
        permissionBlocked: _permissionBlocked,
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
                onZoomIn: () => _nudgeZoom((_maxZoom - _minZoom) * 0.12),
                onZoomOut: () => _nudgeZoom(-(_maxZoom - _minZoom) * 0.12),
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
///
/// [zoom] is a digital crop factor where 1.0 = full fitted frame. Values below
/// 1.0 are not used by the parent.
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
          baseH = viewH;
          baseW = baseH * camAspect;
        } else {
          baseW = viewW;
          baseH = baseW / camAspect;
        }

        final scale = zoom < 1.0 ? 1.0 : zoom;

        return ClipRect(
          child: ColoredBox(
            color: AppColors.coachDark,
            child: Center(
              child: Transform.scale(
                scale: scale,
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
    // Normalize label to “1.0x … Nx” relative to the fitted frame.
    final labelZoom = minZoom <= 0 ? zoom : (zoom / minZoom);

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
              '${labelZoom.toStringAsFixed(1)}x',
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
    this.permissionBlocked = false,
  });

  final String message;
  final VoidCallback onRetry;
  final bool permissionBlocked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: AppColors.coachDark,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
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
                if (permissionBlocked && kIsWeb) ...[
                  const SizedBox(height: 16),
                  Text(
                    'In Chrome: click the tune/lock icon left of the URL → '
                    'Site settings → Camera → Allow. Then tap Try again '
                    '(or reload the page).',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.onCoachDark.withValues(alpha: 0.65),
                      height: 1.4,
                    ),
                  ),
                ],
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
      ),
    );
  }
}
