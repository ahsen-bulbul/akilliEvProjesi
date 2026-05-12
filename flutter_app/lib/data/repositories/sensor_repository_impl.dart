import '../../domain/entities/sensor_data.dart';
import '../../domain/repositories/sensor_repository.dart';
import '../datasources/api_service.dart';

class SensorRepositoryImpl implements SensorRepository {
  @override
  Future<SensorData> getLatestReading({int? sensorId}) {
    return ApiService.getLatestReading(sensorId: sensorId);
  }

  @override
  Future<List<SensorData>> getSensorHistory({int limit = 20}) {
    return ApiService.getSensorHistory(limit: limit);
  }
}
