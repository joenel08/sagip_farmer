// ============================================================
// lib/services/fcm_service.dart
// ============================================================
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

// ============================================================
// BACKGROUND HANDLER — must be top-level + @pragma
// Runs when app is terminated or backgrounded.
// ============================================================
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM-BG] ${message.messageId}');

  final isEmergency = message.data['is_emergency'] == 'true';

  if (isEmergency) {
    await _showEmergencyOverlay(
      title: message.notification?.title ?? '🚨 Emergency Alert',
      body: message.notification?.body ?? 'Check your farm immediately!',
    );
  } else {
    debugPrint('[FCM-BG] standard notif — Android displays automatically');
  }
}

// ============================================================
// SHARED HELPER — used by both background and foreground
// ============================================================
Future<void> _showEmergencyOverlay({
  required String title,
  required String body,
}) async {
  try {
    // 1. Check overlay permission
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      debugPrint('[Overlay] no permission, requesting…');
      await FlutterOverlayWindow.requestPermission();
      // Re-check after request
      if (!await FlutterOverlayWindow.isPermissionGranted()) {
        debugPrint('[Overlay] permission still not granted — aborting');
        return;
      }
    }

    // 2. Close any existing overlay
    if (await FlutterOverlayWindow.isActive()) {
      await FlutterOverlayWindow.closeOverlay();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    // 3. Show the overlay
    await FlutterOverlayWindow.showOverlay(
      height: WindowSize.fullCover,
      width: WindowSize.matchParent,
      flag: OverlayFlag.focusPointer,
      overlayTitle: 'SAGIPfarmer Alert',
      overlayContent: 'Emergency alert',
    );

    // 4. Send the payload so the overlay UI can render it
    await FlutterOverlayWindow.shareData({
      'title': title,
      'body': body,
    });

    debugPrint('[Overlay] emergency shown: $title');
  } catch (e) {
    debugPrint('[Overlay] show failed: $e');
  }
}

// ============================================================
// FCM SERVICE
// ============================================================
class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static bool _initialized = false;

  // ============================================================
  // INIT
  // ============================================================
  static Future<void> init() async {
    if (_initialized) return;

    // Register the background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Ask permission (iOS + Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] permission: ${settings.authorizationStatus}');

    // iOS: show in foreground too
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground listener
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    // User tapped a notification while app was backgrounded
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);

    // App opened from terminated state by tapping a notification
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _onNotificationTap(initial);

    // Token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] token refreshed: $newToken');
      // Optionally re-save here if you cache the userId
    });

    _initialized = true;
    debugPrint('[FCM] init complete');
  }

  // ============================================================
  // FOREGROUND MESSAGE HANDLER
  // ============================================================
  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    debugPrint('[FCM-FG] ${message.messageId}');

    final isEmergency = message.data['is_emergency'] == 'true';
    final notif = message.notification;

    if (isEmergency) {
      // Show the same modal overlay in foreground
      await _showEmergencyOverlay(
        title: notif?.title ?? '🚨 Emergency Alert',
        body: notif?.body ?? 'Check your farm immediately!',
      );
    } else {
      // Standard notification — Android handles it automatically
      debugPrint('[FCM-FG] standard notif — no action needed');
    }
  }

  // ============================================================
  // NOTIFICATION TAP HANDLER
  // ============================================================
  static void _onNotificationTap(RemoteMessage message) {
    debugPrint('[FCM-TAP] ${message.data}');

    // If the user tapped an emergency notification while app was closed,
    // the app opens here. We can also trigger the overlay just in case.
    if (message.data['is_emergency'] == 'true') {
      _showEmergencyOverlay(
        title: message.notification?.title ?? '🚨 Emergency Alert',
        body: message.notification?.body ?? 'Check your farm immediately!',
      );
    }
  }

  // ============================================================
  // TOKEN
  // ============================================================
  static Future<String?> getToken() async {
    try {
      final t = await _messaging.getToken();
      debugPrint('[FCM] token: $t');
      return t;
    } catch (e) {
      debugPrint('[FCM] getToken error: $e');
      return null;
    }
  }

  /// Call after successful login.
  static Future<void> registerTokenForUser(int userId) async {
    final token = await getToken();
    if (token == null) {
      debugPrint('[FCM] no token — cannot register');
      return;
    }
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

  /// Call on logout.
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