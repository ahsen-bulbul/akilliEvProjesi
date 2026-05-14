class DatabaseConstants {
  DatabaseConstants._();

  static const databaseName = 'smart_home_cache.db';
  static const databaseVersion = 1;

  static const sensorReadingsTable = 'sensor_readings';

  static const id = 'id';
  static const sensorId = 'sensor_id';
  static const deviceId = 'device_id';
  static const sensorName = 'sensor_name';
  static const sensorType = 'sensor_type';
  static const temperature = 'temperature';
  static const humidity = 'humidity';
  static const gasLevel = 'gas_level';
  static const lightLevel = 'light_level';
  static const distanceCm = 'distance_cm';
  static const soilRaw = 'soil_raw';
  static const soilMoisture = 'soil_moisture';
  static const motionDetected = 'motion_detected';
  static const buzzer = 'buzzer';
  static const accelerometer = 'accelerometer';
  static const gyroscope = 'gyroscope';
  static const createdAt = 'created_at';
  static const cachedAt = 'cached_at';
}
