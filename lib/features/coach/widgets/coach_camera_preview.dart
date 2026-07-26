import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Live device camera feed for the Coach HUD (web + mobile).
///
/// Supports lens flip when multiple cameras exist, plus a wide zoom range
/// (pinch + on-screen controls). Falls back to a dark placeholder if unavailable.
class CoachCameraPreview extends StatefulWidget {
  const CoachCameraPreview({super.key});

  @override
  State<CoachCameraPreview> createState() => _CoachCameraPreviewState();
}

class _CoachCameraPreviewState extends State<CoachCameraPreview>
    with WidgetsBindingObserver {
  static const double _minZoom = 0.25;
  static const double _maxZoom = 5.0;

  CameraController? _controller;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;

  String? _errorMessage;
  bool _initializing = true;

  double _zoom = 1.0;
  double _pinchBaseZoom = 1.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
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

    final previous = _controller;
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
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
  });

  final CameraController controller;
  final double zoom;

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
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: SizedBox(
                      width: rawW,
                      height: rawH,
                      child: CameraPreview(controller),
                    ),
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
