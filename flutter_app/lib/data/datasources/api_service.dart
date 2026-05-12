import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/sensor_data.dart';
import '../models/sensor_data_model.dart';

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

  static Future<List<DeviceSummary>> getDevices() async {
    final response = await http.get(
      Uri.parse('$baseUrl/devices'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => DeviceSummary.fromJson(e)).toList();
    }
    throw Exception(_errorMessage('Cihazlar alinamadi', response));
  }

  static Future<List<RoomSummary>> getRooms() async {
    final response = await http.get(
      Uri.parse('$baseUrl/rooms'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => RoomSummary.fromJson(e)).toList();
    }
    throw Exception(_errorMessage('Odalar alinamadi', response));
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
}

class RoomSummary {
  final int id;
  final String name;

  const RoomSummary({required this.id, required this.name});

  factory RoomSummary.fromJson(Map<String, dynamic> json) {
    return RoomSummary(id: json['id'], name: json['name']);
  }
}

class DeviceSummary {
  final int id;
  final int? roomId;
  final String name;
  final String type;
  final bool status;

  const DeviceSummary({
    required this.id,
    required this.roomId,
    required this.name,
    required this.type,
    required this.status,
  });

  DeviceSummary copyWith({bool? status}) {
    return DeviceSummary(
      id: id,
      roomId: roomId,
      name: name,
      type: type,
      status: status ?? this.status,
    );
  }

  factory DeviceSummary.fromJson(Map<String, dynamic> json) {
    return DeviceSummary(
      id: json['id'],
      roomId: json['room_id'],
      name: json['device_name'],
      type: json['device_type'],
      status: json['status'] ?? false,
    );
  }
}
