import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpoint_ai/core/sport/app_sport.dart';
import 'package:setpoint_ai/features/coach/pose/blazepose_to_coco.dart';
import 'package:setpoint_ai/features/coach/pose/live_session_recorder.dart';
import 'package:setpoint_ai/features/coach/pose/pose_frame.dart';

PoseFrame _pose({required double xShift, double confidence = 0.95}) {
  final joints = List<Offset>.generate(
    PoseFrame.jointCount,
    (i) => Offset(0.3 + xShift + i * 0.01, 0.2 + (i % 5) * 0.12),
  );
  return PoseFrame(
    joints: joints,
    imageSize: const Size(100, 200),
    confidence: List<double>.filled(PoseFrame.jointCount, confidence),
    score: 0.9,
  );
}

void main() {
  test('ignores frames when not recording', () {
    final recorder = LiveSessionRecorder(minFrames: 2);
    recorder.addFrame(_pose(xShift: 0));
    expect(recorder.frameCount, 0);
  });

  test('buffers distinct frames while recording', () {
    final recorder = LiveSessionRecorder(minFrames: 2);
    recorder.start();
    recorder.addFrame(_pose(xShift: 0.00));
    recorder.addFrame(_pose(xShift: 0.05));
    recorder.addFrame(_pose(xShift: 0.10));
    expect(recorder.frameCount, 3);
  });

  test('skips near-duplicate poses', () {
    final recorder = LiveSessionRecorder(minFrames: 2);
    recorder.start();
    recorder.addFrame(_pose(xShift: 0.00));
    recorder.addFrame(_pose(xShift: 0.0001));
    expect(recorder.frameCount, 1);
  });

  test('finish returns null when below minFrames', () {
    final recorder = LiveSessionRecorder(minFrames: 4);
    recorder.start();
    recorder.addFrame(_pose(xShift: 0.0));
    recorder.addFrame(_pose(xShift: 0.05));
    expect(recorder.finish(sport: AppSport.volleyball), isNull);
    expect(recorder.isRecording, isFalse);
  });

  test('finish publishes a ClipAnalysisResult from live poses', () {
    final recorder = LiveSessionRecorder(minFrames: 4);
    recorder.start();
    for (var i = 0; i < 6; i++) {
      recorder.addFrame(_pose(xShift: i * 0.04));
    }

    final result = recorder.finish(sport: AppSport.volleyball);
    expect(result, isNotNull);
    expect(result!.clipName, startsWith('Live session'));
    expect(result.sport, AppSport.volleyball);
    expect(result.overallScore, inInclusiveRange(55, 96));
    expect(result.athletePeakJoints, hasLength(PoseFrame.jointCount));
    expect(result.modelPeakJoints, hasLength(PoseFrame.jointCount));
    expect(result.phaseScores, isNotEmpty);
    expect(result.feedback, isNotEmpty);
  });

  test('skips low-visibility frames', () {
    final recorder = LiveSessionRecorder(minFrames: 2, minVisibleJoints: 8);
    recorder.start();
    recorder.addFrame(_pose(xShift: 0, confidence: 0.1));
    expect(recorder.frameCount, 0);
    // Confidence list with mixed visibility still counts visible joints.
    final joints = List<Offset>.generate(
      PoseFrame.jointCount,
      (i) => Offset(0.4, 0.2 + i * 0.04),
    );
    final conf = List<double>.generate(
      PoseFrame.jointCount,
      (i) => i < 10 ? 0.9 : BlazePoseToCoco.minVisibility - 0.1,
    );
    recorder.addFrame(
      PoseFrame(
        joints: joints,
        imageSize: const Size(100, 200),
        confidence: conf,
      ),
    );
    expect(recorder.frameCount, 1);
  });
}
