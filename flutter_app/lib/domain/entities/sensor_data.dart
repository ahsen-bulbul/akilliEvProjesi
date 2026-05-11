class SensorData {
  final int id;
  final String deviceId;
  final double? temperature;
  final double? humidity;
  final double? gasLevel;
  final double? lightLevel;
  final double? distanceCm;
  final DateTime createdAt;

  const SensorData({
    required this.id,
    required this.deviceId,
    this.temperature,
    this.humidity,
    this.gasLevel,
    this.lightLevel,
    this.distanceCm,
    required this.createdAt,
  });
}
