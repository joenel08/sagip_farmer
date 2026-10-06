// ============================================================
// lib/services/location_service.dart
// Thin wrapper around geolocator that handles permission
// requests and returns a clean result for the UI.
// ============================================================
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;
  LocationResult({required this.latitude, required this.longitude});
}

/// Possible outcomes from [LocationService.getCurrentPosition]
enum LocationError {
  serviceDisabled,   // GPS / location services are OFF
  permissionDenied,  // user tapped "Deny"
  permissionDeniedForever,
  unknown,
}

class LocationService {
  /// Ask for permission and return the current position.
  ///
  /// Throws [LocationException] on failure so the UI can show a
  /// meaningful message.
  static Future<LocationResult> getCurrentPosition() async {
    // 1. Is location service (GPS) enabled on the device?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException(
        LocationError.serviceDisabled,
        'Location services are turned off. Please enable GPS in your device settings.',
      );
    }

    // 2. Check / request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw LocationException(
        LocationError.permissionDenied,
        'Location permission denied. Grant it to use your current location.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        LocationError.permissionDeniedForever,
        'Location permission permanently denied. Open app settings to allow it.',
      );
    }

    // 3. Get the position
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      return LocationResult(
        latitude: pos.latitude,
        longitude: pos.longitude,
      );
    } catch (_) {
      // Timeout or GPS not fixed — try last known position instead
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return LocationResult(
          latitude: last.latitude,
          longitude: last.longitude,
        );
      }
      throw LocationException(
        LocationError.unknown,
        'Could not get your location. Try again or move to an open area.',
      );
    }
  }

  /// Open the OS settings screen so the user can enable GPS.
  static Future<void> openLocationSettings() =>
      Geolocator.openLocationSettings();

  /// Open the app's permission settings.
  static Future<void> openAppSettings() => Geolocator.openAppSettings();
}

class LocationException implements Exception {
  final LocationError type;
  final String message;
  LocationException(this.type, this.message);

  @override
  String toString() => message;
}