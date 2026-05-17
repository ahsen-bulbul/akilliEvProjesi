import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/services/notification_settings_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late Future<Map<String, bool>> _settingsFuture;
  Map<String, bool> _settings = const {};

  @override
  void initState() {
    super.initState();
    _settingsFuture = _load();
  }

  Future<Map<String, bool>> _load() async {
    final settings = await NotificationSettingsService.loadSettings();
    _settings = settings;
    return settings;
  }

  Future<void> _setEnabled(String key, bool enabled) async {
    setState(() => _settings = {..._settings, key: enabled});
    await NotificationSettingsService.setEnabled(key, enabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1117),
        title: Text(
          'Bildirim Ayarlari',
          style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<Map<String, bool>>(
        future: _settingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D4AA)),
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              Text(
                'Kapattigin alarm tipleri uygulama icinde loglanmaya devam eder, sadece telefon bildirimi gonderilmez.',
                style: GoogleFonts.dmSans(
                  color: const Color(0xFF8B949E),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              for (final option in NotificationSettingsService.options)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _SettingTile(
                    option: option,
                    enabled: _settings[option.key] ?? true,
                    onChanged: (enabled) => _setEnabled(option.key, enabled),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  final NotificationSettingOption option;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _SettingTile({
    required this.option,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: Row(
        children: [
          Icon(_iconFor(option.key), color: const Color(0xFF00D4AA)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.label,
                  style: GoogleFonts.dmSans(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  option.description,
                  style: GoogleFonts.dmSans(
                    color: const Color(0xFF8B949E),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            activeThumbColor: const Color(0xFF00D4AA),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  IconData _iconFor(String key) {
    return switch (key) {
      'temperature' => Icons.thermostat,
      'humidity' => Icons.water_drop_outlined,
      'gas' => Icons.air,
      'soil' => Icons.grass_outlined,
      'motion' => Icons.directions_run,
      'buzzer' => Icons.notifications_active_outlined,
      _ => Icons.notifications_outlined,
    };
  }
}
