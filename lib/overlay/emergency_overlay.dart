// lib/overlay/emergency_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

/// This is the entry point for the overlay. Flutter will run this
/// when the overlay is shown.
@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: _EmergencyOverlayScreen(),
  ));
}

class _EmergencyOverlayScreen extends StatefulWidget {
  const _EmergencyOverlayScreen();
  @override
  State<_EmergencyOverlayScreen> createState() => _EmergencyOverlayScreenState();
}

class _EmergencyOverlayScreenState extends State<_EmergencyOverlayScreen> {
  String _title = 'Emergency Alert';
  String _body = 'Check your farm immediately!';

  @override
  void initState() {
    super.initState();
    // Listen for data sent from your FCM handler
    FlutterOverlayWindow.overlayListener.listen((event) {
      if (event is Map) {
        setState(() {
          _title = event['title'] ?? _title;
          _body = event['body'] ?? _body;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withOpacity(0.8), // Semi-transparent background
      child: Center(
        child: Card(
          elevation: 24,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          margin: const EdgeInsets.all(24),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 72),
                const SizedBox(height: 16),
                const Text('CRITICAL ALERT', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 16),
                Text(_title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(_body, style: const TextStyle(fontSize: 16, height: 1.5), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () async {
                    await FlutterOverlayWindow.closeOverlay();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text('DISMISS', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}