import 'package:flutter_app/data/models/sensor_data_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SensorDataModel Unit Tests', () {
    test(
      'UT-03 API JSON icindeki data alanini sensor degerlerine map eder',
      () {
        final model = SensorDataModel.fromJson({
          'id': 1,
          'sensor_id': 7,
          'sensor_name': 'Salon Sensoru',
          'sensor_type': 'temperature',
          'data': {
            'device_id': 'raspberry-pi',
            'temperature': 24.5,
            'humidity': 58,
            'gas_level': 120,
            'accelerometer': {'x': 1, 'y': 2.5, 'z': 0},
          },
          'created_at': '2026-05-17T12:00:00Z',
        });

        expect(model.id, equals(1));
        expect(model.sensorId, equals(7));
        expect(model.deviceId, equals('raspberry-pi'));
        expect(model.temperature, equals(24.5));
        expect(model.humidity, equals(58.0));
        expect(model.accelerometer, equals({'x': 1.0, 'y': 2.5, 'z': 0.0}));
      },
    );

    test('UT-04 cache map donusumu boolean ve tarih alanlarini korur', () {
      final createdAt = DateTime.utc(2026, 5, 17, 12);
      final model = SensorDataModel(
        id: 2,
        sensorId: 8,
        deviceId: 'device-8',
        sensorName: 'Hareket Sensoru',
        sensorType: 'motion',
        motionDetected: true,
        buzzer: false,
        gyroscope: const {'x': 0.1, 'y': 0.2},
        createdAt: createdAt,
      );

      final cacheMap = model.toCacheMap();
      final restored = SensorDataModel.fromCacheMap(cacheMap);

      expect(cacheMap['motion_detected'], equals(1));
      expect(cacheMap['buzzer'], equals(0));
      expect(restored.motionDetected, isTrue);
      expect(restored.buzzer, isFalse);
      expect(restored.gyroscope, equals({'x': 0.1, 'y': 0.2}));
      expect(restored.createdAt, equals(createdAt));
    });

    test('UT-07 bozuk MQTT sensor degerleri uygulamayi dusurmez', () {
      final model = SensorDataModel.fromMqttJson({
        'id': 'hatali-id',
        'sensor_id': 'hatali-sensor',
        'temperature': 'sicak',
        'humidity': null,
        'gas_level': {'ppm': 900},
        'accelerometer': {'x': 1, 'y': 'bozuk', 'z': 0},
      });

      expect(model.sensorId, equals(0));
      expect(model.deviceId, equals('unknown'));
      expect(model.temperature, isNull);
      expect(model.humidity, isNull);
      expect(model.gasLevel, isNull);
      expect(model.accelerometer, equals({'x': 1.0, 'z': 0.0}));
    });
  });
}
