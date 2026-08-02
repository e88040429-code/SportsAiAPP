import 'package:flutter/material.dart';

import '../../../core/sport/app_sport.dart';
import '../data/clip_analysis_session.dart';
import '../data/clip_form_analyzer.dart';
import '../data/model_pose_library.dart';
import 'blazepose_to_coco.dart';
import 'pose_frame.dart';

/// Buffers live [PoseFrame] joints while the athlete is recording, then builds
/// a [ClipAnalysisResult] for Session Recap via [ClipFormAnalyzer].
class LiveSessionRecorder {
  LiveSessionRecorder({
    this.minFrames = 4,
    this.maxFrames = 180,
    this.minVisibleJoints = 8,
  });

  /// Minimum poses required to produce a Recap (else recording is discarded).
  final int minFrames;

  /// Cap so a long hold doesn't grow without bound.
  final int maxFrames;

  /// Skip frames that don't have enough confident joints.
  final int minVisibleJoints;

  bool _recording = false;
  final List<List<Offset>> _frames = [];
  DateTime? _startedAt;

  bool get isRecording => _recording;
  int get frameCount => _frames.length;
  DateTime? get startedAt => _startedAt;

  /// Clears prior frames and starts a new session.
  void start() {
    _recording = true;
    _frames.clear();
    _startedAt = DateTime.now();
  }

  /// Appends a pose snapshot when recording (throttled by caller / busy gate).
  void addFrame(PoseFrame? frame) {
    if (!_recording || frame == null) return;
    if (_frames.length >= maxFrames) return;

    var visible = 0;
    final conf = frame.confidence;
    for (var i = 0; i < PoseFrame.jointCount; i++) {
      final ok = conf == null ||
          conf.length != PoseFrame.jointCount ||
          conf[i] >= BlazePoseToCoco.minVisibility;
      if (ok) visible++;
    }
    if (visible < minVisibleJoints) return;

    // Drop near-duplicates (same pose held still).
    if (_frames.isNotEmpty) {
      final prev = _frames.last;
      var drift = 0.0;
      for (var i = 0; i < PoseFrame.jointCount; i++) {
        drift += (frame.joints[i] - prev[i]).distance;
      }
      if (drift / PoseFrame.jointCount < 0.004) return;
    }

    _frames.add(List<Offset>.from(frame.joints));
  }

  /// Ends recording and returns analysis, or `null` if too few frames.
  ClipAnalysisResult? finish({
    required AppSport sport,
    SkillModelKind kind = SkillModelKind.hitting,
  }) {
    _recording = false;
    final captured = List<List<Offset>>.from(_frames);
    final started = _startedAt;
    _frames.clear();
    _startedAt = null;

    if (captured.length < minFrames) return null;

    final model = ModelPoseLibrary.modelSequence(sport, kind);
    final stamp = started ?? DateTime.now();
    final label =
        'Live session · ${stamp.hour.toString().padLeft(2, '0')}:${stamp.minute.toString().padLeft(2, '0')}';

    return ClipFormAnalyzer.analyze(
      clipName: label,
      sport: sport,
      kind: kind,
      athleteSeq: captured,
      modelSeq: model,
    );
  }

  void cancel() {
    _recording = false;
    _frames.clear();
    _startedAt = null;
  }
}
