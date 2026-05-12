import 'dart:math';

import '../models/sensor_data_model.dart';

class MockService {
  static final _rnd = Random();
  static int _idCounter = 1000;

  static double _rndBetween(double min, double max, {int decimals = 1}) {
    final val = min + _rnd.nextDouble() * (max - min);
    final factor = pow(10, decimals);
    return (val * factor).round() / factor;
  }

  static SensorDataModel generateReading() {
    return SensorDataModel(
      id: _idCounter++,
      sensorId: 1,
      deviceId: 'Ankara-RPi-01',
      sensorName: 'Living Room Sensor',
      sensorType: 'environment',
      temperature: _rndBetween(18, 36),
      humidity: _rndBetween(30, 85),
      gasLevel: _rndBetween(0, 120),
      lightLevel: _rndBetween(0, 1020, decimals: 0),
      distanceCm: _rndBetween(5, 200),
      createdAt: DateTime.now(),
    );
  }

  static List<SensorDataModel> generateHistory({int count = 20}) {
    return List.generate(count, (i) {
      return SensorDataModel(
        id: _idCounter++,
        sensorId: 1,
        deviceId: 'Ankara-RPi-01',
        sensorName: 'Living Room Sensor',
        sensorType: 'environment',
        temperature: _rndBetween(18, 36),
        humidity: _rndBetween(30, 85),
        gasLevel: _rndBetween(0, 120),
        lightLevel: _rndBetween(0, 1020, decimals: 0),
        distanceCm: _rndBetween(5, 200),
        createdAt: DateTime.now().subtract(Duration(seconds: (count - i) * 5)),
      );
    });
  }
}
