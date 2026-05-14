import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/sensor_alarm_log.dart';
import '../../domain/entities/sensor_data.dart';

class FirebaseEventDataSource {
  FirebaseEventDataSource({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  static const collectionName = 'sensor_alarm_logs';

  final FirebaseFirestore _firestore;

  Stream<List<SensorAlarmLog>> watchAlarmLogs({int limit = 20}) {
    return _firestore
        .collection(collectionName)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => _alarmLogFromDoc(doc)).toList(),
        );
  }

  Future<void> addAlarmLog({
    required SensorData reading,
    required List<String> labels,
  }) {
    return _firestore.collection(collectionName).add({
      'reading_id': reading.id,
      'sensor_id': reading.sensorId,
      'device_id': reading.deviceId,
      'labels': labels,
      'temperature': reading.temperature,
      'humidity': reading.humidity,
      'gas_level': reading.gasLevel,
      'soil_moisture': reading.soilMoisture,
      'created_at': Timestamp.fromDate(reading.createdAt.toUtc()),
      'written_at': FieldValue.serverTimestamp(),
    });
  }

  SensorAlarmLog _alarmLogFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAt = data['created_at'];
    return SensorAlarmLog(
      id: doc.id,
      readingId: data['reading_id'] as int? ?? 0,
      sensorId: data['sensor_id'] as int? ?? 0,
      deviceId: data['device_id'] as String? ?? 'unknown',
      labels: (data['labels'] as List<dynamic>? ?? const [])
          .map((label) => label.toString())
          .toList(),
      temperature: (data['temperature'] as num?)?.toDouble(),
      humidity: (data['humidity'] as num?)?.toDouble(),
      gasLevel: (data['gas_level'] as num?)?.toDouble(),
      soilMoisture: (data['soil_moisture'] as num?)?.toDouble(),
      createdAt: createdAt is Timestamp
          ? createdAt.toDate()
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
