import 'package:flutter_app/data/models/message.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Message Model Unit Tests', () {
    test('UT-01 JSON verisini Message nesnesine donusturur', () {
      final message = Message.fromJson({
        'id': 12,
        'sender_id': 'user-1',
        'receiver_id': 'admin-1',
        'text': 'Merhaba admin',
        'created_at': '2026-05-17T10:15:00Z',
      });

      expect(message.id, equals('12'));
      expect(message.senderId, equals('user-1'));
      expect(message.receiverId, equals('admin-1'));
      expect(message.text, equals('Merhaba admin'));
      expect(message.timestamp, isA<DateTime>());
    });

    test('UT-02 receiver_id null geldiginde bos metin kullanir', () {
      final message = Message.fromJson({
        'id': 13,
        'sender_id': 'user-1',
        'receiver_id': null,
        'text': 'Admin henuz atanmamis',
        'created_at': '2026-05-17T10:20:00Z',
      });

      expect(message.receiverId, isEmpty);
    });
  });
}
