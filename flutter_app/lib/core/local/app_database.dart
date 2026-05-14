import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'database_constants.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }

    final path = p.join(
      await getDatabasesPath(),
      DatabaseConstants.databaseName,
    );
    final db = await openDatabase(
      path,
      version: DatabaseConstants.databaseVersion,
      onCreate: _createSchema,
      onUpgrade: _runMigrations,
    );
    _database = db;
    return db;
  }

  Future<void> _createSchema(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DatabaseConstants.sensorReadingsTable} (
        ${DatabaseConstants.id} INTEGER PRIMARY KEY,
        ${DatabaseConstants.sensorId} INTEGER NOT NULL,
        ${DatabaseConstants.deviceId} TEXT NOT NULL,
        ${DatabaseConstants.sensorName} TEXT,
        ${DatabaseConstants.sensorType} TEXT,
        ${DatabaseConstants.temperature} REAL,
        ${DatabaseConstants.humidity} REAL,
        ${DatabaseConstants.gasLevel} REAL,
        ${DatabaseConstants.lightLevel} REAL,
        ${DatabaseConstants.distanceCm} REAL,
        ${DatabaseConstants.soilRaw} REAL,
        ${DatabaseConstants.soilMoisture} REAL,
        ${DatabaseConstants.motionDetected} INTEGER,
        ${DatabaseConstants.buzzer} INTEGER,
        ${DatabaseConstants.accelerometer} TEXT,
        ${DatabaseConstants.gyroscope} TEXT,
        ${DatabaseConstants.createdAt} TEXT NOT NULL,
        ${DatabaseConstants.cachedAt} TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_sensor_readings_created_at '
      'ON ${DatabaseConstants.sensorReadingsTable}'
      '(${DatabaseConstants.createdAt} DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_sensor_readings_sensor_id '
      'ON ${DatabaseConstants.sensorReadingsTable}'
      '(${DatabaseConstants.sensorId})',
    );
  }

  Future<void> _runMigrations(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 1) {
      await _createSchema(db, newVersion);
    }
  }
}
