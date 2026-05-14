import 'sensor_repository_impl.dart';

class OfflineFirstSensorRepository extends SensorRepositoryImpl {
  OfflineFirstSensorRepository({
    super.remoteDataSource,
    super.localDataSource,
    super.connectivityChecker,
  });
}
