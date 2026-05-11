import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/main.dart';

void main() {
  testWidgets('renders main navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const SmartHomeApp());

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Sensors'), findsOneWidget);
    expect(find.text('Control'), findsOneWidget);
    expect(find.text('Stats'), findsOneWidget);
  });
}
