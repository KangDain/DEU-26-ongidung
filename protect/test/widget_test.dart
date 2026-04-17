import 'package:flutter_test/flutter_test.dart';
import 'package:protect/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProtectApp());
    expect(find.text('PROTECT'), findsOneWidget);
  });
}
