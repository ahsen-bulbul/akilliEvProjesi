import 'package:flutter/material.dart';
import 'package:flutter_app/presentation/widgets/message_input_field.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MessageInputField Widget Tests', () {
    testWidgets(
      'WT-03 metin girilip gonder butonuna basilinca callback calisir',
      (tester) async {
        final controller = TextEditingController();
        var sendCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageInputField(
                controller: controller,
                onSend: () => sendCount++,
              ),
            ),
          ),
        );

        await tester.enterText(find.byType(TextField), 'Test mesaji');
        await tester.tap(find.byIcon(Icons.send_rounded));
        await tester.pump();

        expect(controller.text, equals('Test mesaji'));
        expect(sendCount, equals(1));
      },
    );

    testWidgets('WT-04 sending durumunda input ve gonder butonu pasif olur', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Bekleyen mesaj');
      var sendCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageInputField(
              controller: controller,
              sending: true,
              onSend: () => sendCount++,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(sendCount, equals(0));
    });

    testWidgets('WT-08 bos mesaj gonderilirse callback calismaz', (
      tester,
    ) async {
      final controller = TextEditingController(text: '   ');
      var sendCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageInputField(
              controller: controller,
              onSend: () => sendCount++,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(sendCount, equals(0));
    });
  });
}
