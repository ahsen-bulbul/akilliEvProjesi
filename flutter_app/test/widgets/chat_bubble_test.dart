import 'package:flutter/material.dart';
import 'package:flutter_app/data/models/message.dart';
import 'package:flutter_app/presentation/widgets/chat_bubble.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatBubble Widget Tests', () {
    testWidgets('WT-01 kullanici mesaji sag tarafta ve metinle render edilir', (
      tester,
    ) async {
      final message = Message(
        id: '1',
        senderId: 'user-1',
        receiverId: 'admin-1',
        text: 'Merhaba',
        timestamp: DateTime(2026, 5, 17, 10, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubble(message: message, isOwnMessage: true),
          ),
        ),
      );

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, equals(Alignment.centerRight));
      expect(find.text('Merhaba'), findsOneWidget);
      expect(find.text('10:30'), findsOneWidget);
    });

    testWidgets('WT-02 admin mesaji sol tarafta render edilir', (tester) async {
      final message = Message(
        id: '2',
        senderId: 'admin-1',
        receiverId: 'user-1',
        text: 'Size nasil yardimci olabiliriz?',
        timestamp: DateTime(2026, 5, 17, 9, 5),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubble(message: message, isOwnMessage: false),
          ),
        ),
      );

      final align = tester.widget<Align>(find.byType(Align));
      expect(align.alignment, equals(Alignment.centerLeft));
      expect(find.text('Size nasil yardimci olabiliriz?'), findsOneWidget);
      expect(find.text('09:05'), findsOneWidget);
    });
  });
}
