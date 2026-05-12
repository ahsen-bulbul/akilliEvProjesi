import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/datasources/api_service.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  List<RoomSummary> _rooms = const [];
  List<DeviceSummary> _devices = const [];
  final Set<int> _busyDeviceIds = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadControlData();
  }

  Future<void> _loadControlData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getRooms(),
        ApiService.getDevices(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _rooms = results[0] as List<RoomSummary>;
        _devices = results[1] as List<DeviceSummary>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _setDeviceStatus(DeviceSummary device, bool enabled) async {
    final oldDevices = _devices;
    setState(() {
      _busyDeviceIds.add(device.id);
      _devices = _devices
          .map(
            (item) =>
                item.id == device.id ? item.copyWith(status: enabled) : item,
          )
          .toList();
    });

    try {
      await ApiService.sendControl(
        targetId: device.id,
        action: enabled ? 'turn_on' : 'turn_off',
        value: enabled.toString(),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _devices = oldDevices;
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _busyDeviceIds.remove(device.id));
      }
    }
  }

  Map<int?, List<DeviceSummary>> get _devicesByRoom {
    final grouped = <int?, List<DeviceSummary>>{};
    for (final device in _devices) {
      grouped.putIfAbsent(device.roomId, () => []).add(device);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final devicesByRoom = _devicesByRoom;
    final roomsWithDevices = [
      ..._rooms.where((room) => devicesByRoom.containsKey(room.id)),
    ];
    final unassignedDevices = devicesByRoom[null] ?? const <DeviceSummary>[];

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadControlData,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 88),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rooms',
                          style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_rooms.length} oda · ${_devices.length} cihaz',
                          style: GoogleFonts.dmSans(
                            color: const Color(0xFF8B949E),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Yenile',
                    color: const Color(0xFF00D4AA),
                    onPressed: _loadControlData,
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (_loading)
                const _ControlStatus(text: 'Odalar ve cihazlar yukleniyor...')
              else if (_error != null)
                _ControlStatus(text: _error!, isError: true)
              else if (_devices.isEmpty)
                const _ControlStatus(text: 'Kayitli cihaz bulunamadi.')
              else ...[
                for (final room in roomsWithDevices) ...[
                  _RoomPanel(
                    title: room.name,
                    devices: devicesByRoom[room.id]!,
                    busyDeviceIds: _busyDeviceIds,
                    onSetStatus: _setDeviceStatus,
                  ),
                  const SizedBox(height: 14),
                ],
                if (unassignedDevices.isNotEmpty) ...[
                  _RoomPanel(
                    title: 'Odasiz Cihazlar',
                    devices: unassignedDevices,
                    busyDeviceIds: _busyDeviceIds,
                    onSetStatus: _setDeviceStatus,
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomPanel extends StatelessWidget {
  final String title;
  final List<DeviceSummary> devices;
  final Set<int> busyDeviceIds;
  final Future<void> Function(DeviceSummary device, bool enabled) onSetStatus;

  const _RoomPanel({
    required this.title,
    required this.devices,
    required this.busyDeviceIds,
    required this.onSetStatus,
  });

  @override
  Widget build(BuildContext context) {
    final activeCount = devices.where((device) => device.status).length;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Row(
              children: [
                const Icon(
                  Icons.meeting_room_outlined,
                  color: Color(0xFF00D4AA),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.dmSans(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '$activeCount/${devices.length} acik',
                  style: GoogleFonts.spaceMono(
                    color: const Color(0xFF8B949E),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFF30363D)),
          for (final device in devices)
            _DeviceRow(
              device: device,
              isBusy: busyDeviceIds.contains(device.id),
              onSetStatus: onSetStatus,
            ),
        ],
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  final DeviceSummary device;
  final bool isBusy;
  final Future<void> Function(DeviceSummary device, bool enabled) onSetStatus;

  const _DeviceRow({
    required this.device,
    required this.isBusy,
    required this.onSetStatus,
  });

  @override
  Widget build(BuildContext context) {
    final color = device.status
        ? const Color(0xFF00D4AA)
        : const Color(0xFF8B949E);
    final icon = switch (device.type.toLowerCase()) {
      'light' || 'lamp' => Icons.lightbulb_outline,
      'fan' => Icons.air,
      'ac' || 'climate' => Icons.ac_unit,
      'camera' => Icons.videocam_outlined,
      'door' => Icons.door_front_door_outlined,
      _ => Icons.power_settings_new,
    };

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${device.type} · ${device.status ? 'Acik' : 'Kapali'}',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF8B949E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (isBusy)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00D4AA),
              ),
            )
          else
            SegmentedButton<bool>(
              showSelectedIcon: false,
              selected: {device.status},
              segments: const [
                ButtonSegment(value: false, label: Text('Kapat')),
                ButtonSegment(value: true, label: Text('Ac')),
              ],
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                textStyle: WidgetStatePropertyAll(
                  GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                padding: const WidgetStatePropertyAll(
                  EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
              onSelectionChanged: (selection) {
                final enabled = selection.first;
                if (enabled != device.status) {
                  onSetStatus(device, enabled);
                }
              },
            ),
        ],
      ),
    );
  }
}

class _ControlStatus extends StatelessWidget {
  final String text;
  final bool isError;

  const _ControlStatus({required this.text, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? const Color(0xFFFF6B6B) : const Color(0xFF30363D),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          color: isError ? const Color(0xFFFFB4B4) : const Color(0xFF8B949E),
          fontSize: 13,
        ),
      ),
    );
  }
}
