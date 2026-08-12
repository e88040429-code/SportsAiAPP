import 'package:flutter_test/flutter_test.dart';
import 'package:setpoint_ai/app.dart';
import 'package:setpoint_ai/core/router/app_router.dart';
import 'package:setpoint_ai/core/sport/app_sport.dart';

Future<void> _pumpFreshApp(WidgetTester tester) async {
  appSportController.debugReset();
  await tester.pumpWidget(const SetPointApp());
  appRouter.go('/sports');
  await tester.pumpAndSettle();
}

Future<void> _enterAppAsVolleyball(WidgetTester tester) async {
  await _pumpFreshApp(tester);

  expect(find.textContaining('Welcome, Emma'), findsOneWidget);

  await tester.tap(find.text('Volleyball'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    appSportController.debugReset();
    appRouter.go('/sports');
  });

  testWidgets('Welcome screen asks Emma to pick a sport', (tester) async {
    await _pumpFreshApp(tester);

    expect(find.textContaining('Welcome, Emma'), findsOneWidget);
    expect(
      find.text('What sport would you like to practice today?'),
      findsOneWidget,
    );
    expect(find.text('Volleyball'), findsOneWidget);
    expect(find.text('Soccer'), findsOneWidget);
  });

  testWidgets('Deep link to Coach without sport redirects to welcome',
      (tester) async {
    await tester.pumpWidget(const SetPointApp());
    await tester.pumpAndSettle();

    appRouter.go('/coach');
    await tester.pumpAndSettle();

    expect(find.textContaining('Welcome, Emma'), findsOneWidget);
    expect(find.textContaining('Live Coach'), findsNothing);
  });

  testWidgets('Deep link to Coach resumes after sport pick', (tester) async {
    await tester.pumpWidget(const SetPointApp());
    await tester.pumpAndSettle();

    appRouter.go('/coach');
    await tester.pumpAndSettle();
    expect(find.textContaining('Welcome, Emma'), findsOneWidget);

    await tester.tap(find.text('Volleyball'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Live Coach'), findsOneWidget);
  });

  testWidgets('Picking a sport opens the Home dashboard', (tester) async {
    await _enterAppAsVolleyball(tester);

    expect(find.textContaining('Good morning'), findsOneWidget);
    expect(find.text('Emma'), findsOneWidget);
    expect(find.text('87%'), findsOneWidget);
    expect(find.text('Form'), findsOneWidget);
    expect(find.text("Today's Session"), findsOneWidget);
    expect(find.text('Drive • Toss • Contact'), findsOneWidget);
    expect(find.text('Common Skills'), findsOneWidget);
    expect(find.text('Continue Learning'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
  });

  testWidgets('Library shows search, toggle, chips, and drill sections', (tester) async {
    await _enterAppAsVolleyball(tester);

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
    await _enterAppAsVolleyball(tester);

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
    await _enterAppAsVolleyball(tester);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    final drillFinder = find.text('Arm swing timing');
    await tester.ensureVisible(drillFinder);
    await tester.pumpAndSettle();
    await tester.tap(drillFinder);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Start Drill'));
    // Coach keeps a loading spinner / camera bootstrap running — don't settle forever.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Live Coach'), findsOneWidget);
  });
}
