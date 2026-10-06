// ============================================================
// lib/services/geocoding_service.dart
// Free geocoding via OpenStreetMap Nominatim.
// No API key required.
//
// Nominatim usage policy:
//   - Max 1 request per second
//   - Must include a valid User-Agent
//   - Do not bulk-query
// ============================================================
import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodeResult {
  final double latitude;
  final double longitude;
  final String displayName;

  GeocodeResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });
}

class GeocodingService {
  static const String _userAgent = 'SAGIPfarmer/1.0 (contact: support@sagipfarmer.com)';

  // ------------------------------------------------------------
  // Forward geocoding: address -> coordinates
  // ------------------------------------------------------------
  static Future<GeocodeResult?> fromAddress(String address) async {
    if (address.trim().isEmpty) return null;

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': address.trim(),
        'format': 'json',
        'addressdetails': '1',
        'limit': '1',
      });

      final r = await http.get(uri, headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));

      if (r.statusCode != 200) return null;

      final list = jsonDecode(r.body);
      if (list is! List || list.isEmpty) return null;

      final first = list.first;
      return GeocodeResult(
        latitude: double.parse(first['lat'].toString()),
        longitude: double.parse(first['lon'].toString()),
        displayName: first['display_name']?.toString() ?? address,
      );
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------
  // Reverse geocoding: coordinates -> address
  // ------------------------------------------------------------
  static Future<GeocodeResult?> fromCoordinates(
    double lat,
    double lng,
  ) async {
    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
        'lat': lat.toString(),
        'lon': lng.toString(),
        'format': 'json',
        'addressdetails': '1',
      });

      final r = await http.get(uri, headers: {
        'User-Agent': _userAgent,
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 15));

      if (r.statusCode != 200) return null;

      final d = jsonDecode(r.body);
      return GeocodeResult(
        latitude: lat,
        longitude: lng,
        displayName: d['display_name']?.toString() ?? '',
      );
    } catch (_) {
      return null;
    }
  }
}