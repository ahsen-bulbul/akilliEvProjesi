import 'package:flutter/foundation.dart';

import '../../domain/entities/control_device.dart';
import '../../domain/entities/control_room.dart';
import '../../domain/repositories/control_repository.dart';

class ControlViewModel extends ChangeNotifier {
  ControlViewModel(this._repository);

  final ControlRepository _repository;

  List<ControlRoom> _rooms = const [];
  List<ControlDevice> _devices = const [];
  final Set<int> _busyDeviceIds = {};
  bool _loading = false;
  String? _error;

  List<ControlRoom> get rooms => _rooms;
  List<ControlDevice> get devices => _devices;
  Set<int> get busyDeviceIds => Set.unmodifiable(_busyDeviceIds);
  bool get loading => _loading;
  String? get error => _error;

  Map<int?, List<ControlDevice>> get devicesByRoom {
    final grouped = <int?, List<ControlDevice>>{};
    for (final device in _devices) {
      grouped.putIfAbsent(device.roomId, () => []).add(device);
    }
    return grouped;
  }

  Future<void> loadControlData() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _repository.getRooms(),
        _repository.getDevices(),
      ]);
      _rooms = results[0] as List<ControlRoom>;
      _devices = results[1] as List<ControlDevice>;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> setDeviceStatus(ControlDevice device, bool enabled) async {
    final oldDevices = _devices;
    _busyDeviceIds.add(device.id);
    _devices = _devices
        .map(
          (item) =>
              item.id == device.id ? item.copyWith(status: enabled) : item,
        )
        .toList();
    notifyListeners();

    try {
      await _repository.setDeviceStatus(deviceId: device.id, enabled: enabled);
    } catch (e) {
      _devices = oldDevices;
      _error = e.toString();
    } finally {
      _busyDeviceIds.remove(device.id);
      notifyListeners();
    }
  }
}
