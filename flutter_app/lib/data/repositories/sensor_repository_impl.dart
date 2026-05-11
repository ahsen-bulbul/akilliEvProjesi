import '../../domain/entities/sensor_data.dart';
import '../../domain/repositories/sensor_repository.dart';
import '../datasources/api_service.dart';

class SensorRepositoryImpl implements SensorRepository {
  @override
  Future<SensorData> getLatestReading({String deviceId = 'Ankara-RPi-01'}) {
    return ApiService.getLatestReading(deviceId: deviceId);
  }

  @override
  Future<List<SensorData>> getSensorHistory({int limit = 20}) {
    return ApiService.getSensorHistory(limit: limit);
  }
}
