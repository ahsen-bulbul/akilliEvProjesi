import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/main.dart';

void main() {
  testWidgets('shows config message without Supabase dart-defines', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SmartHomeApp());

    expect(find.textContaining('Supabase ayarlari eksik'), findsOneWidget);
  });
}
