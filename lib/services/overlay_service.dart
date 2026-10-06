// lib/services/overlay_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

class OverlayService {
  /// Ask the user for overlay permission (Android only).
  static Future<bool> requestPermission() async {
    if (!await FlutterOverlayWindow.isPermissionGranted()) {
      await FlutterOverlayWindow.requestPermission();
    }
    return FlutterOverlayWindow.isPermissionGranted();
  }

  /// Show the emergency overlay across the whole screen.
  static Future<void> showEmergency({
    required String title,
    required String body,
  }) async {
    try {
      final hasPerm = await requestPermission();
      if (!hasPerm) {
        debugPrint('[Overlay] permission not granted');
        return;
      }

      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
        await Future.delayed(const Duration(milliseconds: 200));
      }

      await FlutterOverlayWindow.showOverlay(
        height: WindowSize.fullCover,
        width: WindowSize.matchParent,
        flag: OverlayFlag.focusPointer,
        overlayTitle: 'SAGIPfarmer Alert',
        overlayContent: 'Emergency alert',
      );

      await FlutterOverlayWindow.shareData({
        'title': title,
        'body': body,
      });
    } catch (e) {
      debugPrint('[Overlay] show failed: $e');
    }
  }

  static Future<void> close() async {
    try {
      if (await FlutterOverlayWindow.isActive()) {
        await FlutterOverlayWindow.closeOverlay();
      }
    } catch (_) {}
  }
}