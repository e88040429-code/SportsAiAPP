import 'package:flutter_test/flutter_test.dart';
import 'package:setpoint_ai/app.dart';

void main() {
  testWidgets('SetPoint AI shows home tab and bottom navigation', (tester) async {
    await tester.pumpWidget(const SetPointApp());
    await tester.pumpAndSettle();

    expect(find.text('SetPoint AI'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Coach'), findsOneWidget);
    expect(find.text('Recap'), findsOneWidget);
    expect(find.text('Rehab'), findsOneWidget);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();

    expect(find.text('Pose Library'), findsOneWidget);
  });
}
