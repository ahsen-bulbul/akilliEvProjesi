import 'package:flutter/foundation.dart';

import '../../domain/entities/sensor_alarm_log.dart';
import '../../domain/repositories/firebase_event_repository.dart';

class FirebaseAlarmLogViewModel extends ChangeNotifier {
  FirebaseAlarmLogViewModel(this._repository);

  final FirebaseEventRepository _repository;

  Stream<List<SensorAlarmLog>> watchAlarmLogs({int limit = 12}) {
    return _repository.watchAlarmLogs(limit: limit);
  }
}
