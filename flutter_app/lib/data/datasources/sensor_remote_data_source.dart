import '../../domain/entities/sensor_data.dart';
import 'api_service.dart';
import 'mqtt_sensor_service.dart';

class SensorRemoteDataSource {
  SensorRemoteDataSource({MqttSensorService? mqttService})
    : _mqttService = mqttService ?? MqttSensorService();

  final MqttSensorService _mqttService;

  Stream<SensorData> get liveReadings => _mqttService.readings;

  Future<void> connectLiveReadings() {
    return _mqttService.connect();
  }

  Future<void> disconnectLiveReadings() {
    return _mqttService.disconnect();
  }

  Future<SensorData> getLatestReading({int? sensorId}) {
    return ApiService.getLatestReading(sensorId: sensorId);
  }

  Future<List<SensorData>> getSensorHistory({int limit = 20}) {
    return ApiService.getSensorHistory(limit: limit);
  }

  void dispose() {
    _mqttService.dispose();
  }
}
