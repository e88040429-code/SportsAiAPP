import 'package:flutter_test/flutter_test.dart';
import 'package:setpoint_ai/app.dart';

void main() {
  testWidgets('Home dashboard shows greeting, metrics, and sections', (tester) async {
    await tester.pumpWidget(const SetPointApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Good morning'), findsOneWidget);
    expect(find.text('Maya Chen'), findsOneWidget);
    expect(find.text('87%'), findsOneWidget);
    expect(find.text('Form'), findsOneWidget);
    expect(find.text("Today's Session"), findsOneWidget);
    expect(find.text('Drive • Toss • Contact'), findsOneWidget);
    expect(find.text('Common Skills'), findsOneWidget);
    expect(find.text('Continue Learning'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
  });

  testWidgets('Library shows search, toggle, chips, and drill sections', (tester) async {
    await tester.pumpWidget(const SetPointApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    expect(find.text('Pose Library'), findsOneWidget);
    expect(find.text('Search drills & poses'), findsOneWidget);
    expect(find.text('Training'), findsOneWidget);
    expect(find.text('Rehab'), findsWidgets);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Spike'), findsOneWidget);
    expect(find.text('Featured Drill'), findsOneWidget);
    expect(find.text('Core Skills'), findsOneWidget);
    expect(find.text('3-step approach'), findsWidgets);
  });

  testWidgets('Library drill tap opens drill detail', (tester) async {
    await tester.pumpWidget(const SetPointApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    final drillFinder = find.text('Arm swing timing');
    await tester.ensureVisible(drillFinder);
    await tester.pumpAndSettle();
    await tester.tap(drillFinder);
    await tester.pumpAndSettle();

    expect(find.text('Drill Detail'), findsOneWidget);
    expect(find.text('Arm swing timing'), findsWidgets);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Key Positions'), findsOneWidget);
    expect(find.text('Start Drill'), findsOneWidget);
  });

  testWidgets('Drill detail Start Drill navigates to Coach', (tester) async {
    await tester.pumpWidget(const SetPointApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    final drillFinder = find.text('Arm swing timing');
    await tester.ensureVisible(drillFinder);
    await tester.pumpAndSettle();
    await tester.tap(drillFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Drill'));
    await tester.pumpAndSettle();

    expect(find.text('Live Coach'), findsOneWidget);
  });
}
