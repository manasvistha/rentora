import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

final userSessionServiceProvider = Provider<UserSessionService>((ref) {
  return UserSessionService(const FlutterSecureStorage());
});

class UserSessionService {
  static String? normalizeRole(dynamic raw) {
    if (raw == null) return null;
    if (raw is String && raw.trim().isNotEmpty) {
      return raw.trim().toLowerCase();
    }
    if (raw is Map<String, dynamic>) {
      final name = raw['name'] ?? raw['role'] ?? raw['value'];
      if (name is String && name.trim().isNotEmpty) {
        return name.trim().toLowerCase();
      }
    }
    return null;
  }

  static String? extractRoleFromToken(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final payload = JwtDecoder.decode(token);
      return normalizeRole(payload['role'] ?? payload['roles']);
    } catch (_) {
      return null;
    }
  }

  final FlutterSecureStorage _secureStorage;

  UserSessionService(this._secureStorage);

  // Keys for storage
  static const String _tokenKey = 'auth_token';
  static const String _userIdKey = 'user_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  static const String _userRoleKey = 'user_role';

  /// Saves the 4 core fields + token after a successful login/register
  Future<void> saveUserSession({
    required String userId,
    required String email,
    required String name,
    required String token,
    String? role,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Store the sensitive token in Secure Storage
    await _secureStorage.write(key: _tokenKey, value: token);

    // 2. Store non-sensitive profile info in SharedPreferences
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userNameKey, name);
    final normalizedRole = normalizeRole(role) ?? extractRoleFromToken(token);
    if (normalizedRole != null) {
      await prefs.setString(_userRoleKey, normalizedRole);
    }
  }

  /// Retrieves the JWT token for API headers
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Checks if a user is currently logged in
  Future<bool> hasSession() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Gets the stored user data (returning your 4 core fields)
  Future<Map<String, String?>> getUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString(_userIdKey),
      'email': prefs.getString(_userEmailKey),
      'name': prefs.getString(_userNameKey),
      'role': prefs.getString(_userRoleKey),
    };
  }

  /// Clears everything on logout
  Future<void> deleteSession() async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: _tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userRoleKey);
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    final storedRole = normalizeRole(prefs.getString(_userRoleKey));
    if (storedRole != null) return storedRole;

    final tokenRole = extractRoleFromToken(await getToken());
    if (tokenRole != null) {
      await prefs.setString(_userRoleKey, tokenRole);
    }
    return tokenRole;
  }

  Future<bool> isAdmin() async {
    final role = await getUserRole();
    if (role == null) return false;
    return role.toLowerCase() == 'admin' ||
        role.toLowerCase() == 'administrator';
  }
}
