class ApiConfig {
  // ------------------------------------------------------------
  // BASE URL
  // ------------------------------------------------------------
  // Android emulator  -> http://10.0.2.2/sagipfarmer_api/api
  // iOS simulator     -> http://localhost/sagipfarmer_api/api
  // Real phone (LAN)  -> http://192.168.x.x/sagipfarmer_api/api
  // ------------------------------------------------------------
  static const String baseUrl = "https://sagipfarmer.isuc-ccsict.com/api";

  // ---------------- AUTH ----------------
  static const String register = "$baseUrl/register.php";
  static const String login = "$baseUrl/login.php";

  // ---------------- USER DATA ----------------
  static const String updateProfile = "$baseUrl/update_profile.php"; // ← NEW
  static const String plots = "$baseUrl/plots.php";
  static const String readings = "$baseUrl/readings.php";
  static const String alerts = "$baseUrl/alerts.php";

  // ---------------- ADMIN ----------------
  static const String adminUsers = "$baseUrl/admin_users.php";
  static const String adminSensors = "$baseUrl/admin_sensors.php";

  // ---------------- FCM TOKEN ----------------
  static const String saveToken = "$baseUrl/save_token.php";
  static const String clearToken = "$baseUrl/clear_token.php";

  // ---------------- TIME SETTINGS ----------------
  /// How often the dashboard auto-refreshes sensor data (seconds).
  static const int autoRefreshSeconds = 10;

  /// How many recent readings to pull for the chart.
  static const int chartReadingLimit = 20;

  /// Splash screen delay (milliseconds).
  static const int splashDelayMs = 2400;
}
