import '../../domain/entities/sensor_data.dart';

class SensorDataModel extends SensorData {
  const SensorDataModel({
    required super.id,
    required super.deviceId,
    super.temperature,
    super.humidity,
    super.gasLevel,
    super.lightLevel,
    super.distanceCm,
    required super.createdAt,
  });

  factory SensorDataModel.fromJson(Map<String, dynamic> json) {
    return SensorDataModel(
      id: json['id'],
      deviceId: json['device_id'],
      temperature: (json['temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      gasLevel: (json['gas_level'] as num?)?.toDouble(),
      lightLevel: (json['light_level'] as num?)?.toDouble(),
      distanceCm: (json['distance_cm'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
