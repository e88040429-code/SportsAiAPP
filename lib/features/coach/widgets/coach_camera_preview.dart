import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/sport/shell_tab_scope.dart';
import '../../../core/theme/app_colors.dart';

/// Live device camera feed for the Coach HUD (web + mobile).
///
/// Zoom is digital crop-in only (min 1x = full frame). Zooming out past the
/// fitted frame is disabled so you never get empty letterbox “zoom”.
///
/// Camera only starts while the Coach bottom-nav tab is active — the shell uses
/// an IndexedStack, so this widget can stay mounted on other tabs.
class CoachCameraPreview extends StatefulWidget {
  const CoachCameraPreview({super.key});

  @override
  State<CoachCameraPreview> createState() => _CoachCameraPreviewState();
}

class _CoachCameraPreviewState extends State<CoachCameraPreview>
    with WidgetsBindingObserver {
  /// 1x = full camera frame fitted in the window. No zoom-out below that.
  static const double _fitZoom = 1.0;
  static const double _defaultMaxZoom = 3.0;

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
      _bootstrap();
    } else {
      _releaseCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_tabActive) return;

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      if (state == AppLifecycleState.resumed) {
        _bootstrap();
      }
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

  Future<void> _releaseCamera() async {
    final previous = _controller;
    _controller = null;
    if (mounted) {
      setState(() {
        _initializing = false;
        // Keep last error so returning to Coach still explains a block.
      });
    }
    await previous?.dispose();
  }

  Future<void> _bootstrap() async {
    if (!_tabActive) return;

    setState(() {
      _initializing = true;
      // Keep prior permission copy until a new result arrives.
    });

    try {
      final cameras = await availableCameras();
      if (!mounted || !_tabActive) return;

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
      if (!mounted || !_tabActive) return;
      _applyCameraFailure(e);
    } catch (_) {
      if (!mounted || !_tabActive) return;
      setState(() {
        _initializing = false;
        _permissionBlocked = false;
        _errorMessage =
            'Camera unavailable. Allow camera access and try again.';
      });
    }
  }

  Future<void> _openCamera(CameraDescription camera) async {
    if (!_tabActive) return;

    setState(() {
      _initializing = true;
    });

    final previous = _controller;
    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await controller.initialize();
      if (!mounted || !_tabActive) {
        await controller.dispose();
        return;
      }

      await previous?.dispose();
      // Helps web release the previous MediaStream before opening another.
      await Future<void>.delayed(const Duration(milliseconds: 80));

      if (!mounted || !_tabActive) {
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
    } on CameraException catch (e) {
      await controller.dispose();
      if (!mounted || !_tabActive) return;
      _applyCameraFailure(e);
    } catch (_) {
      await controller.dispose();
      if (!mounted || !_tabActive) return;
      setState(() {
        _initializing = false;
        _permissionBlocked = false;
        _errorMessage =
            'Camera unavailable. Allow camera access and try again.';
      });
    }
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
    switch (e.code) {
      case 'cameraNotReadable':
        return 'Camera is in use by another app. Close other camera apps and retry.';
      default:
        return e.description ?? 'Could not open the camera.';
    }
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
              // Hardware zoom already applied on the stream; don't double-scale.
              zoom: _useHardwareZoom ? _fitZoom : _zoom / _minZoom,
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
