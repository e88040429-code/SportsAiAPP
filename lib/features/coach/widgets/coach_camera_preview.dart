import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Live device camera feed for the Coach HUD (web + mobile).
///
/// Prefers the front-facing camera (FaceTime / selfie cam). Falls back to a
/// dark placeholder if permission is denied or no camera is available.
class CoachCameraPreview extends StatefulWidget {
  const CoachCameraPreview({super.key});

  @override
  State<CoachCameraPreview> createState() => _CoachCameraPreviewState();
}

class _CoachCameraPreviewState extends State<CoachCameraPreview>
    with WidgetsBindingObserver {
  CameraController? _controller;
  String? _errorMessage;
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCamera();
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
      _startCamera();
    }
  }

  Future<void> _startCamera() async {
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

      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      await _controller?.dispose();
      setState(() {
        _controller = controller;
        _initializing = false;
      });
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
        onRetry: _startCamera,
      );
    }

    return ColoredBox(
      color: AppColors.coachDark,
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: controller.value.previewSize?.height ?? 720,
            height: controller.value.previewSize?.width ?? 1280,
            child: CameraPreview(controller),
          ),
        ),
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
