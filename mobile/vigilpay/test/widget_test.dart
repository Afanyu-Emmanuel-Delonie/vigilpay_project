import 'package:flutter_test/flutter_test.dart';

import 'package:vigilpay/main.dart';

void main() {
  testWidgets('App renders login page', (WidgetTester tester) async {
    await tester.pumpWidget(const VigilPayApp());

    expect(find.text('Login'), findsOneWidget);
  });
}
