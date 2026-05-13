import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class FirebaseService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;

  static String? _fcmToken;

  static Future<void> initialize() async {
    try {
      // Permission al
      await _firebaseMessaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      );

      // FCM token al
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Ön plan mesajları
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Token yenile
      _firebaseMessaging.onTokenRefresh.listen((token) {
        _fcmToken = token;
        debugPrint('FCM Token Refreshed: $token');
        _sendTokenToBackend(token);
      });

      // Token'ı backend'e gönder
      if (_fcmToken != null) {
        _sendTokenToBackend(_fcmToken!);
      }
    } catch (e) {
      debugPrint('Firebase initialize error: $e');
    }
  }

  static String? getToken() => _fcmToken;

  static Future<void> _sendTokenToBackend(String token) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/fcm-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM token sent to backend');
      } else {
        debugPrint('Failed to send FCM token: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error sending FCM token: $e');
    }
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
    }
  }
}
