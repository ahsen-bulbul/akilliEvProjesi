import '../entities/sensor_data.dart';

abstract class SensorRepository {
  Future<SensorData> getLatestReading({String deviceId = 'Ankara-RPi-01'});

  Future<List<SensorData>> getSensorHistory({int limit = 20});
}
