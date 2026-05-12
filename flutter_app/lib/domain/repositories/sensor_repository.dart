import '../entities/sensor_data.dart';

abstract class SensorRepository {
  Future<SensorData> getLatestReading({int? sensorId});

  Future<List<SensorData>> getSensorHistory({int limit = 20});
}
