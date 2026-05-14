import '../../domain/entities/sensor_alarm_log.dart';
import '../../domain/entities/sensor_data.dart';
import '../../domain/repositories/firebase_event_repository.dart';
import '../datasources/firebase_event_data_source.dart';

class FirebaseEventRepositoryImpl implements FirebaseEventRepository {
  FirebaseEventRepositoryImpl({FirebaseEventDataSource? dataSource})
    : _dataSource = dataSource ?? FirebaseEventDataSource();

  final FirebaseEventDataSource _dataSource;

  @override
  Stream<List<SensorAlarmLog>> watchAlarmLogs({int limit = 20}) {
    return _dataSource.watchAlarmLogs(limit: limit);
  }

  @override
  Future<void> addAlarmLog({
    required SensorData reading,
    required List<String> labels,
  }) {
    return _dataSource.addAlarmLog(reading: reading, labels: labels);
  }
}
