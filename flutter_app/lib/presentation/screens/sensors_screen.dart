import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/sensor_data.dart';
import '../../domain/entities/sensor_alarm_log.dart';
import '../viewmodels/firebase_alarm_log_view_model.dart';
import '../viewmodels/sensor_view_model.dart';
import '../widgets/sensor_card.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  int _shownAlertVersion = 0;

  void _showAlertSnackBar(List<String> alerts) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF5A1F24),
        duration: const Duration(seconds: 4),
        content: Text(
          'Alert: ${alerts.join(', ')} normal araligin disinda.',
          style: GoogleFonts.dmSans(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SensorViewModel>();
    if (viewModel.alertVersion != _shownAlertVersion) {
      _shownAlertVersion = viewModel.alertVersion;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && viewModel.lastAlertLabels.isNotEmpty) {
          _showAlertSnackBar(viewModel.lastAlertLabels);
        }
      });
    }

    final reading = viewModel.latest;
    final updatedAt = reading == null
        ? 'No data'
        : DateFormat('HH:mm:ss').format(reading.createdAt.toLocal());

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: viewModel.connectLiveReadings,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              _Header(
                updatedAt: updatedAt,
                hasAlert: viewModel.hasAlert,
                isCached: viewModel.showingCachedData,
              ),
              const SizedBox(height: 18),
              if (viewModel.loading)
                const _StatusPanel(text: 'Loading live sensor data...')
              else if (viewModel.error != null && reading == null)
                _StatusPanel(text: viewModel.error!, isError: true)
              else if (reading == null)
                const _StatusPanel(text: 'No sensor reading found.')
              else ...[
                if (viewModel.showingCachedData) ...[
                  _StatusPanel(
                    text:
                        viewModel.error ??
                        'Showing cached sensor data. Values are not live.',
                    isWarning: true,
                  ),
                  const SizedBox(height: 16),
                ],
                _DevicePanel(
                  reading: reading,
                  isCached: viewModel.showingCachedData,
                ),
                const SizedBox(height: 16),
                _SensorGrid(reading: reading),
                const SizedBox(height: 16),
                const _FirestoreAlarmLogPanel(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FirestoreAlarmLogPanel extends StatelessWidget {
  const _FirestoreAlarmLogPanel();

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FirebaseAlarmLogViewModel>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.cloud_queue,
                color: Color(0xFFFFD166),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Firestore Alarm Logs',
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          StreamBuilder<List<SensorAlarmLog>>(
            stream: viewModel.watchAlarmLogs(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _FirestoreStatusText(
                  'Firestore stream error: ${snapshot.error}',
                  color: const Color(0xFFFFB4B4),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _FirestoreStatusText('Listening snapshots()...');
              }

              final logs = snapshot.data ?? const [];
              if (logs.isEmpty) {
                return const _FirestoreStatusText(
                  'Alarm log yok. Esik asilinca Firestore kaydi olusacak.',
                );
              }

              return Column(
                children: logs
                    .take(4)
                    .map(
                      (log) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _FirestoreAlarmLogTile(log: log),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FirestoreStatusText extends StatelessWidget {
  final String text;
  final Color color;

  const _FirestoreStatusText(
    this.text, {
    this.color = const Color(0xFF8B949E),
  });

  @override
  Widget build(BuildContext context) {
    return Text(text, style: GoogleFonts.dmSans(color: color, fontSize: 13));
  }
}

class _FirestoreAlarmLogTile extends StatelessWidget {
  final SensorAlarmLog log;

  const _FirestoreAlarmLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('HH:mm:ss').format(log.createdAt.toLocal());

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 7),
          decoration: const BoxDecoration(
            color: Color(0xFFFF6B6B),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                log.labels.join(', '),
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${log.deviceId} - reading #${log.readingId} - $time',
                style: GoogleFonts.spaceMono(
                  color: const Color(0xFF8B949E),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String updatedAt;
  final bool hasAlert;
  final bool isCached;

  const _Header({
    required this.updatedAt,
    required this.hasAlert,
    required this.isCached,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Live Sensors',
                style: GoogleFonts.dmSans(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isCached
                    ? 'Cached SQLite reading - not live'
                    : 'Direct MQTT feed via HiveMQ',
                style: GoogleFonts.dmSans(
                  color: isCached
                      ? const Color(0xFFFFD166)
                      : const Color(0xFF8B949E),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: hasAlert ? const Color(0xFF5A1F24) : const Color(0xFF12362F),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasAlert
                  ? const Color(0xFFFF6B6B)
                  : isCached
                  ? const Color(0xFFFFD166)
                  : const Color(0xFF00D4AA),
            ),
          ),
          child: Text(
            isCached ? 'CACHED $updatedAt' : updatedAt,
            style: GoogleFonts.spaceMono(
              color: hasAlert
                  ? const Color(0xFFFFB4B4)
                  : isCached
                  ? const Color(0xFFFFD166)
                  : const Color(0xFF75E6D0),
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}

class _DevicePanel extends StatelessWidget {
  final SensorData reading;
  final bool isCached;

  const _DevicePanel({required this.reading, this.isCached = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          const Icon(Icons.developer_board, color: Color(0xFF00D4AA), size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reading.deviceId,
                  style: GoogleFonts.spaceMono(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  isCached
                      ? 'Cached reading #${reading.id}'
                      : 'Reading #${reading.id}',
                  style: GoogleFonts.dmSans(
                    color: isCached
                        ? const Color(0xFFFFD166)
                        : const Color(0xFF8B949E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.circle,
            color: isCached ? const Color(0xFFFFD166) : const Color(0xFF00D4AA),
            size: 10,
          ),
        ],
      ),
    );
  }
}

class _SensorGrid extends StatelessWidget {
  final SensorData reading;

  const _SensorGrid({required this.reading});

  @override
  Widget build(BuildContext context) {
    final cards = [
      _SensorCardData(
        'Temperature',
        reading.temperature,
        'C',
        Icons.thermostat,
        const Color(0xFFFFB020),
        reading.temperature != null && reading.temperature! > 30,
      ),
      _SensorCardData(
        'Soil Moisture',
        reading.soilMoisture ?? reading.humidity,
        '%',
        Icons.water_drop_outlined,
        const Color(0xFF58A6FF),
        (reading.soilMoisture ?? reading.humidity) != null &&
            ((reading.soilMoisture ?? reading.humidity)! < 20 ||
                (reading.soilMoisture ?? reading.humidity)! > 80),
      ),
      _SensorCardData(
        'MQ9 Gas',
        reading.gasLevel,
        'raw',
        Icons.air,
        const Color(0xFF9B59B6),
        reading.gasLevel != null && reading.gasLevel! > 500,
      ),
      _SensorCardData(
        'Motion',
        null,
        '',
        Icons.directions_run,
        const Color(0xFFFF6B6B),
        reading.motionDetected == true,
        valueText: reading.motionDetected == null
            ? '--'
            : (reading.motionDetected! ? 'Detected' : 'Clear'),
      ),
      _SensorCardData(
        'Buzzer',
        null,
        '',
        Icons.notifications_active_outlined,
        const Color(0xFF00D4AA),
        reading.buzzer == true,
        valueText: reading.buzzer == null
            ? '--'
            : (reading.buzzer! ? 'On' : 'Off'),
      ),
      _SensorCardData(
        'Accel',
        _vectorMagnitude(reading.accelerometer),
        'm/s2',
        Icons.screen_rotation_alt_outlined,
        const Color(0xFFFFD166),
        false,
      ),
      _SensorCardData(
        'Gyro',
        _vectorMagnitude(reading.gyroscope),
        'dps',
        Icons.threesixty,
        const Color(0xFF00B8D9),
        false,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemBuilder: (context, index) {
        final card = cards[index];
        return SensorCard(
          label: card.label,
          value:
              card.valueText ??
              (card.value == null ? '--' : card.value!.toStringAsFixed(1)),
          unit: card.unit,
          icon: card.icon,
          color: card.color,
          isAlert: card.isAlert,
        );
      },
    );
  }

  double? _vectorMagnitude(Map<String, double>? vector) {
    if (vector == null) {
      return null;
    }
    final x = vector['x'] ?? 0;
    final y = vector['y'] ?? 0;
    final z = vector['z'] ?? 0;
    return sqrt(x * x + y * y + z * z);
  }
}

class _SensorCardData {
  final String label;
  final double? value;
  final String unit;
  final IconData icon;
  final Color color;
  final bool isAlert;
  final String? valueText;

  const _SensorCardData(
    this.label,
    this.value,
    this.unit,
    this.icon,
    this.color,
    this.isAlert, {
    this.valueText,
  });
}

class _StatusPanel extends StatelessWidget {
  final String text;
  final bool isError;
  final bool isWarning;

  const _StatusPanel({
    required this.text,
    this.isError = false,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isError
              ? const Color(0xFFFF6B6B)
              : isWarning
              ? const Color(0xFFFFD166)
              : const Color(0xFF30363D),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          color: isError
              ? const Color(0xFFFFB4B4)
              : isWarning
              ? const Color(0xFFFFD166)
              : const Color(0xFF8B949E),
          fontSize: 13,
        ),
      ),
    );
  }
}
