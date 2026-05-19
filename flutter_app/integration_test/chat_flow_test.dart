import 'package:flutter/material.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/presentation/widgets/message_input_field.dart';
import 'package:flutter_app/presentation/widgets/sensor_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Smart Home Integration Tests', () {
    testWidgets('IT-01 mesaj yazma akisinda input metni kabul edilir', (
      tester,
    ) async {
      final controller = TextEditingController();
      var sentText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageInputField(
              controller: controller,
              onSend: () => sentText = controller.text,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Admin destek mesaji');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(sentText, equals('Admin destek mesaji'));
    });

    testWidgets('IT-02 sensor alarm akisi uyari ikonunu gosterir', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SensorCard(
              label: 'Gaz Seviyesi',
              value: '950',
              unit: 'ppm',
              icon: Icons.local_fire_department,
              color: Colors.red,
              isAlert: true,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Gaz Seviyesi'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('IT-03 mesaj gonderme sirasinda yuklenme durumu gorunur', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Bekleyen mesaj');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageInputField(
              controller: controller,
              sending: true,
              onSend: () {},
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });

    testWidgets('IT-04 uygulama config eksiginde uyari ekrani acar', (
      tester,
    ) async {
      await tester.pumpWidget(const SmartHomeApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('Supabase ayarlari eksik'), findsOneWidget);
    });
  });
}
