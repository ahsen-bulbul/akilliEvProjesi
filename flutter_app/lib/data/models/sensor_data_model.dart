import '../../domain/entities/sensor_data.dart';

class SensorDataModel extends SensorData {
  const SensorDataModel({
    required super.id,
    required super.sensorId,
    required super.deviceId,
    super.sensorName,
    super.sensorType,
    super.temperature,
    super.humidity,
    super.gasLevel,
    super.lightLevel,
    super.distanceCm,
    super.soilRaw,
    super.soilMoisture,
    super.motionDetected,
    super.buzzer,
    super.accelerometer,
    super.gyroscope,
    required super.createdAt,
  });

  static Map<String, double>? _vectorFromJson(dynamic value) {
    if (value is! Map) {
      return null;
    }
    return value.map(
      (key, item) => MapEntry(key.toString(), (item as num).toDouble()),
    );
  }

  factory SensorDataModel.fromJson(Map<String, dynamic> json) {
    final data = (json['data'] as Map?)?.cast<String, dynamic>() ?? json;
    final sensorName = json['sensor_name'] as String?;
    return SensorDataModel(
      id: json['id'],
      sensorId: json['sensor_id'] ?? 0,
      deviceId:
          data['device_id'] ?? sensorName ?? 'Sensor ${json['sensor_id']}',
      sensorName: sensorName,
      sensorType: json['sensor_type'] as String?,
      temperature: (data['temperature'] as num?)?.toDouble(),
      humidity: (data['humidity'] as num?)?.toDouble(),
      gasLevel: (data['gas_level'] as num?)?.toDouble(),
      lightLevel: (data['light_level'] as num?)?.toDouble(),
      distanceCm: (data['distance_cm'] as num?)?.toDouble(),
      soilRaw: (data['soil_raw'] as num?)?.toDouble(),
      soilMoisture: (data['soil_moisture'] as num?)?.toDouble(),
      motionDetected: data['motion_detected'] as bool?,
      buzzer: data['buzzer'] as bool?,
      accelerometer: _vectorFromJson(data['accelerometer']),
      gyroscope: _vectorFromJson(data['gyroscope']),
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  factory SensorDataModel.fromMqttJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return SensorDataModel(
      id: json['id'] is int ? json['id'] : now.millisecondsSinceEpoch,
      sensorId: json['sensor_id'] is int ? json['sensor_id'] : 0,
      deviceId: json['device_id'] ?? 'unknown',
      sensorName: json['sensor_name'] as String?,
      sensorType: json['sensor_type'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      gasLevel: (json['gas_level'] as num?)?.toDouble(),
      lightLevel: (json['light_level'] as num?)?.toDouble(),
      distanceCm: (json['distance_cm'] as num?)?.toDouble(),
      soilRaw: (json['soil_raw'] as num?)?.toDouble(),
      soilMoisture: (json['soil_moisture'] as num?)?.toDouble(),
      motionDetected: json['motion_detected'] as bool?,
      buzzer: json['buzzer'] as bool?,
      accelerometer: _vectorFromJson(json['accelerometer']),
      gyroscope: _vectorFromJson(json['gyroscope']),
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'])
          : now,
    );
  }
}
