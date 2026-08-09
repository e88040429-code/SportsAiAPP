import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/sport/app_sport.dart';
import '../../core/sport/shell_tab_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/sport_colors.dart';
import 'data/clip_analysis_session.dart';
import 'data/clip_form_analyzer.dart';
import 'data/clip_import_validator.dart';
import 'data/clip_video_loader.dart';
import 'data/coach_mock_data.dart';
import 'data/model_pose_library.dart';
import 'data/picked_file_bytes.dart';
import 'pose/live_pose_coach.dart';
import 'pose/live_session_recorder.dart';
import 'pose/pose_detector_service.dart';
import 'pose/pose_frame.dart';
import 'widgets/clip_analysis_panel.dart';
import 'widgets/coach_camera_preview.dart';
import 'widgets/coach_metrics_bar.dart';
import 'widgets/cue_bubble.dart';
import 'widgets/record_button.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  bool _isRecording = false;
  bool _analyzingClip = false;
  bool _converting = false;
  bool _tabActive = false;
  String? _previewNote;

  String? _clipName;
  VideoPlayerController? _video;
  Uint8List? _stillImageBytes;
  PoseFrame? _stillPose;
  List<CoachMetric> _stillMetrics = const [];
  bool _importIsImage = false;
  SkillModelKind _modelKind = SkillModelKind.hitting;
  ClipAnalysisResult? _analysis;
  final _athleteDescriptionController = TextEditingController();
  final PoseDetectorService _poseService = PoseDetectorService();
  final LivePoseCoach _poseCoach = LivePoseCoach();
  final LiveSessionRecorder _sessionRecorder = LiveSessionRecorder();

  @override
  void initState() {
    super.initState();
    unawaited(_poseService.initialize());
    _poseService.latestFrame.addListener(_onLivePoseFrame);
  }

  void _onLivePoseFrame() {
    if (!_isRecording) return;
    _sessionRecorder.addFrame(_poseService.latestFrame.value);
  }

  void _onJpegFrame(CameraJpegFrame frame) {
    unawaited(
      _poseService.processImageBytes(
        frame.bytes,
        imageSize: frame.imageSize,
        mirrorHorizontally: frame.mirrorHorizontally,
      ),
    );
  }

  void _onStreamFrame(CameraStreamFrame frame) {
    unawaited(
      _poseService.processCameraImage(
        frame.image,
        detectionImageSize: frame.detectionImageSize,
        mirrorHorizontally: frame.mirrorHorizontally,
        rotation: frame.rotation,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final index = ShellTabScope.indexOf(context);
    final active = index == kCoachShellBranchIndex;
    if (active == _tabActive) return;
    _tabActive = active;
    if (!active && _isRecording) {
      // Leaving Coach mid-record stops the session UI state.
      setState(() => _isRecording = false);
    }
  }

  void _onBack() {
    if (_analyzingClip) {
      _closeAnalysis();
      return;
    }
    if (_isRecording) {
      setState(() => _isRecording = false);
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  void _toggleRecording() {
    if (!_isRecording) {
      _sessionRecorder.start();
      setState(() => _isRecording = true);
      return;
    }

    final sport = appSportController.sport;
    final analysis = _sessionRecorder.finish(
      sport: sport,
      kind: SkillModelKind.hitting,
    );
    setState(() => _isRecording = false);

    if (analysis == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Recording too short — move in frame for a few seconds, then stop.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    clipAnalysisController.publish(analysis);
    context.go('/recap');
  }

  Future<void> _importClip() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: kAllowedImportExtensions.toList(growable: false),
      withData: kIsWeb, // Web needs bytes to sniff; avoid loading whole clips on mobile.
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;

    final rejection = ClipImportValidator.validate(file);
    if (rejection != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rejection),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final name = file.name;
    final ext = (file.extension ?? name.split('.').last).toLowerCase();
    final stillImage = isImageImportExtension(ext);

    setState(() {
      _analyzingClip = true;
      _converting = stillImage;
      _clipName = name;
      _previewNote = null;
      _modelKind = SkillModelKind.hitting;
      _athleteDescriptionController.clear();
      _analysis = null;
      _stillImageBytes = null;
      _stillPose = null;
      _stillMetrics = const [];
      _importIsImage = stillImage;
    });
    _poseService.clearFrame();
    _poseCoach.reset();
    if (_isRecording) {
      _sessionRecorder.cancel();
      _isRecording = false;
    }

    await _disposeVideo();
    if (stillImage) {
      unawaited(_loadStillImage(file));
    } else {
      unawaited(_loadVideoPreview(file, ext));
    }
  }

  Future<void> _loadStillImage(PlatformFile file) async {
    final bytes = await readPickedFileBytes(file);
    if (!mounted) return;
    if (bytes == null || bytes.isEmpty) {
      setState(() {
        _converting = false;
        _previewNote =
            'Could not read that photo. Try another JPG or PNG.';
      });
      return;
    }

    setState(() => _stillImageBytes = bytes);

    await _poseService.initialize();
    if (!mounted) return;
    if (!_poseService.isReady) {
      setState(() {
        _converting = false;
        _previewNote =
            'Pose model isn’t ready yet. Tap Generate after it finishes loading.';
      });
      return;
    }

    final imageSize = await _decodeImageSize(bytes);
    final frame = await _poseService.detectStillImage(
      bytes,
      imageSize: imageSize,
    );
    if (!mounted) return;

    if (frame == null) {
      setState(() {
        _converting = false;
        _stillPose = null;
        _stillMetrics = const [];
        _previewNote =
            'No person found in this photo. Try a clearer full-body standing shot.';
      });
      return;
    }

    final insights = _poseCoach.analyze(frame, appSportController.sport, stillImage: true);
    final analysis = ClipFormAnalyzer.analyzeStill(
      clipName: _clipName ?? file.name,
      sport: appSportController.sport,
      kind: _modelKind,
      frame: frame,
    );
    clipAnalysisController.publish(analysis);
    setState(() {
      _stillPose = frame;
      _stillMetrics = insights.metrics;
      _analysis = analysis;
      _converting = false;
      _previewNote = null;
    });
  }

  Future<Size> _decodeImageSize(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final size = Size(image.width.toDouble(), image.height.toDouble());
      image.dispose();
      return size.width > 0 && size.height > 0
          ? size
          : const Size(1280, 720);
    } catch (_) {
      return const Size(1280, 720);
    }
  }

  Future<void> _loadVideoPreview(PlatformFile file, String ext) async {
    VideoPlayerController? controller;
    try {
      controller = await loadClipVideo(file);
      await controller.initialize().timeout(const Duration(seconds: 4));
      await controller.setLooping(true);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _video = controller;
        _previewNote = null;
      });
      await controller.play();
    } catch (_) {
      await controller?.dispose();
      if (!mounted) return;
      setState(() {
        _video = null;
        _previewNote = ext == 'mov' || ext == 'mkv'
            ? 'Chrome can’t preview this $ext clip. You can still describe it and tap Generate.'
            : 'Video preview isn’t available. Describe the clip below, then tap Generate.';
      });
    }
  }

  Future<void> _generateFeedback() async {
    final name = _clipName;
    if (name == null || _converting) return;

    final description = _athleteDescriptionController.text.trim();
    if (!_importIsImage && description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a short description of your clip first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_importIsImage) {
      final frame = _stillPose;
      if (frame == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No pose in this photo yet. Try another full-body shot.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      setState(() => _converting = true);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final analysis = ClipFormAnalyzer.analyzeStill(
        clipName: name,
        sport: appSportController.sport,
        kind: _modelKind,
        frame: frame,
      ).copyWith(athleteDescription: description);
      clipAnalysisController.publish(analysis);
      if (!mounted) return;
      setState(() {
        _analysis = analysis;
        _converting = false;
      });
      return;
    }

    setState(() => _converting = true);

    // Brief pause so Generate feels intentional, then analyze.
    await Future<void>.delayed(const Duration(milliseconds: 350));

    final sport = appSportController.sport;
    final athlete = ModelPoseLibrary.athleteSequenceFromClip(
      sport: sport,
      kind: _modelKind,
      clipName: '$name|$description',
    );
    final model = ModelPoseLibrary.modelSequence(sport, _modelKind);
    final analysis = ClipFormAnalyzer.analyze(
      clipName: name,
      sport: sport,
      kind: _modelKind,
      athleteSeq: athlete,
      modelSeq: model,
    ).copyWith(athleteDescription: description);

    clipAnalysisController.publish(analysis);

    if (!mounted) return;
    setState(() {
      _analysis = analysis;
      _converting = false;
    });
  }

  void _onKindChanged(SkillModelKind kind) {
    setState(() => _modelKind = kind);
    final frame = _stillPose;
    if (_importIsImage && frame != null && !_converting) {
      final analysis = ClipFormAnalyzer.analyzeStill(
        clipName: _clipName ?? 'Imported photo',
        sport: appSportController.sport,
        kind: kind,
        frame: frame,
      ).copyWith(athleteDescription: _athleteDescriptionController.text.trim());
      clipAnalysisController.publish(analysis);
      setState(() => _analysis = analysis);
    }
  }

  void _openRecap() {
    final description = _athleteDescriptionController.text.trim();
    final current = _analysis;
    if (current != null && description.isNotEmpty) {
      final updated = current.copyWith(athleteDescription: description);
      clipAnalysisController.publish(updated);
      setState(() => _analysis = updated);
    }
    context.go('/recap');
  }

  Future<void> _closeAnalysis() async {
    await _disposeVideo();
    if (!mounted) return;
    setState(() {
      _analyzingClip = false;
      _converting = false;
      _clipName = null;
      _previewNote = null;
      _analysis = null;
      _stillImageBytes = null;
      _stillPose = null;
      _stillMetrics = const [];
      _importIsImage = false;
      // Keep last published result in clipAnalysisController for Recap.
    });
  }

  Future<void> _disposeVideo() async {
    final c = _video;
    _video = null;
    if (c != null) {
      await c.dispose();
    }
  }

  @override
  void dispose() {
    _sessionRecorder.cancel();
    _poseService.latestFrame.removeListener(_onLivePoseFrame);
    _athleteDescriptionController.dispose();
    _video?.dispose();
    final poseService = _poseService;
    super.dispose();
    unawaited(poseService.dispose());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: appSportController,
      builder: (context, _) {
        final sport = appSportController.sport;
        final colors = SportColors.of(sport);

        if (_analyzingClip) {
          return Scaffold(
            backgroundColor: AppColors.coachDark,
            body: ClipAnalysisPanel(
              sport: sport,
              kind: _modelKind,
              clipName: _clipName ??
                  (_importIsImage ? 'Imported photo' : 'Imported clip'),
              videoController: _video,
              previewNote: _previewNote,
              imageBytes: _stillImageBytes,
              stillPose: _stillPose,
              stillMetrics: _stillMetrics,
              isStillImage: _importIsImage,
              isGenerating: _converting,
              analysis: _analysis,
              athleteDescriptionController: _athleteDescriptionController,
              onKindChanged: _onKindChanged,
              onClose: _closeAnalysis,
              onGenerate: _generateFeedback,
              onOpenRecap: _openRecap,
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppColors.coachDark,
          body: Stack(
            fit: StackFit.expand,
            children: [
              CoachCameraPreview(
                poseEnabled: true,
                onJpegFrame: _onJpegFrame,
                // Image streams are unsupported on web and Windows camera_windows.
                onStreamFrame: (kIsWeb ||
                        defaultTargetPlatform == TargetPlatform.windows)
                    ? null
                    : _onStreamFrame,
                poseFrameListenable: _poseService.latestFrame,
                canCaptureFrame: () =>
                    _poseService.isReady && !_poseService.isBusy,
              ),
              IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.darkestNavy.withValues(alpha: 0.55),
                        AppColors.darkestNavy.withValues(alpha: 0.12),
                        AppColors.darkestNavy.withValues(alpha: 0.55),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: _onBack,
                              icon: const Icon(Icons.arrow_back),
                              color: AppColors.onCoachDark,
                              tooltip: 'Back',
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Live Coach · ${sport.label}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppColors.onCoachDark,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            ValueListenableBuilder<String?>(
                              valueListenable: _poseService.statusMessage,
                              builder: (context, status, _) {
                                if (status != null) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Text(
                                      status,
                                      style:
                                          theme.textTheme.labelSmall?.copyWith(
                                        color: AppColors.onCoachDark
                                            .withValues(alpha: 0.75),
                                      ),
                                    ),
                                  );
                                }
                                return ValueListenableBuilder<PoseFrame?>(
                                  valueListenable: _poseService.latestFrame,
                                  builder: (context, frame, _) {
                                    if (frame == null) {
                                      return const SizedBox.shrink();
                                    }
                                    return Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.coachLine
                                            .withValues(alpha: 0.85),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'Tracking',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                          color: AppColors.onCoachDark,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                            if (_isRecording)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.darkRed.withValues(alpha: 0.9),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'REC',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppColors.onCoachDark,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            FilledButton.icon(
                              onPressed: _importClip,
                              style: FilledButton.styleFrom(
                                backgroundColor: colors.action,
                                foregroundColor: AppColors.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              icon: const Icon(Icons.perm_media_outlined, size: 18),
                              label: const Text('Import clip / photo'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 56,
                      left: 20,
                      right: 20,
                      child: ValueListenableBuilder<PoseFrame?>(
                        valueListenable: _poseService.latestFrame,
                        builder: (context, frame, _) {
                          final insights = _poseCoach.analyze(frame, sport);
                          return CueBubble(message: insights.cue);
                        },
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 12,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ValueListenableBuilder<PoseFrame?>(
                            valueListenable: _poseService.latestFrame,
                            builder: (context, frame, _) {
                              final insights = _poseCoach.analyze(frame, sport);
                              return CoachMetricsBar(metrics: insights.metrics);
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _importClip,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.onCoachDark,
                                    side: BorderSide(
                                      color: colors.coachLine.withValues(alpha: 0.7),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  icon: const Icon(Icons.upload_file),
                                  label: Text(
                                    kIsWeb
                                        ? 'Import clip or photo'
                                        : 'Import clip or photo',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              RecordButton(
                                isRecording: _isRecording,
                                onPressed: _toggleRecording,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
