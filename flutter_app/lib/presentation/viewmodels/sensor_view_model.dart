import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/services/notification_service.dart';
import '../../domain/entities/sensor_data.dart';
import '../../domain/entities/sensor_threshold.dart';
import '../../domain/repositories/firebase_event_repository.dart';
import '../../domain/repositories/sensor_repository.dart';

class SensorViewModel extends ChangeNotifier {
  SensorViewModel(this._repository, {FirebaseEventRepository? eventRepository})
    : _eventRepository = eventRepository;

  static const thresholds = [
    SensorThreshold(
      key: 'temperature',
      label: 'Temperature',
      max: 30,
      unit: 'C',
    ),
    SensorThreshold(key: 'humidity', label: 'Humidity', max: 70, unit: '%'),
    SensorThreshold(key: 'gas', label: 'Gas Level', max: 400, unit: 'ppm'),
    SensorThreshold(
      key: 'soil',
      label: 'Soil Moisture',
      min: 20,
      max: 80,
      unit: '%',
    ),
  ];

  final SensorRepository _repository;
  final FirebaseEventRepository? _eventRepository;

  SensorData? _latest;
  StreamSubscription<SensorData>? _liveSubscription;
  Timer? _cacheFallbackTimer;
  bool _loading = false;
  bool _showingCachedData = false;
  String? _error;
  int? _lastNotifiedReadingId;
  String? _lastSystemNotificationKey;
  DateTime? _lastSystemNotificationAt;
  int _alertVersion = 0;
  List<String> _lastAlertLabels = const [];

  SensorData? get latest => _latest;
  bool get loading => _loading;
  bool get showingCachedData => _showingCachedData;
  String? get error => _error;
  int get alertVersion => _alertVersion;
  List<String> get lastAlertLabels => _lastAlertLabels;

  bool get hasAlert => _latest != null && alertLabels(_latest!).isNotEmpty;

  Future<void> connectLiveReadings() async {
    _loading = true;
    _error = null;
    _showingCachedData = false;
    notifyListeners();

    try {
      _cacheFallbackTimer?.cancel();
      await _liveSubscription?.cancel();
      await _repository.disconnectLiveReadings();
      _liveSubscription = _repository.liveReadings.listen(
        _handleReading,
        onError: (error) => unawaited(_loadCachedReading(error.toString())),
      );
      await _repository.connectLiveReadings();
      _cacheFallbackTimer = Timer(const Duration(seconds: 4), () {
        if (_latest == null) {
          unawaited(
            _loadCachedReading('MQTT baglandi ama henuz canli veri gelmedi.'),
          );
        }
      });
      _error = null;
      notifyListeners();
    } catch (e) {
      await _loadCachedReading(e.toString());
    }
  }

  void _handleReading(SensorData reading) {
    _cacheFallbackTimer?.cancel();
    _latest = reading;
    _loading = false;
    _error = null;
    _showingCachedData = false;
    notifyListeners();

    unawaited(_repository.cacheReading(reading));
    _notifyIfNeeded(reading);
  }

  Future<void> _loadCachedReading(String reason) async {
    try {
      final cached = await _repository.getCachedLatestReading();
      if (cached == null) {
        throw StateError('Cache empty');
      }
      _latest = cached;
      _loading = false;
      _showingCachedData = true;
      _error = 'Live MQTT unavailable. Showing cached data. $reason';
    } catch (_) {
      _loading = false;
      _showingCachedData = false;
      _error =
          'Live MQTT unavailable and no cached sensor reading was found. $reason';
    }
    notifyListeners();
  }

  void _notifyIfNeeded(SensorData reading) {
    final alerts = alertLabels(reading);
    if (alerts.isEmpty || _lastNotifiedReadingId == reading.id) {
      return;
    }
    _lastNotifiedReadingId = reading.id;
    _lastAlertLabels = alerts;
    _alertVersion++;
    notifyListeners();
    unawaited(_eventRepository?.addAlarmLog(reading: reading, labels: alerts));

    final key = alerts.join('|');
    final now = DateTime.now();
    final lastAt = _lastSystemNotificationAt;
    if (_lastSystemNotificationKey == key &&
        lastAt != null &&
        now.difference(lastAt) < const Duration(seconds: 60)) {
      return;
    }

    _lastSystemNotificationKey = key;
    _lastSystemNotificationAt = now;
    NotificationService.showSensorAlert(alerts);
  }

  List<String> alertLabels(SensorData reading) {
    return thresholds
        .where(
          (threshold) =>
              threshold.isExceeded(_valueFor(reading, threshold.key)),
        )
        .map((threshold) => threshold.label)
        .toList();
  }

  double? _valueFor(SensorData reading, String key) {
    return switch (key) {
      'temperature' => reading.temperature,
      'humidity' => reading.humidity,
      'gas' => reading.gasLevel,
      'soil' => reading.soilMoisture,
      _ => null,
    };
  }

  @override
  void dispose() {
    _cacheFallbackTimer?.cancel();
    _liveSubscription?.cancel();
    _repository.dispose();
    super.dispose();
  }
}
