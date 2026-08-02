import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpoint_ai/core/sport/app_sport.dart';
import 'package:setpoint_ai/features/coach/pose/blazepose_to_coco.dart';
import 'package:setpoint_ai/features/coach/pose/live_pose_coach.dart';
import 'package:setpoint_ai/features/coach/pose/pose_frame.dart';

PoseFrame _frame(List<Offset> joints, {List<double>? confidence}) {
  assert(joints.length == PoseFrame.jointCount);
  return PoseFrame(
    joints: joints,
    imageSize: const Size(100, 200),
    confidence: confidence ?? List<double>.filled(PoseFrame.jointCount, 0.95),
    score: 0.9,
  );
}

/// Neutral standing pose, roughly symmetric.
PoseFrame _standing({double hipLean = 0}) {
  final joints = List<Offset>.generate(PoseFrame.jointCount, (_) => Offset.zero);
  joints[CocoJoints.nose] = const Offset(0.50, 0.12);
  joints[CocoJoints.leftEye] = const Offset(0.46, 0.10);
  joints[CocoJoints.rightEye] = const Offset(0.54, 0.10);
  joints[CocoJoints.leftEar] = const Offset(0.42, 0.12);
  joints[CocoJoints.rightEar] = const Offset(0.58, 0.12);
  joints[CocoJoints.leftShoulder] = Offset(0.38 + hipLean, 0.28);
  joints[CocoJoints.rightShoulder] = Offset(0.62 + hipLean, 0.28);
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
  return _frame(joints);
}

void main() {
  test('idle insights when no pose is present', () {
    final coach = LivePoseCoach();
    final insights = coach.analyze(null, AppSport.volleyball);

    expect(insights.hasPose, isFalse);
    expect(insights.cue, contains('Stand in frame'));
    expect(insights.metrics, hasLength(3));
    expect(insights.metrics.every((m) => m.value == '—'), isTrue);
  });

  test('volleyball metrics update from a standing pose', () {
    final coach = LivePoseCoach();
    final insights = coach.analyze(_standing(), AppSport.volleyball);

    expect(insights.hasPose, isTrue);
    expect(insights.metrics.map((m) => m.label), ['Balance', 'Symmetry', 'Timing']);
    for (final m in insights.metrics) {
      expect(m.value.endsWith('%'), isTrue);
      final n = int.parse(m.value.replaceAll('%', ''));
      expect(n, inInclusiveRange(40, 98));
    }
    expect(insights.cue, isNotEmpty);
  });

  test('leaning torso lowers balance and can change the cue', () {
    final coach = LivePoseCoach();
    final balanced = coach.analyze(_standing(), AppSport.volleyball);
    coach.reset();
    final leaning = coach.analyze(_standing(hipLean: 0.12), AppSport.volleyball);

    final balA = int.parse(balanced.metrics.first.value.replaceAll('%', ''));
    final balB = int.parse(leaning.metrics.first.value.replaceAll('%', ''));
    expect(balB, lessThan(balA));
  });

  test('soccer metrics use Plant / Contact / Follow labels', () {
    final coach = LivePoseCoach();
    final insights = coach.analyze(_standing(), AppSport.soccer);

    expect(insights.metrics.map((m) => m.label), ['Plant', 'Contact', 'Follow']);
    expect(insights.hasPose, isTrue);
  });

  test('low elbow triggers a follow-through cue', () {
    final coach = LivePoseCoach();
    final joints = List<Offset>.from(_standing().joints);
    // Drop right elbow well below shoulder (higher dy).
    joints[CocoJoints.rightElbow] = const Offset(0.72, 0.48);
    joints[CocoJoints.rightShoulder] = const Offset(0.62, 0.28);
    final insights = coach.analyze(_frame(joints), AppSport.volleyball);

    expect(insights.cue.toLowerCase(), contains('elbow'));
  });
}
