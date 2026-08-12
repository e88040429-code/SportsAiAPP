import 'package:flutter_test/flutter_test.dart';
import 'package:setpoint_ai/features/coach/data/clip_pose_extractor.dart';

void main() {
  test('VM / native extractor is unsupported (Chrome overlay only)', () async {
    expect(isClipPoseOverlaySupported, isFalse);

    final result = await extractClipPoseTrack(
      videoUrl: 'blob:test',
      duration: const Duration(seconds: 2),
      detect: (_, _) async => null,
      isCancelled: () => false,
    );

    expect(result.cancelled, isFalse);
    expect(result.track, isNull);
    expect(result.message, contains('Chrome'));
  });
}