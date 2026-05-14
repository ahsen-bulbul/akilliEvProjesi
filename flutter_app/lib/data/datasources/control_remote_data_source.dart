import '../../domain/entities/control_device.dart';
import '../../domain/entities/control_room.dart';
import 'api_service.dart';

class ControlRemoteDataSource {
  Future<List<ControlRoom>> getRooms() {
    return ApiService.getRooms();
  }

  Future<List<ControlDevice>> getDevices() {
    return ApiService.getDevices();
  }

  Future<void> sendDeviceStatus({
    required int deviceId,
    required bool enabled,
  }) {
    return ApiService.sendControl(
      targetId: deviceId,
      action: enabled ? 'turn_on' : 'turn_off',
      value: enabled.toString(),
    );
  }
}
