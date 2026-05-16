import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/control_device.dart';
import '../../domain/entities/control_room.dart';
import '../../domain/entities/sensor_data.dart';
import '../models/sensor_data_model.dart';

class WeatherData {
  final String location;
  final double temperature;
  final double? apparentTemperature;
  final double? humidity;
  final double? windSpeed;
  final double? uvIndex;
  final String condition;
  final int? weatherCode;
  final bool? isDay;
  final DateTime? observedAt;

  const WeatherData({
    required this.location,
    required this.temperature,
    required this.condition,
    this.apparentTemperature,
    this.humidity,
    this.windSpeed,
    this.uvIndex,
    this.weatherCode,
    this.isDay,
    this.observedAt,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      location: json['location'] ?? 'Ev',
      temperature: (json['temperature'] as num).toDouble(),
      apparentTemperature: (json['apparent_temperature'] as num?)?.toDouble(),
      humidity: (json['humidity'] as num?)?.toDouble(),
      windSpeed: (json['wind_speed'] as num?)?.toDouble(),
      uvIndex: (json['uv_index'] as num?)?.toDouble(),
      condition: json['condition'] ?? 'Bilinmiyor',
      weatherCode: json['weather_code'],
      isDay: json['is_day'],
      observedAt: json['observed_at'] == null
          ? null
          : DateTime.tryParse(json['observed_at']),
    );
  }
}

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';

  static Map<String, String> get _headers {
    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    if (token == null) {
      throw StateError('Oturum bulunamadi. Lutfen tekrar giris yapin.');
    }
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static Future<SensorData> getLatestReading({int? sensorId}) async {
    final query = sensorId == null ? '' : '?sensor_id=$sensorId';
    final response = await http.get(
      Uri.parse('$baseUrl/sensors/latest$query'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return SensorDataModel.fromJson(jsonDecode(response.body));
    }
    throw Exception(_errorMessage('Veri alinamadi', response));
  }

  static Future<List<SensorData>> getSensorHistory({int limit = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/sensors?limit=$limit'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => SensorDataModel.fromJson(e)).toList();
    }
    throw Exception(_errorMessage('Gecmis alinamadi', response));
  }

  static Future<List<ControlDevice>> getDevices() async {
    final response = await http.get(
      Uri.parse('$baseUrl/devices'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => _deviceFromJson(e)).toList();
    }
    throw Exception(_errorMessage('Cihazlar alinamadi', response));
  }

  static Future<Map<String, dynamic>> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_errorMessage('Kullanici bilgisi alinamadi', response));
  }

  static Future<Map<String, dynamic>> createSensor(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/sensors'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_errorMessage('Sensor olusturulamadi', response));
  }

  static Future<Map<String, dynamic>> createDevice(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/devices'),
      headers: _headers,
      body: jsonEncode(payload),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception(_errorMessage('Cihaz olusturulamadi', response));
  }

  static Future<List<ControlRoom>> getRooms() async {
    final response = await http.get(
      Uri.parse('$baseUrl/rooms'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => _roomFromJson(e)).toList();
    }
    throw Exception(_errorMessage('Odalar alinamadi', response));
  }

  static Future<WeatherData> getCurrentWeather() async {
    final response = await http.get(
      Uri.parse('$baseUrl/weather/current'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return WeatherData.fromJson(jsonDecode(response.body));
    }
    throw Exception(_errorMessage('Hava durumu alinamadi', response));
  }

  static Future<void> sendControl({
    required int targetId,
    String targetType = 'device',
    required String action,
    String? value,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/control'),
      headers: _headers,
      body: jsonEncode({
        'target_type': targetType,
        'target_id': targetId,
        'action': action,
        'value': value,
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception(_errorMessage('Komut gonderilemedi', response));
    }
  }

  static String _errorMessage(String message, http.Response response) {
    final body = response.body.trim();
    if (body.isEmpty) {
      return '$message: ${response.statusCode}';
    }
    return '$message: ${response.statusCode} - $body';
  }

  static ControlRoom _roomFromJson(Map<String, dynamic> json) {
    return ControlRoom(id: json['id'], name: json['name']);
  }

  static ControlDevice _deviceFromJson(Map<String, dynamic> json) {
    return ControlDevice(
      id: json['id'],
      roomId: json['room_id'],
      name: json['device_name'],
      type: json['device_type'],
      status: json['status'] ?? false,
    );
  }
}
