import '../../domain/entities/sensor_data.dart';
import '../../domain/repositories/sensor_repository.dart';
import '../connectivity/connectivity_checker.dart';
import '../datasources/sensor_remote_data_source.dart';
import '../local/sensor_local_data_source.dart';
import '../models/sensor_data_model.dart';

class SensorRepositoryImpl implements SensorRepository {
  SensorRepositoryImpl({
    SensorRemoteDataSource? remoteDataSource,
    SensorLocalDataSource? localDataSource,
    ConnectivityChecker? connectivityChecker,
  }) : _remoteDataSource = remoteDataSource ?? SensorRemoteDataSource(),
       _localDataSource = localDataSource ?? SensorLocalDataSource(),
       _connectivityChecker = connectivityChecker ?? ConnectivityChecker();

  final SensorRemoteDataSource _remoteDataSource;
  final SensorLocalDataSource _localDataSource;
  final ConnectivityChecker _connectivityChecker;

  @override
  Stream<SensorData> get liveReadings => _remoteDataSource.liveReadings;

  @override
  Future<void> connectLiveReadings() {
    return _remoteDataSource.connectLiveReadings();
  }

  @override
  Future<void> disconnectLiveReadings() {
    return _remoteDataSource.disconnectLiveReadings();
  }

  @override
  Future<SensorData> getLatestReading({int? sensorId}) async {
    if (await _connectivityChecker.isOnline) {
      try {
        final remote = await _remoteDataSource.getLatestReading(
          sensorId: sensorId,
        );
        final model = SensorDataModel.fromEntity(remote);
        await _localDataSource.cacheReading(model);
        return model;
      } catch (_) {
        // API/DNS/auth failures fall back to the local SQLite cache.
      }
    }

    final cached = await _localDataSource.getLatestReading(sensorId: sensorId);
    if (cached != null) {
      return cached;
    }
    throw StateError('Offline cache icinde sensor verisi bulunamadi.');
  }

  @override
  Future<List<SensorData>> getSensorHistory({int limit = 20}) async {
    if (await _connectivityChecker.isOnline) {
      try {
        final remote = await _remoteDataSource.getSensorHistory(limit: limit);
        final models = remote.map(SensorDataModel.fromEntity).toList();
        await _localDataSource.cacheReadings(models);
        return models;
      } catch (_) {
        // If backend, auth, or network fails, serve the last saved readings.
      }
    }

    return _localDataSource.getHistory(limit: limit);
  }

  @override
  Future<void> cacheReading(SensorData reading) {
    return _localDataSource.cacheReading(SensorDataModel.fromEntity(reading));
  }

  @override
  Future<SensorData?> getCachedLatestReading({int? sensorId}) {
    return _localDataSource.getLatestReading(sensorId: sensorId);
  }

  @override
  void dispose() {
    _remoteDataSource.dispose();
  }
}
