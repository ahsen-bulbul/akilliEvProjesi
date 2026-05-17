import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/sensor_alarm_log.dart';
import '../viewmodels/firebase_alarm_log_view_model.dart';

class CameraEventLogScreen extends StatelessWidget {
  const CameraEventLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FirebaseAlarmLogViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: Text(
          'Kamera Olay Kaydi',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<SensorAlarmLog>>(
        stream: viewModel.watchAlarmLogs(limit: 100),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _StatusText('Olay kaydi alinamadi: ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D4AA)),
            );
          }

          final events = (snapshot.data ?? const <SensorAlarmLog>[])
              .where(_isCameraEvent)
              .toList();
          if (events.isEmpty) {
            return const _StatusText(
              'Henuz kamera olayi yok. Hareket veya buzzer alarmi geldiginde burada gorunecek.',
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            itemCount: events.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _CameraEventCard(log: events[index]),
              );
            },
          );
        },
      ),
    );
  }

  bool _isCameraEvent(SensorAlarmLog log) {
    return log.labels.any((label) {
      final value = label.toLowerCase();
      return value.contains('motion') ||
          value.contains('hareket') ||
          value.contains('buzzer');
    });
  }
}

class _CameraEventCard extends StatelessWidget {
  final SensorAlarmLog log;

  const _CameraEventCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd.MM.yyyy HH:mm:ss').format(log.createdAt);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.videocam_outlined,
              color: Color(0xFFFF6B6B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.labels.join(', '),
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${log.deviceId} - $date',
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
}

class _StatusText extends StatelessWidget {
  final String text;

  const _StatusText(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(color: const Color(0xFF8B949E)),
        ),
      ),
    );
  }
}
