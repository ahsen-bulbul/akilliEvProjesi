import '../entities/sensor_data.dart';

abstract class SensorRepository {
  Stream<SensorData> get liveReadings;

  Future<void> connectLiveReadings();

  Future<void> disconnectLiveReadings();

  Future<SensorData> getLatestReading({int? sensorId});

  Future<List<SensorData>> getSensorHistory({int limit = 20});

  Future<void> cacheReading(SensorData reading);

  Future<SensorData?> getCachedLatestReading({int? sensorId});

  void dispose();
}
