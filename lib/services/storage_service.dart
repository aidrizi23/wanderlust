import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  static const String _expirationKey = 'token_expiration';

  Future<void> saveAuthData({
    required String token,
    required String refreshToken,
    required String userName,
    required String email,
    required List<String> roles,
    required DateTime expiration,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_tokenKey, token);
    await prefs.setString(_refreshTokenKey, refreshToken);
    await prefs.setString(_expirationKey, expiration.toIso8601String());

    final userData = {'userName': userName, 'email': email, 'roles': roles};
    await prefs.setString(_userKey, json.encode(userData));
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson != null) {
      return json.decode(userJson);
    }
    return null;
  }

  Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expirationString = prefs.getString(_expirationKey);
    if (expirationString == null) return true;

    final expiration = DateTime.parse(expirationString);
    return DateTime.now().isAfter(expiration);
  }

  Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_expirationKey);
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && !(await isTokenExpired());
  }
}
