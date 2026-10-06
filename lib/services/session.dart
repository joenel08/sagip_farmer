// ============================================================
// lib/services/session.dart
// Handles persistent login state + "remember me" credentials
// using SharedPreferences.
// ============================================================
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class Session {
  // -------- session keys --------
  static const _kId = 'user_id';
  static const _kName = 'full_name';
  static const _kUser = 'username';
  static const _kAddr = 'address';
  static const _kContact = 'contact';
  static const _kRole = 'role';

  // -------- remember-me keys --------
  static const _kRemember = 'remember';
  static const _kSavedUser = 'saved_username';
  static const _kSavedPass = 'saved_password';

  // ============================================================
  // SESSION (logged-in user)
  // ============================================================
  static Future<void> saveUser(UserModel u) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kId, u.id);
    await p.setString(_kName, u.fullName);
    await p.setString(_kUser, u.username);
    await p.setString(_kAddr, u.fullAddress);
    await p.setString(_kContact, u.contactNumber);
    await p.setString(_kRole, u.role);
  }

  static Future<UserModel?> getUser() async {
    final p = await SharedPreferences.getInstance();
    final id = p.getInt(_kId);
    if (id == null) return null;

    return UserModel(
      id: id,
      fullName: p.getString(_kName) ?? '',
      username: p.getString(_kUser) ?? '',
      fullAddress: p.getString(_kAddr) ?? '',
      contactNumber: p.getString(_kContact) ?? '',
      role: p.getString(_kRole) ?? 'user',
    );
  }

  static Future<bool> isLoggedIn() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kId) != null;
  }

  /// Clears the current session but KEEPS saved credentials
  /// (so "remember me" still works next time).
  static Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kId);
    await p.remove(_kName);
    await p.remove(_kUser);
    await p.remove(_kAddr);
    await p.remove(_kContact);
    await p.remove(_kRole);
  }

  /// Full wipe — including remember-me credentials.
  static Future<void> logoutAndForget() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
  }

  // ============================================================
  // REMEMBER ME
  // ============================================================
  static Future<void> saveCredentials(String username, String password) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kRemember, true);
    await p.setString(_kSavedUser, username);
    await p.setString(_kSavedPass, password);
  }

  static Future<void> clearCredentials() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kRemember, false);
    await p.remove(_kSavedUser);
    await p.remove(_kSavedPass);
  }

  static Future<Map<String, String>?> getCredentials() async {
    final p = await SharedPreferences.getInstance();
    if (p.getBool(_kRemember) != true) return null;

    final u = p.getString(_kSavedUser);
    final pw = p.getString(_kSavedPass);
    if (u == null || pw == null) return null;

    return {'username': u, 'password': pw};
  }

  static Future<bool> isRemembered() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kRemember) ?? false;
  }

  /// Call this after a successful profile edit.
  static Future<void> updateUser(UserModel updated) async {
    await saveUser(updated);
  }
}
