import 'dart:convert';

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

  static double? _doubleFromJson(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    return null;
  }

  static Map<String, double>? _vectorFromJson(dynamic value) {
    if (value is! Map) {
      return null;
    }
    final vector = <String, double>{};
    for (final entry in value.entries) {
      final item = entry.value;
      if (item is num) {
        vector[entry.key.toString()] = item.toDouble();
      }
    }
    return vector;
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
      temperature: _doubleFromJson(data['temperature']),
      humidity: _doubleFromJson(data['humidity']),
      gasLevel: _doubleFromJson(data['gas_level']),
      lightLevel: _doubleFromJson(data['light_level']),
      distanceCm: _doubleFromJson(data['distance_cm']),
      soilRaw: _doubleFromJson(data['soil_raw']),
      soilMoisture: _doubleFromJson(data['soil_moisture']),
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
      temperature: _doubleFromJson(json['temperature']),
      humidity: _doubleFromJson(json['humidity']),
      gasLevel: _doubleFromJson(json['gas_level']),
      lightLevel: _doubleFromJson(json['light_level']),
      distanceCm: _doubleFromJson(json['distance_cm']),
      soilRaw: _doubleFromJson(json['soil_raw']),
      soilMoisture: _doubleFromJson(json['soil_moisture']),
      motionDetected: json['motion_detected'] as bool?,
      buzzer: json['buzzer'] as bool?,
      accelerometer: _vectorFromJson(json['accelerometer']),
      gyroscope: _vectorFromJson(json['gyroscope']),
      createdAt: json['created_at'] is String
          ? DateTime.parse(json['created_at'])
          : now,
    );
  }

  factory SensorDataModel.fromEntity(SensorData data) {
    if (data is SensorDataModel) {
      return data;
    }
    return SensorDataModel(
      id: data.id,
      sensorId: data.sensorId,
      deviceId: data.deviceId,
      sensorName: data.sensorName,
      sensorType: data.sensorType,
      temperature: data.temperature,
      humidity: data.humidity,
      gasLevel: data.gasLevel,
      lightLevel: data.lightLevel,
      distanceCm: data.distanceCm,
      soilRaw: data.soilRaw,
      soilMoisture: data.soilMoisture,
      motionDetected: data.motionDetected,
      buzzer: data.buzzer,
      accelerometer: data.accelerometer,
      gyroscope: data.gyroscope,
      createdAt: data.createdAt,
    );
  }

  factory SensorDataModel.fromCacheMap(Map<String, Object?> map) {
    Map<String, double>? decodeVector(Object? value) {
      if (value is! String || value.isEmpty) {
        return null;
      }
      final decoded = jsonDecode(value) as Map<String, dynamic>;
      return decoded.map(
        (key, item) => MapEntry(key, (item as num).toDouble()),
      );
    }

    return SensorDataModel(
      id: map['id'] as int,
      sensorId: map['sensor_id'] as int,
      deviceId: map['device_id'] as String,
      sensorName: map['sensor_name'] as String?,
      sensorType: map['sensor_type'] as String?,
      temperature: (map['temperature'] as num?)?.toDouble(),
      humidity: (map['humidity'] as num?)?.toDouble(),
      gasLevel: (map['gas_level'] as num?)?.toDouble(),
      lightLevel: (map['light_level'] as num?)?.toDouble(),
      distanceCm: (map['distance_cm'] as num?)?.toDouble(),
      soilRaw: (map['soil_raw'] as num?)?.toDouble(),
      soilMoisture: (map['soil_moisture'] as num?)?.toDouble(),
      motionDetected: _boolFromCache(map['motion_detected']),
      buzzer: _boolFromCache(map['buzzer']),
      accelerometer: decodeVector(map['accelerometer']),
      gyroscope: decodeVector(map['gyroscope']),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toCacheMap() {
    return {
      'id': id,
      'sensor_id': sensorId,
      'device_id': deviceId,
      'sensor_name': sensorName,
      'sensor_type': sensorType,
      'temperature': temperature,
      'humidity': humidity,
      'gas_level': gasLevel,
      'light_level': lightLevel,
      'distance_cm': distanceCm,
      'soil_raw': soilRaw,
      'soil_moisture': soilMoisture,
      'motion_detected': _boolToCache(motionDetected),
      'buzzer': _boolToCache(buzzer),
      'accelerometer': accelerometer == null ? null : jsonEncode(accelerometer),
      'gyroscope': gyroscope == null ? null : jsonEncode(gyroscope),
      'created_at': createdAt.toUtc().toIso8601String(),
      'cached_at': DateTime.now().toUtc().toIso8601String(),
    };
  }

  static bool? _boolFromCache(Object? value) {
    if (value == null) {
      return null;
    }
    return value == 1;
  }

  static int? _boolToCache(bool? value) {
    if (value == null) {
      return null;
    }
    return value ? 1 : 0;
  }
}
