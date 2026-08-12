import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpoint_ai/features/coach/pose/clip_pose_track.dart';
import 'package:setpoint_ai/features/coach/pose/pose_frame.dart';

PoseFrame _pose(double x) {
  return PoseFrame(
    joints: List<Offset>.generate(
      PoseFrame.jointCount,
      (i) => Offset(x, i / (PoseFrame.jointCount - 1)),
    ),
    imageSize: const Size(100, 200),
    confidence: List<double>.filled(PoseFrame.jointCount, 0.9),
    score: 0.8,
  );
}

void main() {
  group('sampleTimesForClip', () {
    test('returns empty for zero or negative duration', () {
      expect(sampleTimesForClip(duration: Duration.zero), isEmpty);
      expect(
        sampleTimesForClip(duration: const Duration(milliseconds: -1)),
        isEmpty,
      );
    });

    test('uses ~10 FPS (100ms) for a 1s clip', () {
      final times = sampleTimesForClip(
        duration: const Duration(seconds: 1),
        targetFps: 10,
        maxSamples: 180,
      );

      expect(times.first, Duration.zero);
      expect(times.length, 11);
      expect(times[1], const Duration(milliseconds: 100));
      expect(times.last, const Duration(milliseconds: 1000));
    });

    test('caps sample count and still spans the full duration', () {
      final times = sampleTimesForClip(
        duration: const Duration(seconds: 30),
        targetFps: 10,
        maxSamples: 180,
      );

      expect(times, hasLength(180));
      expect(times.first, Duration.zero);
      expect(times.last.inMilliseconds, 30 * 1000);
      expect(times, isA<List<Duration>>());
      for (var i = 1; i < times.length; i++) {
        expect(times[i] >= times[i - 1], isTrue);
      }
    });

    test('maxSamples of 1 returns only t=0', () {
      expect(
        sampleTimesForClip(
          duration: const Duration(seconds: 5),
          maxSamples: 1,
        ),
        [Duration.zero],
      );
    });

    test('short clip stays on the 80–120ms grid', () {
      final times = sampleTimesForClip(
        duration: const Duration(milliseconds: 250),
        targetFps: 10,
      );
      expect(times, [
        Duration.zero,
        const Duration(milliseconds: 100),
        const Duration(milliseconds: 200),
      ]);
    });
  });

  group('ClipPoseTrack.poseAt', () {
    test('empty track returns null', () {
      const track = ClipPoseTrack(samples: [], duration: Duration(seconds: 1));
      expect(track.poseAt(Duration.zero), isNull);
      expect(track.hasAnyPose, isFalse);
    });

    test('returns first sample when t is before the first timestamp', () {
      final first = _pose(0.2);
      final track = ClipPoseTrack(
        samples: [
          ClipPoseSample(
            time: const Duration(milliseconds: 200),
            pose: first,
          ),
          ClipPoseSample(
            time: const Duration(milliseconds: 400),
            pose: _pose(0.8),
          ),
        ],
        duration: const Duration(seconds: 1),
      );

      expect(track.poseAt(Duration.zero), same(first));
      expect(track.poseAt(const Duration(milliseconds: 50)), same(first));
    });

    test('returns last sample when t is after the last timestamp', () {
      final last = _pose(0.9);
      final track = ClipPoseTrack(
        samples: [
          ClipPoseSample(time: Duration.zero, pose: _pose(0.1)),
          ClipPoseSample(
            time: const Duration(milliseconds: 400),
            pose: last,
          ),
        ],
        duration: const Duration(seconds: 1),
      );

      expect(track.poseAt(const Duration(milliseconds: 400)), same(last));
      expect(track.poseAt(const Duration(seconds: 2)), same(last));
    });

    test('returns exact match', () {
      final mid = _pose(0.5);
      final track = ClipPoseTrack(
        samples: [
          ClipPoseSample(time: Duration.zero, pose: _pose(0.1)),
          ClipPoseSample(
            time: const Duration(milliseconds: 300),
            pose: mid,
          ),
          ClipPoseSample(
            time: const Duration(milliseconds: 600),
            pose: _pose(0.9),
          ),
        ],
        duration: const Duration(seconds: 1),
      );

      expect(track.poseAt(const Duration(milliseconds: 300)), same(mid));
    });

    test('picks the nearer sample between two timestamps', () {
      final early = _pose(0.2);
      final late = _pose(0.8);
      final track = ClipPoseTrack(
        samples: [
          ClipPoseSample(time: Duration.zero, pose: early),
          ClipPoseSample(
            time: const Duration(milliseconds: 100),
            pose: late,
          ),
        ],
        duration: const Duration(seconds: 1),
      );

      expect(track.poseAt(const Duration(milliseconds: 40)), same(early));
      expect(track.poseAt(const Duration(milliseconds: 60)), same(late));
    });

    test('midpoint tie prefers the earlier sample', () {
      final early = _pose(0.2);
      final late = _pose(0.8);
      final track = ClipPoseTrack(
        samples: [
          ClipPoseSample(time: Duration.zero, pose: early),
          ClipPoseSample(
            time: const Duration(milliseconds: 100),
            pose: late,
          ),
        ],
        duration: const Duration(seconds: 1),
      );

      expect(track.poseAt(const Duration(milliseconds: 50)), same(early));
    });

    test('returns null when the nearest sample has no person', () {
      final track = ClipPoseTrack(
        samples: [
          ClipPoseSample(time: Duration.zero, pose: _pose(0.2)),
          const ClipPoseSample(time: Duration(milliseconds: 100)),
          ClipPoseSample(
            time: const Duration(milliseconds: 200),
            pose: _pose(0.8),
          ),
        ],
        duration: const Duration(seconds: 1),
      );

      expect(track.poseAt(const Duration(milliseconds: 100)), isNull);
      expect(track.poseAt(const Duration(milliseconds: 110)), isNull);
      expect(track.hasAnyPose, isTrue);
    });
  });
}
