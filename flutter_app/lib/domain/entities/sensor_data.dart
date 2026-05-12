class SensorData {
  final int id;
  final int sensorId;
  final String deviceId;
  final String? sensorName;
  final String? sensorType;
  final double? temperature;
  final double? humidity;
  final double? gasLevel;
  final double? lightLevel;
  final double? distanceCm;
  final double? soilRaw;
  final double? soilMoisture;
  final bool? motionDetected;
  final bool? buzzer;
  final Map<String, double>? accelerometer;
  final Map<String, double>? gyroscope;
  final DateTime createdAt;

  const SensorData({
    required this.id,
    required this.sensorId,
    required this.deviceId,
    this.sensorName,
    this.sensorType,
    this.temperature,
    this.humidity,
    this.gasLevel,
    this.lightLevel,
    this.distanceCm,
    this.soilRaw,
    this.soilMoisture,
    this.motionDetected,
    this.buzzer,
    this.accelerometer,
    this.gyroscope,
    required this.createdAt,
  });
}
