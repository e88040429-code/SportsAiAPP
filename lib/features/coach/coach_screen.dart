import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../core/sport/app_sport.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/sport_colors.dart';
import 'data/clip_analysis_session.dart';
import 'data/clip_form_analyzer.dart';
import 'data/clip_video_loader.dart';
import 'data/model_pose_library.dart';
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
  String? _previewNote;

  String? _clipName;
  VideoPlayerController? _video;
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

  void _onBack() {
    if (_analyzingClip) {
      _closeAnalysis();
      return;
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
      allowedExtensions: const ['mp4', 'mov', 'm4v', 'webm', 'avi', 'mkv'],
      withData: kIsWeb,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final name = file.name;
    final ext = (file.extension ?? name.split('.').last).toLowerCase();

    setState(() {
      _analyzingClip = true;
      _converting = false;
      _clipName = name;
      _previewNote = null;
      _modelKind = SkillModelKind.hitting;
      _athleteDescriptionController.clear();
      _analysis = null;
    });
    _poseService.clearFrame();
    _poseCoach.reset();
    if (_isRecording) {
      _sessionRecorder.cancel();
      _isRecording = false;
    }

    await _disposeVideo();
    // Load video in background — description + Generate come first.
    unawaited(_loadVideoPreview(file, ext));
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
    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a short description of your clip first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
    // Don't auto-generate — athlete taps Generate again after changing skill.
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
              clipName: _clipName ?? 'Imported clip',
              videoController: _video,
              previewNote: _previewNote,
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
                onStreamFrame: kIsWeb ? null : _onStreamFrame,
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
                              icon: const Icon(Icons.video_file_outlined, size: 18),
                              label: const Text('Import clip'),
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
                                        ? 'Import from desktop / files'
                                        : 'Import from photos / files',
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
