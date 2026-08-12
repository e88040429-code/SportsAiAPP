import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:setpoint_ai/core/sport/app_sport.dart';
import 'package:setpoint_ai/features/coach/pose/pose_frame.dart';
import 'package:setpoint_ai/features/coach/widgets/clip_pose_overlay_chrome.dart';

PoseFrame _standing() {
  return PoseFrame(
    joints: List<Offset>.generate(
      PoseFrame.jointCount,
      (i) => Offset(0.5, i / (PoseFrame.jointCount - 1)),
    ),
    imageSize: const Size(100, 200),
    confidence: List<double>.filled(PoseFrame.jointCount, 0.95),
    score: 0.9,
  );
}

Future<void> _pumpOverlay(
  WidgetTester tester, {
  PoseFrame? pose,
  double? progress,
  String? note,
  bool showSkeleton = true,
  VoidCallback? onToggleSkeleton,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 320,
          height: 180,
          child: ClipPoseOverlayChrome(
            sport: AppSport.volleyball,
            pose: pose,
            progress: progress,
            note: note,
            showSkeleton: showSkeleton,
            onToggleSkeleton: onToggleSkeleton,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('paints skeleton when a pose is present', (tester) async {
    await _pumpOverlay(tester, pose: _standing());
    expect(find.byKey(const Key('clip-pose-skeleton')), findsOneWidget);
  });

  testWidgets('hides skeleton when track pose is null', (tester) async {
    await _pumpOverlay(tester);
    expect(find.byKey(const Key('clip-pose-skeleton')), findsNothing);
  });

  testWidgets('toggle hides the skeleton painter', (tester) async {
    var show = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SizedBox(
                width: 320,
                height: 180,
                child: ClipPoseOverlayChrome(
                  sport: AppSport.volleyball,
                  pose: _standing(),
                  showSkeleton: show,
                  onToggleSkeleton: () => setState(() => show = !show),
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('clip-pose-skeleton')), findsOneWidget);
    await tester.tap(find.byTooltip('Hide skeleton'));
    await tester.pump();
    expect(find.byKey(const Key('clip-pose-skeleton')), findsNothing);
    expect(find.byTooltip('Show skeleton'), findsOneWidget);
  });

  testWidgets('shows reading-poses progress chip', (tester) async {
    await _pumpOverlay(tester, progress: 0.4);
    expect(find.text('Reading poses… 40%'), findsOneWidget);
    expect(find.byKey(const Key('clip-pose-skeleton')), findsNothing);
  });

  testWidgets('shows overlay note when extraction is unavailable', (tester) async {
    await _pumpOverlay(
      tester,
      note: 'Pose overlay is available in Chrome for now.',
    );
    expect(
      find.text('Pose overlay is available in Chrome for now.'),
      findsOneWidget,
    );
  });
}
