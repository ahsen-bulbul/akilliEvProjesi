import 'package:sqflite/sqflite.dart';

import '../../core/local/app_database.dart';
import '../../core/local/database_constants.dart';
import '../models/sensor_data_model.dart';

class SensorDao {
  SensorDao({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> upsertReading(SensorDataModel reading) async {
    final db = await _database.database;
    await db.insert(
      DatabaseConstants.sensorReadingsTable,
      reading.toCacheMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertReadings(List<SensorDataModel> readings) async {
    if (readings.isEmpty) {
      return;
    }

    final db = await _database.database;
    final batch = db.batch();
    for (final reading in readings) {
      batch.insert(
        DatabaseConstants.sensorReadingsTable,
        reading.toCacheMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<SensorDataModel?> getLatestReading({int? sensorId}) async {
    final db = await _database.database;
    final rows = await db.query(
      DatabaseConstants.sensorReadingsTable,
      where: sensorId == null ? null : '${DatabaseConstants.sensorId} = ?',
      whereArgs: sensorId == null ? null : [sensorId],
      orderBy: '${DatabaseConstants.createdAt} DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return SensorDataModel.fromCacheMap(rows.first);
  }

  Future<List<SensorDataModel>> getHistory({int limit = 20}) async {
    final db = await _database.database;
    final rows = await db.query(
      DatabaseConstants.sensorReadingsTable,
      orderBy: '${DatabaseConstants.createdAt} DESC',
      limit: limit,
    );
    return rows.map(SensorDataModel.fromCacheMap).toList();
  }
}
