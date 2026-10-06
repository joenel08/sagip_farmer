import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

// ============================================================
// BACKGROUND HANDLER — must be top-level + @pragma('vm:entry-point')
// Runs when app is terminated or in background.
// ============================================================
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM-BG] ${message.messageId} — ${message.notification?.title}');
  // Android auto-displays the notification for "notification" payloads.
}

// ============================================================
// SERVICE
// ============================================================
class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  // ---- Foreground message stream (UI can listen to it) ----
  static final StreamController<RemoteMessage> _foregroundController =
      StreamController<RemoteMessage>.broadcast();

  /// Listen to this in your home screen to show a SnackBar.
  static Stream<RemoteMessage> get foregroundMessages =>
      _foregroundController.stream;

  // ============================================================
  // INIT — call once from main()
  // ============================================================
  static Future<void> init() async {
    if (_initialized) return;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] permission: ${settings.authorizationStatus}');

    // iOS: no need to present in foreground — we handle it in-app
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );

    // Foreground messages → push into the stream
    FirebaseMessaging.onMessage.listen((msg) {
      debugPrint('[FCM-FG] ${msg.messageId}');
      _foregroundController.add(msg);
    });

    // User tapped a push notification (app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // App opened from terminated state via a tap
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _onNotificationTap(initial);

    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] token refreshed: $newToken');
    });

    _initialized = true;
  }

  static void _onNotificationTap(RemoteMessage message) {
    debugPrint('[FCM-TAP] data = ${message.data}');
    // Optionally navigate using a global navigator key.
  }

  // ============================================================
  // TOKEN
  // ============================================================
  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      debugPrint('[FCM] token: $token');
      return token;
    } catch (e) {
      debugPrint('[FCM] getToken error: $e');
      return null;
    }
  }

  static Future<void> registerTokenForUser(int userId) async {
    final token = await getToken();
    if (token == null) {
      debugPrint('[FCM] no token — cannot register');
      return;
    }
    await _sendTokenToServer(userId, token);
  }

  static Future<void> _sendTokenToServer(int userId, String token) async {
    try {
      final r = await http
          .post(
            Uri.parse(ApiConfig.saveToken),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'user_id': userId, 'fcm_token': token}),
          )
          .timeout(const Duration(seconds: 15));
      debugPrint('[FCM] save response: ${r.body}');
    } catch (e) {
      debugPrint('[FCM] save failed: $e');
    }
  }

  static Future<void> unregisterToken(int userId) async {
    try {
      final token = await _messaging.getToken();
      await http
          .post(
            Uri.parse(ApiConfig.clearToken),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'user_id': userId,
              'fcm_token': token ?? '',
            }),
          )
          .timeout(const Duration(seconds: 15));
      debugPrint('[FCM] token cleared');
    } catch (e) {
      debugPrint('[FCM] clear failed: $e');
    }
  }
}