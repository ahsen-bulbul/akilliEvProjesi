import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingOption {
  final String key;
  final String label;
  final String description;

  const NotificationSettingOption({
    required this.key,
    required this.label,
    required this.description,
  });
}

class NotificationSettingsService {
  static const options = [
    NotificationSettingOption(
      key: 'temperature',
      label: 'Temperature',
      description: 'Sicaklik esik disina cikinca bildir.',
    ),
    NotificationSettingOption(
      key: 'humidity',
      label: 'Humidity',
      description: 'Nem yuksek oldugunda bildir.',
    ),
    NotificationSettingOption(
      key: 'gas',
      label: 'Gas Level',
      description: 'MQ9 gaz seviyesi tehlikeli oldugunda bildir.',
    ),
    NotificationSettingOption(
      key: 'soil',
      label: 'Soil Moisture',
      description: 'Toprak nemi kritik araliga girince bildir.',
    ),
    NotificationSettingOption(
      key: 'motion',
      label: 'Motion',
      description: 'HW-416 hareket algiladiginda bildir.',
    ),
    NotificationSettingOption(
      key: 'buzzer',
      label: 'Buzzer',
      description: 'Buzzer aktif oldugunda bildir.',
    ),
  ];

  static const _prefix = 'notification_alert_';

  static Future<Map<String, bool>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final option in options)
        option.key: prefs.getBool('$_prefix${option.key}') ?? true,
    };
  }

  static Future<void> setEnabled(String key, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$key', enabled);
  }

  static Future<List<String>> filterEnabledAlerts(List<String> alerts) async {
    final settings = await loadSettings();
    return alerts.where((alert) {
      final key = _keyForAlertLabel(alert);
      return key == null || settings[key] == true;
    }).toList();
  }

  static String? _keyForAlertLabel(String label) {
    return switch (label) {
      'Temperature' => 'temperature',
      'Humidity' => 'humidity',
      'Gas Level' => 'gas',
      'Soil Moisture' => 'soil',
      'Motion' => 'motion',
      'Buzzer' => 'buzzer',
      _ => null,
    };
  }
}
