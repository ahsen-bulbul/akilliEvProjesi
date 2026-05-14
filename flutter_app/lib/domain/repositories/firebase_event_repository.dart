import '../entities/sensor_alarm_log.dart';
import '../entities/sensor_data.dart';

abstract class FirebaseEventRepository {
  Stream<List<SensorAlarmLog>> watchAlarmLogs({int limit = 20});

  Future<void> addAlarmLog({
    required SensorData reading,
    required List<String> labels,
  });
}
