import 'package:flutter_app/domain/entities/control_device.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ControlDevice Unit Tests', () {
    test('UT-05 copyWith sadece verilen status alanini degistirir', () {
      const device = ControlDevice(
        id: 1,
        roomId: 10,
        name: 'Salon Isigi',
        type: 'light',
        status: false,
      );

      final updated = device.copyWith(status: true);

      expect(updated.id, equals(device.id));
      expect(updated.roomId, equals(device.roomId));
      expect(updated.name, equals(device.name));
      expect(updated.type, equals(device.type));
      expect(updated.status, isTrue);
    });

    test('UT-06 copyWith status verilmezse mevcut degeri korur', () {
      const device = ControlDevice(
        id: 2,
        roomId: null,
        name: 'Kapi Kilidi',
        type: 'door',
        status: true,
      );

      final updated = device.copyWith();

      expect(updated.status, isTrue);
      expect(updated.roomId, isNull);
    });
  });
}
