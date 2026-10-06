// ============================================================
// lib/services/api_service.dart
// ============================================================
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/models.dart';

class ApiService {
  static Map<String, String> get _jsonHeaders => {
        "Content-Type": "application/json; charset=UTF-8",
        "Accept": "application/json",
      };

  static Map<String, dynamic> _decode(http.Response r) {
    try {
      final body = r.body.trim();
      if (body.isEmpty) {
        return {"success": false, "message": "Empty response from server."};
      }
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {"success": false, "message": "Unexpected response format."};
    } catch (_) {
      return {
        "success": false,
        "message": "Server returned invalid response (HTTP ${r.statusCode})."
      };
    }
  }

  // ============================================================
  // AUTH
  // ============================================================
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String contactNumber,
    required String fullAddress,
    required String username,
    required String password,
  }) async {
    try {
      final r = await http.post(
        Uri.parse(ApiConfig.register),
        headers: _jsonHeaders,
        body: jsonEncode({
          'full_name': fullName,
          'contact_number': contactNumber,
          'full_address': fullAddress,
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 20));
      return _decode(r);
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  static Future<Map<String, dynamic>> login(
      String username, String password) async {
    try {
      final r = await http.post(
        Uri.parse(ApiConfig.login),
        headers: _jsonHeaders,
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 20));
      return _decode(r);
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================
  static Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String fullName,
    required String contactNumber,
    required String fullAddress,
  }) async {
    try {
      final r = await http.post(
        Uri.parse(ApiConfig.updateProfile),
        headers: _jsonHeaders,
        body: jsonEncode({
          'user_id': userId,
          'full_name': fullName,
          'contact_number': contactNumber,
          'full_address': fullAddress,
        }),
      ).timeout(const Duration(seconds: 20));
      return _decode(r);
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  // ============================================================
  // PLOTS
  // ============================================================
  static Future<List<Plot>> getPlots(int userId) async {
    try {
      final r = await http
          .get(Uri.parse("${ApiConfig.plots}?user_id=$userId"))
          .timeout(const Duration(seconds: 20));
      final d = _decode(r);
      if (d['success'] == true && d['plots'] is List) {
        return (d['plots'] as List)
            .map((e) => Plot.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> addPlot({
    required int userId,
    required String sensorName,
    required String sensorType,
    required String sensorId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final r = await http.post(
        Uri.parse(ApiConfig.plots),
        headers: _jsonHeaders,
        body: jsonEncode({
          'user_id': userId,
          'sensor_name': sensorName,
          'sensor_type': sensorType,
          'sensor_id': sensorId,
          'latitude': latitude,
          'longitude': longitude,
        }),
      ).timeout(const Duration(seconds: 20));
      return _decode(r);
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  static Future<bool> deletePlot(int id) async {
    try {
      final r = await http
          .delete(Uri.parse("${ApiConfig.plots}?id=$id"))
          .timeout(const Duration(seconds: 20));
      return _decode(r)['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // READINGS
  // ============================================================
  static Future<Map<String, dynamic>> getReadings(
    int plotId, {
    int limit = ApiConfig.chartReadingLimit,
  }) async {
    try {
      final r = await http
          .get(Uri.parse(
              "${ApiConfig.readings}?plot_id=$plotId&limit=$limit"))
          .timeout(const Duration(seconds: 20));
      final d = _decode(r);

      if (d['success'] == true) {
        final list = (d['readings'] as List? ?? [])
            .map((e) => Reading.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        final latest = d['latest'] != null
            ? double.tryParse(d['latest'].toString())
            : (list.isNotEmpty ? list.last.value : null);

        return {'readings': list, 'latest': latest};
      }
      return {'readings': <Reading>[], 'latest': null};
    } catch (_) {
      return {'readings': <Reading>[], 'latest': null};
    }
  }

  // ============================================================
  // ALERTS
  // ============================================================
  static Future<List<AlertModel>> getAlerts(int userId) async {
    try {
      final r = await http
          .get(Uri.parse("${ApiConfig.alerts}?user_id=$userId"))
          .timeout(const Duration(seconds: 20));
      final d = _decode(r);
      if (d['success'] == true && d['alerts'] is List) {
        return (d['alerts'] as List)
            .map((e) => AlertModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<AlertModel>> getAllAlerts() async {
    try {
      final r = await http
          .get(Uri.parse("${ApiConfig.alerts}?all=1"))
          .timeout(const Duration(seconds: 20));
      final d = _decode(r);
      if (d['success'] == true && d['alerts'] is List) {
        return (d['alerts'] as List)
            .map((e) => AlertModel.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // ADMIN
  // ============================================================
  static Future<List<Map<String, dynamic>>> getAdminUsers() async {
    try {
      final r = await http
          .get(Uri.parse(ApiConfig.adminUsers))
          .timeout(const Duration(seconds: 20));
      final d = _decode(r);
      if (d['success'] == true && d['users'] is List) {
        return List<Map<String, dynamic>>.from(
          (d['users'] as List)
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<Plot>> getAdminSensors() async {
    try {
      final r = await http
          .get(Uri.parse(ApiConfig.adminSensors))
          .timeout(const Duration(seconds: 20));
      final d = _decode(r);
      if (d['success'] == true && d['sensors'] is List) {
        return (d['sensors'] as List)
            .map((e) => Plot.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ============================================================
  // FCM
  // ============================================================
  static Future<void> saveToken(int userId, String token) async {
    try {
      await http.post(
        Uri.parse(ApiConfig.saveToken),
        headers: _jsonHeaders,
        body: jsonEncode({'user_id': userId, 'fcm_token': token}),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {}
  }

  static Future<void> clearToken(int userId, String token) async {
    try {
      await http.post(
        Uri.parse(ApiConfig.clearToken),
        headers: _jsonHeaders,
        body: jsonEncode({'user_id': userId, 'fcm_token': token}),
      ).timeout(const Duration(seconds: 15));
    } catch (_) {}
  }
}