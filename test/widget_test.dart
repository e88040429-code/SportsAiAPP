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

  testWidgets('Bottom navigation switches to Library', (tester) async {
    await tester.pumpWidget(const SetPointApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    expect(find.text('Pose Library'), findsOneWidget);
  });
}
