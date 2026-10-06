// ============================================================
// lib/config/app_navigator.dart
// Global navigator key so services (FCM, Notifications) can
// push routes without needing a BuildContext.
// ============================================================
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();