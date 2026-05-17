import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/api_config.dart';
import '../../domain/entities/control_device.dart';
import '../../domain/entities/control_room.dart';
import '../../domain/entities/sensor_data.dart';
import '../models/message.dart';
import '../models/sensor_data_model.dart';

class AppUser {
  final String id;
  final String? email;
  final String? username;
  final bool isAdmin;

  const AppUser({
    required this.id,
    this.email,
    this.username,
    required this.isAdmin,
  });

  String get shortId => id.length <= 8 ? id : id.substring(0, 8);
  String get displayName {
    final cleanUsername = username?.trim();
    if (cleanUsername != null && cleanUsername.isNotEmpty) {
      return cleanUsername;
    }

    final cleanEmail = email?.trim();
    if (cleanEmail != null && cleanEmail.isNotEmpty) {
      return cleanEmail;
    }

    return shortId;
  }

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      username: json['username'] as String?,
      isAdmin: json['is_admin'] == true,
    );
  }
}

class SensorDefinition {
  final int id;
  final String userId;
  final int? roomId;
  final String name;
  final String type;
  final bool active;

  const SensorDefinition({
    required this.id,
    required this.userId,
    required this.roomId,
    required this.name,
    required this.type,
    required this.active,
  });

  factory SensorDefinition.fromJson(Map<String, dynamic> json) {
    return SensorDefinition(
      id: json['id'] as int,
      userId: json['user_id'] as String,
      roomId: json['room_id'] as int?,
      name: json['sensor_name'] as String,
      type: json['sensor_type'] as String,
      active: json['active'] == true,
    );
  }
}

class SetupStatus {
  final bool isConfigured;
  final int roomCount;
  final int deviceCount;
  final int sensorCount;
  final String? packageId;
  final String? homeCity;

  const SetupStatus({
    required this.isConfigured,
    required this.roomCount,
    required this.deviceCount,
    required this.sensorCount,
    this.packageId,
    this.homeCity,
  });

  factory SetupStatus.fromJson(Map<String, dynamic> json) {
    return SetupStatus(
      isConfigured: json['is_configured'] == true,
      roomCount: json['room_count'] ?? 0,
      deviceCount: json['device_count'] ?? 0,
      sensorCount: json['sensor_count'] ?? 0,
      packageId: json['package_id'] as String?,
      homeCity: json['home_city'] as String?,
    );
  }
}

class SetupPackageResult {
  final String packageId;
  final String homeCity;
  final int roomCount;
  final int deviceCount;
  final int sensorCount;

  const SetupPackageResult({
    required this.packageId,
    required this.homeCity,
    required this.roomCount,
    required this.deviceCount,
    required this.sensorCount,
  });

