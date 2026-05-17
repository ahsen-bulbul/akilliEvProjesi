import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/datasources/api_service.dart';
import '../../domain/entities/control_device.dart';
import '../../domain/entities/control_room.dart';
import '../viewmodels/control_view_model.dart';

class RoomDetailScreen extends StatefulWidget {
  final ControlRoom room;

  const RoomDetailScreen({super.key, required this.room});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late Future<List<SensorDefinition>> _sensorsFuture;

  @override
  void initState() {
    super.initState();
    _sensorsFuture = ApiService.getSensorDefinitions();
  }

  @override
  Widget build(BuildContext context) {
    final control = context.watch<ControlViewModel>();
    final devices = control.devices
        .where((device) => device.roomId == widget.room.id)
        .toList();
    final activeDevices = devices.where((device) => device.status).length;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: Text(
          widget.room.name,
          style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await control.loadControlData();
          setState(() => _sensorsFuture = ApiService.getSensorDefinitions());
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            _SummaryPanel(
              deviceCount: devices.length,
              activeDeviceCount: activeDevices,
              sensorsFuture: _sensorsFuture,
              roomId: widget.room.id,
            ),
            const SizedBox(height: 16),
            Text(
              'Cihazlar',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (devices.isEmpty)
              const _InfoPanel('Bu odada cihaz yok.')
            else
              for (final device in devices)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RoomDeviceTile(
                    device: device,
                    isBusy: control.busyDeviceIds.contains(device.id),
                    onSetStatus: control.setDeviceStatus,
                  ),
                ),
            const SizedBox(height: 10),
            Text(
              'Sensorler',
              style: GoogleFonts.dmSans(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            FutureBuilder<List<SensorDefinition>>(
              future: _sensorsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        color: Color(0xFF00D4AA),
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return _InfoPanel('Sensorler alinamadi: ${snapshot.error}');
                }

                final sensors = (snapshot.data ?? const <SensorDefinition>[])
                    .where((sensor) => sensor.roomId == widget.room.id)
                    .toList();
                if (sensors.isEmpty) {
                  return const _InfoPanel('Bu odada sensor yok.');
                }

                return Column(
                  children: sensors
                      .map(
                        (sensor) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _SensorDefinitionTile(sensor: sensor),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryPanel extends StatelessWidget {
  final int deviceCount;
  final int activeDeviceCount;
  final Future<List<SensorDefinition>> sensorsFuture;
  final int roomId;

  const _SummaryPanel({
    required this.deviceCount,
    required this.activeDeviceCount,
    required this.sensorsFuture,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: FutureBuilder<List<SensorDefinition>>(
        future: sensorsFuture,
        builder: (context, snapshot) {
          final sensorCount = (snapshot.data ?? const <SensorDefinition>[])
              .where((sensor) => sensor.roomId == roomId)
              .length;
          return Row(
            children: [
              _SummaryMetric(label: 'Cihaz', value: deviceCount.toString()),
              _SummaryMetric(
                label: 'Acik',
                value: '$activeDeviceCount/$deviceCount',
              ),
              _SummaryMetric(label: 'Sensor', value: sensorCount.toString()),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.spaceMono(
              color: const Color(0xFF00D4AA),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.dmSans(
              color: const Color(0xFF8B949E),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomDeviceTile extends StatelessWidget {
  final ControlDevice device;
  final bool isBusy;
  final Future<void> Function(ControlDevice device, bool enabled) onSetStatus;

  const _RoomDeviceTile({
    required this.device,
    required this.isBusy,
    required this.onSetStatus,
  });

  @override
  Widget build(BuildContext context) {
    final color = device.status
        ? const Color(0xFF00D4AA)
        : const Color(0xFF8B949E);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          Icon(_iconForDevice(device.type), color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${device.type} - ${device.status ? 'Acik' : 'Kapali'}',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF8B949E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isBusy)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF00D4AA),
              ),
            )
          else
            Switch(
              value: device.status,
              activeThumbColor: const Color(0xFF00D4AA),
              onChanged: (enabled) => onSetStatus(device, enabled),
            ),
        ],
      ),
    );
  }

  IconData _iconForDevice(String type) {
    return switch (type.toLowerCase()) {
      'light' || 'lamp' => Icons.lightbulb_outline,
      'fan' => Icons.air,
      'ac' || 'climate' => Icons.ac_unit,
      'camera' => Icons.videocam_outlined,
      'door' => Icons.door_front_door_outlined,
      _ => Icons.power_settings_new,
    };
  }
}

class _SensorDefinitionTile extends StatelessWidget {
  final SensorDefinition sensor;

  const _SensorDefinitionTile({required this.sensor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          Icon(_iconForSensor(sensor.type), color: const Color(0xFFFFD166)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sensor.name,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${sensor.type} - ${sensor.active ? 'Aktif' : 'Pasif'}',
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF8B949E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForSensor(String type) {
    final lower = type.toLowerCase();
    if (lower.contains('gas') || lower.contains('mq')) {
      return Icons.air;
    }
    if (lower.contains('soil') || lower.contains('nem')) {
      return Icons.water_drop_outlined;
    }
    if (lower.contains('motion') || lower.contains('hw')) {
      return Icons.directions_run;
    }
    if (lower.contains('buzzer')) {
      return Icons.notifications_active_outlined;
    }
    return Icons.sensors_outlined;
  }
}

class _InfoPanel extends StatelessWidget {
  final String text;

  const _InfoPanel(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(color: const Color(0xFF8B949E)),
      ),
    );
  }
}
