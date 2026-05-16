import 'package:flutter/foundation.dart';

import '../../data/datasources/api_service.dart';
import '../../domain/entities/control_device.dart';
import '../../domain/entities/control_room.dart';

class AdminViewModel extends ChangeNotifier {
  List<AppUser> _users = const [];
  List<ControlRoom> _rooms = const [];
  List<ControlDevice> _devices = const [];
  List<SensorDefinition> _sensors = const [];
  String? _selectedUserId;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  List<AppUser> get users => _users.where((user) => !user.isAdmin).toList();
  List<ControlRoom> get rooms => _rooms;
  List<ControlDevice> get devices => _devices;
  List<SensorDefinition> get sensors => _sensors;
  String? get selectedUserId => _selectedUserId;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;

  AppUser? get selectedUser {
    final id = _selectedUserId;
    if (id == null) {
      return null;
    }
    for (final user in users) {
      if (user.id == id) {
        return user;
      }
    }
    return null;
  }

  List<ControlDevice> devicesForRoom(int roomId) {
    return _devices.where((device) => device.roomId == roomId).toList();
  }

  List<SensorDefinition> sensorsForRoom(int roomId) {
    return _sensors.where((sensor) => sensor.roomId == roomId).toList();
  }

  Future<void> loadUsers() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _users = await ApiService.getAdminUsers();
      _syncSelectedUser();
      await _loadSelectedUserData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> selectUser(String userId) async {
    if (_selectedUserId == userId) {
      return;
    }
    _selectedUserId = userId;
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _loadSelectedUserData();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> createRoom(String name) {
    return _save(() async {
      final userId = _requireSelectedUser();
      await ApiService.createAdminRoom(targetUserId: userId, name: name);
      await _loadSelectedUserData();
    });
  }

  Future<void> deleteSelectedUser() {
    return _save(() async {
      final userId = _requireSelectedUser();
      await ApiService.deleteAdminUser(userId);
      _users = await ApiService.getAdminUsers();
      _syncSelectedUser();
      await _loadSelectedUserData();
    });
  }

  Future<void> createDevice({
    required String name,
    required String type,
    int? roomId,
  }) {
    return _save(() async {
      final userId = _requireSelectedUser();
      await ApiService.createAdminDevice(
        targetUserId: userId,
        name: name,
        type: type,
        roomId: roomId,
      );
      await _loadSelectedUserData();
    });
  }

  Future<void> createSensor({
    required String name,
    required String type,
    int? roomId,
  }) {
    return _save(() async {
      final userId = _requireSelectedUser();
      await ApiService.createAdminSensor(
        targetUserId: userId,
        name: name,
        type: type,
        roomId: roomId,
      );
      await _loadSelectedUserData();
    });
  }

  Future<void> deleteRoom(int roomId) {
    return _save(() async {
      final userId = _requireSelectedUser();
      await ApiService.deleteAdminRoom(targetUserId: userId, roomId: roomId);
      await _loadSelectedUserData();
    });
  }

  Future<void> deleteDevice(int deviceId) {
    return _save(() async {
      final userId = _requireSelectedUser();
      await ApiService.deleteAdminDevice(
        targetUserId: userId,
        deviceId: deviceId,
      );
      await _loadSelectedUserData();
    });
  }

  Future<void> deleteSensor(int sensorId) {
    return _save(() async {
      final userId = _requireSelectedUser();
      await ApiService.deleteAdminSensor(
        targetUserId: userId,
        sensorId: sensorId,
      );
      await _loadSelectedUserData();
    });
  }

  Future<void> _loadSelectedUserData() async {
    final userId = _selectedUserId;
    if (userId == null) {
      _rooms = const [];
      _devices = const [];
      _sensors = const [];
      return;
    }

    final results = await Future.wait([
      ApiService.getAdminRooms(userId),
      ApiService.getAdminDevices(userId),
      ApiService.getAdminSensors(userId),
    ]);
    _rooms = results[0] as List<ControlRoom>;
    _devices = results[1] as List<ControlDevice>;
    _sensors = results[2] as List<SensorDefinition>;
  }

  void _syncSelectedUser() {
    final manageableUsers = users;
    if (manageableUsers.isEmpty) {
      _selectedUserId = null;
      return;
    }

    final currentId = _selectedUserId;
    final hasCurrent = manageableUsers.any((user) => user.id == currentId);
    if (!hasCurrent) {
      _selectedUserId = manageableUsers.first.id;
    }
  }

  Future<void> _save(Future<void> Function() action) async {
    _saving = true;
    _error = null;
    notifyListeners();

    try {
      await action();
    } catch (e) {
      _error = e.toString();
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  String _requireSelectedUser() {
    final userId = _selectedUserId;
    if (userId == null) {
      throw StateError('Once bir kullanici secin.');
    }
    return userId;
  }
}
