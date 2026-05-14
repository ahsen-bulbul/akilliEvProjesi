import '../models/sensor_data_model.dart';
import 'sensor_dao.dart';

class SensorLocalDataSource {
  SensorLocalDataSource({SensorDao? dao}) : _dao = dao ?? SensorDao();

  final SensorDao _dao;

  Future<void> cacheReading(SensorDataModel reading) {
    return _dao.upsertReading(reading);
  }

  Future<void> cacheReadings(List<SensorDataModel> readings) {
    return _dao.upsertReadings(readings);
  }

  Future<SensorDataModel?> getLatestReading({int? sensorId}) {
    return _dao.getLatestReading(sensorId: sensorId);
  }

  Future<List<SensorDataModel>> getHistory({int limit = 20}) {
    return _dao.getHistory(limit: limit);
  }
}
