import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpoint_ai/core/sport/app_sport.dart';
import 'package:setpoint_ai/features/coach/data/clip_form_analyzer.dart';
import 'package:setpoint_ai/features/coach/data/model_pose_library.dart';
import 'package:setpoint_ai/features/coach/pose/blazepose_to_coco.dart';
import 'package:setpoint_ai/features/coach/pose/pose_frame.dart';

PoseFrame _standing() {
  final joints = List<Offset>.generate(PoseFrame.jointCount, (_) => Offset.zero);
  joints[CocoJoints.nose] = const Offset(0.50, 0.12);
  joints[CocoJoints.leftEye] = const Offset(0.46, 0.10);
  joints[CocoJoints.rightEye] = const Offset(0.54, 0.10);
  joints[CocoJoints.leftEar] = const Offset(0.42, 0.12);
  joints[CocoJoints.rightEar] = const Offset(0.58, 0.12);
  joints[CocoJoints.leftShoulder] = const Offset(0.38, 0.28);
  joints[CocoJoints.rightShoulder] = const Offset(0.62, 0.28);
  joints[CocoJoints.leftElbow] = const Offset(0.32, 0.42);
  joints[CocoJoints.rightElbow] = const Offset(0.68, 0.42);
  joints[CocoJoints.leftWrist] = const Offset(0.30, 0.55);
  joints[CocoJoints.rightWrist] = const Offset(0.70, 0.55);
  joints[CocoJoints.leftHip] = const Offset(0.42, 0.52);
  joints[CocoJoints.rightHip] = const Offset(0.58, 0.52);
  joints[CocoJoints.leftKnee] = const Offset(0.42, 0.72);
  joints[CocoJoints.rightKnee] = const Offset(0.58, 0.72);
  joints[CocoJoints.leftAnkle] = const Offset(0.42, 0.92);
  joints[CocoJoints.rightAnkle] = const Offset(0.58, 0.92);
  return PoseFrame(
    joints: joints,
    imageSize: const Size(100, 200),
    confidence: List<double>.filled(PoseFrame.jointCount, 0.95),
    score: 0.9,
  );
}

void main() {
  test('still analysis reports balance and symmetry without timing phases', () {
    final result = ClipFormAnalyzer.analyzeStill(
      clipName: 'stance.png',
      sport: AppSport.volleyball,
      kind: SkillModelKind.hitting,
      frame: _standing(),
    );

    expect(result.isStillImage, isTrue);
    expect(result.phaseScores.map((s) => s.label), ['Balance', 'Symmetry']);
    expect(result.motionDescription.toLowerCase(), contains('still'));
    expect(result.motionDescription.toLowerCase(), isNot(contains('load phase')));
    expect(result.feedback.join(' ').toLowerCase(), contains('timing doesn’t apply'));
  });
}
