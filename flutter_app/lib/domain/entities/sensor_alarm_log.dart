class SensorAlarmLog {
  final String id;
  final int readingId;
  final int sensorId;
  final String deviceId;
  final List<String> labels;
  final double? temperature;
  final double? humidity;
  final double? gasLevel;
  final double? soilMoisture;
  final DateTime createdAt;

  const SensorAlarmLog({
    required this.id,
    required this.readingId,
    required this.sensorId,
    required this.deviceId,
    required this.labels,
    this.temperature,
    this.humidity,
    this.gasLevel,
    this.soilMoisture,
    required this.createdAt,
  });
}
