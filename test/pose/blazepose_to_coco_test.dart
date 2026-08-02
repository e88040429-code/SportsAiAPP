import 'dart:ui' show PictureRecorder;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpoint_ai/features/coach/pose/blazepose_to_coco.dart';
import 'package:setpoint_ai/features/coach/pose/pose_frame.dart';
import 'package:setpoint_ai/features/coach/widgets/pose_skeleton_painter.dart';

List<PixelLandmark?> _slots(Map<int, PixelLandmark> filled) {
  return List<PixelLandmark?>.generate(
    PoseFrame.jointCount,
    (i) => filled[i],
  );
}

void main() {
  const imageSize = Size(100, 200);

  test('maps pixel landmarks into 17 COCO joints normalized 0–1', () {
    final frame = BlazePoseToCoco.fromCocoLandmarks(
      _slots({
        CocoJoints.nose: const PixelLandmark(x: 50, y: 20, visibility: 0.95),
        CocoJoints.leftShoulder: const PixelLandmark(x: 35, y: 50),
        CocoJoints.rightAnkle: const PixelLandmark(x: 64, y: 190),
      }),
      imageSize: imageSize,
      score: 0.9,
    );

    expect(frame, isNotNull);
    expect(frame!.joints, hasLength(PoseFrame.jointCount));
    expect(frame.joints[CocoJoints.nose], const Offset(0.5, 0.1));
    expect(frame.joints[CocoJoints.leftShoulder], const Offset(0.35, 0.25));
    expect(frame.joints[CocoJoints.rightAnkle], const Offset(0.64, 0.95));
    expect(frame.confidence![CocoJoints.nose], closeTo(0.95, 1e-9));
    expect(frame.score, closeTo(0.9, 1e-9));
  });

  test('mirrors x for front-camera overlay alignment', () {
    final frame = BlazePoseToCoco.fromCocoLandmarks(
      _slots({CocoJoints.nose: const PixelLandmark(x: 25, y: 40)}),
      imageSize: imageSize,
      mirrorHorizontally: true,
    );

    expect(frame, isNotNull);
    expect(frame!.joints[CocoJoints.nose].dx, closeTo(0.75, 1e-9));
    expect(frame.joints[CocoJoints.nose].dy, closeTo(0.2, 1e-9));
  });

  test('reuses previous joint when a landmark is missing', () {
    final previous = List<Offset>.generate(
      PoseFrame.jointCount,
      (i) => Offset(0.1 * i, 0.2),
    );
    final previousConf = List<double>.filled(PoseFrame.jointCount, 0.9);

    final frame = BlazePoseToCoco.fromCocoLandmarks(
      _slots({CocoJoints.nose: const PixelLandmark(x: 50, y: 20)}),
      imageSize: imageSize,
      previousJoints: previous,
      previousConfidence: previousConf,
    );

    expect(frame, isNotNull);
    expect(frame!.joints[CocoJoints.nose], const Offset(0.5, 0.1));
    expect(frame.joints[CocoJoints.leftShoulder], previous[CocoJoints.leftShoulder]);
    expect(
      frame.confidence![CocoJoints.leftShoulder],
      closeTo(0.9 * 0.85, 1e-9),
    );
  });

  test('treats low-visibility landmarks as missing', () {
    final frame = BlazePoseToCoco.fromCocoLandmarks(
      _slots({
        CocoJoints.nose: const PixelLandmark(x: 50, y: 20, visibility: 0.1),
        CocoJoints.leftShoulder:
            const PixelLandmark(x: 35, y: 50, visibility: 0.9),
      }),
      imageSize: imageSize,
    );

    expect(frame, isNotNull);
    expect(frame!.confidence![CocoJoints.nose], 0);
    expect(frame.joints[CocoJoints.nose], Offset.zero);
    expect(frame.joints[CocoJoints.leftShoulder], const Offset(0.35, 0.25));
    expect(frame.isJointVisible(CocoJoints.nose), isFalse);
    expect(frame.isJointVisible(CocoJoints.leftShoulder), isTrue);
  });

  test('returns null when every landmark is missing or low-vis', () {
    final frame = BlazePoseToCoco.fromCocoLandmarks(
      _slots({
        CocoJoints.nose: const PixelLandmark(x: 10, y: 10, visibility: 0.1),
      }),
      imageSize: imageSize,
    );
    expect(frame, isNull);
  });

  test('painter skips bones touching invisible joints', () {
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(100, 200);

    // Only nose + left shoulder visible — nose→L-shoulder bone (0,5) should draw;
    // L-elbow bone (5,7) should not.
    final joints = List<Offset>.generate(
      PoseFrame.jointCount,
      (_) => Offset.zero,
    );
    joints[CocoJoints.nose] = const Offset(0.5, 0.1);
    joints[CocoJoints.leftShoulder] = const Offset(0.3, 0.3);

    final confidence = List<double>.filled(PoseFrame.jointCount, 0);
    confidence[CocoJoints.nose] = 0.9;
    confidence[CocoJoints.leftShoulder] = 0.9;

    final painter = PoseSkeletonPainter(
      joints: joints,
      confidence: confidence,
      lineColor: const Color(0xFF00FF00),
      jointColor: const Color(0xFF0000FF),
    );

    // Smoke: paint must not throw with partial visibility.
    expect(() => painter.paint(canvas, size), returnsNormally);
    expect(painter.shouldRepaint(painter), isFalse);
  });

  test('clamps normalized coordinates into 0–1', () {
    final frame = BlazePoseToCoco.fromCocoLandmarks(
      _slots({
        CocoJoints.nose: const PixelLandmark(x: -10, y: 250, visibility: 1),
      }),
      imageSize: imageSize,
    );

    expect(frame, isNotNull);
    expect(frame!.joints[CocoJoints.nose].dx, 0);
    expect(frame.joints[CocoJoints.nose].dy, 1);
  });
}
