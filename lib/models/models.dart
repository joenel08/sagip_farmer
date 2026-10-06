class UserModel {
  final int id;
  final String fullName;
  final String contactNumber;
  final String fullAddress;
  final String username;
  final String role; // 'user' | 'admin'

  UserModel({
    required this.id,
    required this.fullName,
    required this.contactNumber,
    required this.fullAddress,
    required this.username,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: int.parse(j['id'].toString()),
        fullName: (j['full_name'] ?? '').toString(),
        contactNumber: (j['contact_number'] ?? '').toString(),
        fullAddress: (j['full_address'] ?? '').toString(),
        username: (j['username'] ?? '').toString(),
        role: (j['role'] ?? 'user').toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'contact_number': contactNumber,
        'full_address': fullAddress,
        'username': username,
        'role': role,
      };

  bool get isAdmin => role == 'admin';
}

// ------------------------------------------------------------
// PLOT  (a sensor installed at a location)
// ------------------------------------------------------------
class Plot {
  final int id;
  final int userId;
  final String sensorName;
  final String sensorType; // 'water_level' | 'soil_moisture'
  final String sensorId;
  final double latitude;
  final double longitude;
  double? latestValue;
  DateTime? lastUpdate;

  Plot({
    required this.id,
    required this.userId,
    required this.sensorName,
    required this.sensorType,
    required this.sensorId,
    required this.latitude,
    required this.longitude,
    this.latestValue,
    this.lastUpdate,
  });

  factory Plot.fromJson(Map<String, dynamic> j) => Plot(
        id: int.parse(j['id'].toString()),
        userId: int.parse(j['user_id'].toString()),
        sensorName: (j['sensor_name'] ?? '').toString(),
        sensorType: (j['sensor_type'] ?? 'water_level').toString(),
        sensorId: (j['sensor_id'] ?? '').toString(),
        latitude: double.tryParse(j['latitude'].toString()) ?? 0,
        longitude: double.tryParse(j['longitude'].toString()) ?? 0,
        latestValue: j['latest_value'] != null
            ? double.tryParse(j['latest_value'].toString())
            : null,
        lastUpdate: j['last_update'] != null
            ? DateTime.tryParse(j['last_update'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'sensor_name': sensorName,
        'sensor_type': sensorType,
        'sensor_id': sensorId,
        'latitude': latitude,
        'longitude': longitude,
        'latest_value': latestValue,
        'last_update': lastUpdate?.toIso8601String(),
      };

  bool get isWater => sensorType == 'water_level';
  bool get isSoil => sensorType == 'soil_moisture';

  String get typeLabel => isWater ? 'Water Level' : 'Soil Moisture';
}

// ------------------------------------------------------------
// READING  (a single sensor value with timestamp)
// ------------------------------------------------------------
class Reading {
  final double value;
  final DateTime time;

  Reading({required this.value, required this.time});

  factory Reading.fromJson(Map<String, dynamic> j) => Reading(
        value: double.tryParse(j['value'].toString()) ?? 0,
        time: DateTime.tryParse(j['reading_time'] ?? '') ?? DateTime.now(),
      );
}
// ------------------------------------------------------------
// ALERT (defensive parsing — never crashes on null fields)
// ------------------------------------------------------------
class AlertModel {
  final int id;
  final String alertType;
  final String message;
  final String severity;
  final bool isRead;
  final String sensorName;
  final DateTime createdAt;

  // Owner info (populated by admin queries)
  final String userName;
  final String userAddress;
  final String userContact;

  AlertModel({
    required this.id,
    required this.alertType,
    required this.message,
    required this.severity,
    required this.isRead,
    required this.sensorName,
    required this.createdAt,
    this.userName = '',
    this.userAddress = '',
    this.userContact = '',
  });

  /// Safe String converter — never returns null.
  static String _str(dynamic v) {
    if (v == null) return '';
    return v.toString();
  }

  factory AlertModel.fromJson(Map<String, dynamic> j) {
    return AlertModel(
      id: int.tryParse(_str(j['id'])) ?? 0,
      alertType: _str(j['alert_type']).isEmpty
          ? 'Alert'
          : _str(j['alert_type']),
      message: _str(j['message']),
      severity: _str(j['severity']).isEmpty
          ? 'low'
          : _str(j['severity']),
      isRead: _str(j['is_read']) == '1' ||
          _str(j['is_read']).toLowerCase() == 'true',
      sensorName: _str(j['sensor_name']),
      createdAt: DateTime.tryParse(_str(j['created_at'])) ?? DateTime.now(),
      userName: _str(j['user_name']),
      userAddress: _str(j['user_address']),
      userContact: _str(j['user_contact']),
    );
  }

  bool get isHigh => severity == 'high';
  bool get isMedium => severity == 'medium';
  bool get isLow => severity == 'low';
}