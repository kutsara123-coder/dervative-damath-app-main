import 'package:flutter_test/flutter_test.dart';

import 'package:derivative_damath/main.dart';

void main() {
  testWidgets('shows the main menu', (WidgetTester tester) async {
    await tester.pumpWidget(const DerivativeDamathApp());
    await tester.pumpAndSettle();

    expect(find.text('Player vs Computer'), findsOneWidget);
    expect(find.text('Player vs Dexter'), findsOneWidget);
    expect(find.text('Player vs Player'), findsOneWidget);
    expect(find.text('How to Play'), findsOneWidget);
    expect(find.text('Credits'), findsOneWidget);
  });
}
