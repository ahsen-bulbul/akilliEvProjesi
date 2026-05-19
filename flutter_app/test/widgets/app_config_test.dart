import 'package:flutter_app/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SmartHomeApp Widget Tests', () {
    testWidgets('WT-07 Supabase ayarlari yoksa config mesaji gosterir', (
      tester,
    ) async {
      await tester.pumpWidget(const SmartHomeApp());

      expect(find.textContaining('Supabase ayarlari eksik'), findsOneWidget);
    });
  });
}
