import '../../domain/entities/control_device.dart';
import '../../domain/entities/control_room.dart';
import '../../domain/repositories/control_repository.dart';
import '../datasources/control_remote_data_source.dart';

class ControlRepositoryImpl implements ControlRepository {
  ControlRepositoryImpl({ControlRemoteDataSource? remoteDataSource})
    : _remoteDataSource = remoteDataSource ?? ControlRemoteDataSource();

  final ControlRemoteDataSource _remoteDataSource;

  @override
  Future<List<ControlRoom>> getRooms() {
    return _remoteDataSource.getRooms();
  }

  @override
  Future<List<ControlDevice>> getDevices() {
    return _remoteDataSource.getDevices();
  }

  @override
  Future<void> setDeviceStatus({required int deviceId, required bool enabled}) {
    return _remoteDataSource.sendDeviceStatus(
      deviceId: deviceId,
      enabled: enabled,
    );
  }
}
