import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/sensor_data.dart';
import '../models/sensor_data_model.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  static Future<SensorData> getLatestReading({
    String deviceId = 'Ankara-RPi-01',
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sensors/latest?device_id=$deviceId'),
    );
    if (response.statusCode == 200) {
      return SensorDataModel.fromJson(jsonDecode(response.body));
    }
    throw Exception('Veri alinamadi: ${response.statusCode}');
  }

  static Future<List<SensorData>> getSensorHistory({int limit = 20}) async {
    final response = await http.get(Uri.parse('$baseUrl/sensors?limit=$limit'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => SensorDataModel.fromJson(e)).toList();
    }
    throw Exception('Gecmis alinamadi');
  }

  static Future<void> sendControl(
    String deviceId,
    String action, {
    String? value,
  }) async {
    await http.post(
      Uri.parse('$baseUrl/control'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'device_id': deviceId,
        'action': action,
        'value': value,
      }),
    );
  }
}
