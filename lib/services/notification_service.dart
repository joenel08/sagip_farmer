// ============================================================
// lib/services/notification_service.dart
// ============================================================
import 'dart:convert';          // ← for jsonDecode
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';   // ← for MaterialPageRoute
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;

import '../config/app_navigator.dart';    // ← for appNavigatorKey
import '../screens/full_screen_alert.dart'; // ← for FullScreenAlert

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ─── CHANNEL IDS ───
  static const String alertChannelId = 'sagipfarmer_alerts';
  static const String alertChannelName = 'Farm Alerts';
  static const String alertChannelDesc =
      'Notifications about water level and soil moisture.';

  static const String emergencyChannelId = 'sagipfarmer_emergency';
  static const String emergencyChannelName = 'Emergency Alerts';
  static const String emergencyChannelDesc =
      'Critical alerts that require immediate attention.';

  // ─── VIBRATION PATTERN (~12 seconds) ───
  static final Int64List _longVibrate = Int64List.fromList([
    0,    800,
    400,  800,
    400,  800,
    400,  800,
    400,  800,
    400,  800,
    400,  800,
    400,  800,
    400,  800,
    400,  800,
  ]);

  static const int emergencyNotificationId = 999;

  // ═══════════════════════════════════════════════════════════
  // INIT
  // ═══════════════════════════════════════════════════════════
  static Future<void> init() async {
    if (_initialized) {
      debugPrint('[Notif] already initialized');
      return;
    }

    tz_data.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _handleTap,
    );

    if (Platform.isAndroid) {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          alertChannelId,
          alertChannelName,
          description: alertChannelDesc,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );
      debugPrint('[Notif] channel created: $alertChannelId');

      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          emergencyChannelId,
          emergencyChannelName,
          description: emergencyChannelDesc,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: _longVibrate,
        ),
      );
      debugPrint('[Notif] channel created: $emergencyChannelId');

      await android?.requestNotificationsPermission();
    }

    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
    debugPrint('[Notif] init complete');
  }

  // ═══════════════════════════════════════════════════════════
  // NOTIFICATION TAP HANDLER
  // ═══════════════════════════════════════════════════════════
  static void _handleTap(NotificationResponse response) {
    debugPrint('[Notif] tapped: ${response.payload}');
    if (response.payload == null) return;

    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;

      if (data['is_emergency'] == 'true') {
        final title = data['title']?.toString() ?? 'Emergency Alert';
        final body  = data['body']?.toString()
            ?? 'Check your farm immediately!';

        appNavigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => FullScreenAlert(title: title, body: body),
          ),
        );
      }
    } catch (e) {
      debugPrint('[Notif] payload parse error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // STANDARD NOTIFICATION
  // ═══════════════════════════════════════════════════════════
  static Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool highPriority = true,
  }) async {
    if (!_initialized) await init();

    final androidDetails = AndroidNotificationDetails(
      alertChannelId,
      alertChannelName,
      channelDescription: alertChannelDesc,
      importance:
          highPriority ? Importance.high : Importance.defaultImportance,
      priority: highPriority ? Priority.high : Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: payload,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // EMERGENCY ALERT (full-screen style)
  // ═══════════════════════════════════════════════════════════
  static Future<void> showEmergencyAlert({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();

    // Build a JSON payload that _handleTap can parse later
    final effectivePayload = payload ??
        jsonEncode({
          'is_emergency': 'true',
          'title': title,
          'body': body,
        });

    final androidDetails = AndroidNotificationDetails(
      emergencyChannelId,
      emergencyChannelName,
      channelDescription: emergencyChannelDesc,
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
      vibrationPattern: _longVibrate,
      ongoing: true,
      autoCancel: false,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    await _plugin.show(
      emergencyNotificationId,
      title,
      body,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: effectivePayload,
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CANCEL
  // ═══════════════════════════════════════════════════════════
  static Future<void> cancelEmergency() async {
    await _plugin.cancel(emergencyNotificationId);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);
}