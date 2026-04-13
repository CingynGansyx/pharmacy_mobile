import 'package:flutter_test/flutter_test.dart';

import 'package:pharmacy_demo/main.dart';

void main() {
  testWidgets('App builds login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PharmacyApp());
    await tester.pump();
    expect(find.text('Нэвтрэх'), findsWidgets);
  });
}
