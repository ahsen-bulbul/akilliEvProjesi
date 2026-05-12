import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

import '../../domain/entities/sensor_data.dart';
import '../models/sensor_data_model.dart';

class MqttSensorService {
  static const String broker = String.fromEnvironment('MQTT_BROKER');
  static const int port = int.fromEnvironment('MQTT_PORT', defaultValue: 8883);
  static const String username = String.fromEnvironment('MQTT_USERNAME');
  static const String password = String.fromEnvironment('MQTT_PASSWORD');
  static const String topic = String.fromEnvironment(
    'MQTT_TOPIC',
    defaultValue: 'ev/sensorler',
  );
  static const bool useTls = bool.fromEnvironment(
    'MQTT_TLS',
    defaultValue: true,
  );

  MqttServerClient? _client;
  StreamSubscription<List<MqttReceivedMessage<MqttMessage>>>? _updatesSub;
  final StreamController<SensorData> _controller =
      StreamController<SensorData>.broadcast();

  Stream<SensorData> get readings => _controller.stream;

  Future<void> connect() async {
    if (broker.isEmpty || username.isEmpty || password.isEmpty) {
      throw StateError(
        'MQTT config eksik. Flutter run komutuna MQTT_BROKER, MQTT_USERNAME ve MQTT_PASSWORD dart-define olarak verilmeli.',
      );
    }

    final clientId =
        'smart-home-mobile-${DateTime.now().millisecondsSinceEpoch}';
    final client = MqttServerClient(broker, clientId)
      ..port = port
      ..secure = useTls
      ..securityContext = SecurityContext.defaultContext
      ..keepAlivePeriod = 30
      ..autoReconnect = true
      ..resubscribeOnAutoReconnect = true
      ..logging(on: false)
      ..connectionMessage = MqttConnectMessage()
          .withClientIdentifier(clientId)
          .authenticateAs(username, password)
          .startClean();

    client.setProtocolV311();

    _client = client;

    final status = await client.connect();
    if (status?.state != MqttConnectionState.connected) {
      client.disconnect();
      throw StateError('MQTT baglantisi kurulamadi: ${status?.state}');
    }

    client.subscribe(topic, MqttQos.atLeastOnce);
    _updatesSub = client.updates?.listen(_handleMessages);
  }

  Future<void> disconnect() async {
    await _updatesSub?.cancel();
    _updatesSub = null;
    _client?.disconnect();
    _client = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _controller.close();
  }

  void _handleMessages(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final received in messages) {
      final message = received.payload;
      if (message is! MqttPublishMessage) {
        continue;
      }

      try {
        final payload = MqttPublishPayload.bytesToStringAsString(
          message.payload.message,
        );
        final json = jsonDecode(payload) as Map<String, dynamic>;
        _controller.add(SensorDataModel.fromMqttJson(json));
      } catch (e) {
        _controller.addError('MQTT mesaji okunamadi: $e');
      }
    }
  }
}
