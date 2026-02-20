import 'package:flutter_test/flutter_test.dart';
import 'package:red_comrade_cards/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RedComradeCardsApp());
    expect(find.text('RED COMRADE'), findsOneWidget);
  });
}
