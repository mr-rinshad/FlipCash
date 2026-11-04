import 'package:flutter_test/flutter_test.dart';
import 'package:flipcash/main.dart';

void main() {
  testWidgets('FlipCashApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FlipCashApp());
    expect(find.byType(FlipCashApp), findsOneWidget);
  });
}
