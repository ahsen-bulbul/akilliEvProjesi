import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../data/datasources/api_service.dart';
import '../../domain/entities/sensor_data.dart';
import '../../domain/entities/sensor_threshold.dart';
import '../widgets/sensor_card.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  static const _thresholds = [
    SensorThreshold(key: 'temperature', label: 'Temperature', max: 30, unit: 'C'),
    SensorThreshold(key: 'humidity', label: 'Humidity', max: 70, unit: '%'),
    SensorThreshold(key: 'gas', label: 'Gas Level', max: 400, unit: 'ppm'),
    SensorThreshold(key: 'light', label: 'Light Level', max: 900, unit: 'lx'),
    SensorThreshold(key: 'distance', label: 'Distance', min: 15, unit: 'cm'),
  ];

  SensorData? _latest;
  Timer? _timer;
  bool _loading = true;
  String? _error;
  int? _lastNotifiedReadingId;

  @override
  void initState() {
    super.initState();
    _loadLatest();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _loadLatest());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadLatest() async {
    try {
      final reading = await ApiService.getLatestReading();
      if (!mounted) {
        return;
      }
      setState(() {
        _latest = reading;
        _loading = false;
        _error = null;
      });
      _notifyIfNeeded(reading);
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

  void _notifyIfNeeded(SensorData reading) {
    final alerts = _alertLabels(reading);
    if (alerts.isEmpty || _lastNotifiedReadingId == reading.id) {
      return;
    }
    _lastNotifiedReadingId = reading.id;

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

  List<String> _alertLabels(SensorData reading) {
    return _thresholds
        .where((threshold) => threshold.isExceeded(_valueFor(reading, threshold.key)))
        .map((threshold) => threshold.label)
        .toList();
  }

  double? _valueFor(SensorData reading, String key) {
    return switch (key) {
      'temperature' => reading.temperature,
      'humidity' => reading.humidity,
      'gas' => reading.gasLevel,
      'light' => reading.lightLevel,
      'distance' => reading.distanceCm,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final reading = _latest;
    final updatedAt = reading == null
        ? 'No data'
        : DateFormat('HH:mm:ss').format(reading.createdAt.toLocal());

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadLatest,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              _Header(
                updatedAt: updatedAt,
                hasAlert: reading != null && _alertLabels(reading).isNotEmpty,
              ),
              const SizedBox(height: 18),
              if (_loading)
                const _StatusPanel(text: 'Loading live sensor data...')
              else if (_error != null)
                _StatusPanel(text: _error!, isError: true)
              else if (reading == null)
                const _StatusPanel(text: 'No sensor reading found.')
              else ...[
                _DevicePanel(reading: reading),
                const SizedBox(height: 16),
                _SensorGrid(reading: reading),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String updatedAt;
  final bool hasAlert;

  const _Header({required this.updatedAt, required this.hasAlert});

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
                'MQTT feed via HiveMQ and backend API',
                style: GoogleFonts.dmSans(color: const Color(0xFF8B949E), fontSize: 13),
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
              color: hasAlert ? const Color(0xFFFF6B6B) : const Color(0xFF00D4AA),
            ),
          ),
          child: Text(
            updatedAt,
            style: GoogleFonts.spaceMono(
              color: hasAlert ? const Color(0xFFFFB4B4) : const Color(0xFF75E6D0),
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

  const _DevicePanel({required this.reading});

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
                  'Reading #${reading.id}',
                  style: GoogleFonts.dmSans(color: const Color(0xFF8B949E), fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.circle, color: Color(0xFF00D4AA), size: 10),
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
      _SensorCardData('Temperature', reading.temperature, 'C', Icons.thermostat, const Color(0xFFFFB020), reading.temperature != null && reading.temperature! > 30),
      _SensorCardData('Humidity', reading.humidity, '%', Icons.water_drop_outlined, const Color(0xFF58A6FF), reading.humidity != null && reading.humidity! > 70),
      _SensorCardData('Gas Level', reading.gasLevel, 'ppm', Icons.air, const Color(0xFF9B59B6), reading.gasLevel != null && reading.gasLevel! > 400),
      _SensorCardData('Light Level', reading.lightLevel, 'lx', Icons.light_mode_outlined, const Color(0xFFFFD166), reading.lightLevel != null && reading.lightLevel! > 900),
      _SensorCardData('Distance', reading.distanceCm, 'cm', Icons.straighten, const Color(0xFF00D4AA), reading.distanceCm != null && reading.distanceCm! < 15),
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
          value: card.value == null ? '--' : card.value!.toStringAsFixed(1),
          unit: card.unit,
          icon: card.icon,
          color: card.color,
          isAlert: card.isAlert,
        );
      },
    );
  }
}

class _SensorCardData {
  final String label;
  final double? value;
  final String unit;
  final IconData icon;
  final Color color;
  final bool isAlert;

  const _SensorCardData(
    this.label,
    this.value,
    this.unit,
    this.icon,
    this.color,
    this.isAlert,
  );
}

class _StatusPanel extends StatelessWidget {
  final String text;
  final bool isError;

  const _StatusPanel({required this.text, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isError ? const Color(0xFFFF6B6B) : const Color(0xFF30363D)),
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