  factory SetupPackageResult.fromJson(Map<String, dynamic> json) {
    return SetupPackageResult(
      packageId: json['package_id'],
      homeCity: json['home_city'],
      roomCount: json['room_count'] ?? 0,
      deviceCount: json['device_count'] ?? 0,
      sensorCount: json['sensor_count'] ?? 0,
    );
  }
}

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
  static const String baseUrl = ApiConfig.baseUrl;

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

  static Future<AppUser> getMe() async {
    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return AppUser.fromJson(jsonDecode(response.body));
    }
    throw Exception(_errorMessage('Kullanici bilgisi alinamadi', response));
  }

  static Future<SetupStatus> getSetupStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/setup/status'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return SetupStatus.fromJson(jsonDecode(response.body));
    }
    throw Exception(_errorMessage('Kurulum durumu alinamadi', response));
  }

  static Future<SetupPackageResult> applySetupPackage({
    required String packageId,
    required String homeCity,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/setup/package'),
      headers: _headers,
      body: jsonEncode({'package_id': packageId, 'home_city': homeCity}),
    );
    if (response.statusCode == 200) {
      return SetupPackageResult.fromJson(jsonDecode(response.body));
    }
    throw Exception(_errorMessage('Paket uygulanamadi', response));
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

  static Future<List<SensorDefinition>> getSensorDefinitions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/sensor-definitions'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => SensorDefinition.fromJson(e)).toList();
    }
    throw Exception(_errorMessage('Sensorler alinamadi', response));
  }

  static Future<List<AppUser>> getAdminUsers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => AppUser.fromJson(e)).toList();
    }
    throw Exception(_errorMessage('Kullanicilar alinamadi', response));
  }

  static Future<void> deleteAdminUser(String userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/users/$userId'),
      headers: _headers,
    );
    if (response.statusCode >= 400) {
      throw Exception(_errorMessage('Kullanici silinemedi', response));
    }
  }

  static Future<List<ControlRoom>> getAdminRooms(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users/$userId/rooms'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => _roomFromJson(e)).toList();
    }
    throw Exception(_errorMessage('Admin odalari alinamadi', response));
  }

  static Future<List<ControlDevice>> getAdminDevices(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users/$userId/devices'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => _deviceFromJson(e)).toList();
    }
    throw Exception(_errorMessage('Admin cihazlari alinamadi', response));
  }

  static Future<List<SensorDefinition>> getAdminSensors(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/users/$userId/sensors'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => SensorDefinition.fromJson(e)).toList();
    }
    throw Exception(_errorMessage('Admin sensorleri alinamadi', response));
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

  static Future<List<Message>> getChatMessages({String? targetUserId}) async {
    final query = targetUserId == null ? '' : '?target_user_id=$targetUserId';
    final response = await http.get(
      Uri.parse('$baseUrl/chat/messages$query'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((e) => Message.fromJson(e)).toList();
    }
    throw Exception(_errorMessage('Mesajlar alinamadi', response));
  }

  static Future<Message> sendChatMessage({
    required String text,
    String? targetUserId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat/messages'),
      headers: _headers,
      body: jsonEncode({'text': text, 'target_user_id': targetUserId}),
    );
    if (response.statusCode == 200) {
      return Message.fromJson(jsonDecode(response.body));
    }
    throw Exception(_errorMessage('Mesaj gonderilemedi', response));
  }

  static Future<ControlRoom> createAdminRoom({
    required String targetUserId,
    required String name,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/rooms'),
      headers: _headers,
      body: jsonEncode({'target_user_id': targetUserId, 'name': name}),
    );
    if (response.statusCode == 200) {
      return _roomFromJson(jsonDecode(response.body));
    }
    throw Exception(_errorMessage('Oda olusturulamadi', response));
  }

  static Future<ControlDevice> createAdminDevice({
    required String targetUserId,
    required String name,
    required String type,
    int? roomId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/devices'),
      headers: _headers,
      body: jsonEncode({
        'target_user_id': targetUserId,
        'device_name': name,
        'device_type': type,
        'room_id': roomId,
      }),
    );
    if (response.statusCode == 200) {
      return _deviceFromJson(jsonDecode(response.body));
    }
    throw Exception(_errorMessage('Cihaz olusturulamadi', response));
  }

  static Future<SensorDefinition> createAdminSensor({
    required String targetUserId,
    required String name,
    required String type,
    int? roomId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/admin/sensors'),
      headers: _headers,
      body: jsonEncode({
        'target_user_id': targetUserId,
        'sensor_name': name,
        'sensor_type': type,
        'room_id': roomId,
        'active': true,
      }),
    );
    if (response.statusCode == 200) {
      return SensorDefinition.fromJson(jsonDecode(response.body));
    }
    throw Exception(_errorMessage('Sensor olusturulamadi', response));
  }

  static Future<void> deleteAdminRoom({
    required String targetUserId,
    required int roomId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/rooms/$roomId?target_user_id=$targetUserId'),
      headers: _headers,
    );
    if (response.statusCode >= 400) {
      throw Exception(_errorMessage('Oda silinemedi', response));
    }
  }

  static Future<void> deleteAdminDevice({
    required String targetUserId,
    required int deviceId,
  }) async {
    final response = await http.delete(
      Uri.parse(
        '$baseUrl/admin/devices/$deviceId?target_user_id=$targetUserId',
      ),
      headers: _headers,
    );
    if (response.statusCode >= 400) {
      throw Exception(_errorMessage('Cihaz silinemedi', response));
    }
  }

  static Future<void> deleteAdminSensor({
    required String targetUserId,
    required int sensorId,
  }) async {
    final response = await http.delete(
      Uri.parse(
        '$baseUrl/admin/sensors/$sensorId?target_user_id=$targetUserId',
      ),
      headers: _headers,
    );
    if (response.statusCode >= 400) {
      throw Exception(_errorMessage('Sensor silinemedi', response));
    }
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
