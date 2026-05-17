import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/sensor_alarm_log.dart';
import '../viewmodels/firebase_alarm_log_view_model.dart';

class AlarmHistoryScreen extends StatelessWidget {
  const AlarmHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<FirebaseAlarmLogViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: Text(
          'Alarm Gecmisi',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<List<SensorAlarmLog>>(
        stream: viewModel.watchAlarmLogs(limit: 100),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _StatusText('Alarm gecmisi alinamadi: ${snapshot.error}');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D4AA)),
            );
          }

          final logs = snapshot.data ?? const [];
          if (logs.isEmpty) {
            return const _StatusText('Henuz alarm kaydi yok.');
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _AlarmLogCard(log: logs[index]),
              );
            },
          );
        },
      ),
    );
  }
}

class _AlarmLogCard extends StatelessWidget {
  final SensorAlarmLog log;

  const _AlarmLogCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('dd.MM.yyyy HH:mm:ss').format(log.createdAt);
    final values = [
      if (log.temperature != null) 'Sicaklik ${log.temperature!.toStringAsFixed(1)} C',
      if (log.humidity != null) 'Nem ${log.humidity!.toStringAsFixed(1)}%',
      if (log.gasLevel != null) 'Gaz ${log.gasLevel!.toStringAsFixed(1)}',
      if (log.soilMoisture != null)
        'Toprak ${log.soilMoisture!.toStringAsFixed(1)}%',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: Color(0xFFFF6B6B)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  log.labels.join(', '),
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${log.deviceId} - sensor #${log.sensorId} - reading #${log.readingId}',
            style: GoogleFonts.spaceMono(
              color: const Color(0xFF8B949E),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: GoogleFonts.dmSans(
              color: const Color(0xFF8B949E),
              fontSize: 12,
            ),
          ),
          if (values.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              values.join('  |  '),
              style: GoogleFonts.dmSans(
                color: const Color(0xFFC9D1D9),
                fontSize: 12,
              ),
            ),
          ],
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
