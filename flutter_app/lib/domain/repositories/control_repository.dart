import '../entities/control_device.dart';
import '../entities/control_room.dart';

abstract class ControlRepository {
  Future<List<ControlRoom>> getRooms();

  Future<List<ControlDevice>> getDevices();

  Future<void> setDeviceStatus({required int deviceId, required bool enabled});
}
