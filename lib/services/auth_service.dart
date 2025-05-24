import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/auth_models.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<void> checkAuthStatus() async {
    try {
      _isLoading = true;
      notifyListeners();

      final hasToken = await _storage.hasToken();
      if (hasToken) {
        final userData = await _storage.getUserData();
        if (userData != null) {
          _currentUser = User(
            userName: userData['userName'],
            email: userData['email'],
            roles: List<String>.from(userData['roles']),
          );
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(LoginRequest request) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _api.post('/auth/login', body: request.toJson());

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final authResponse = AuthResponse.fromJson(data);

        if (authResponse.isSuccess) {
          await _storage.saveAuthData(
            token: authResponse.token,
            refreshToken: authResponse.refreshToken,
            userName: authResponse.userName,
            email: authResponse.email,
            roles: authResponse.roles,
            expiration: authResponse.expiration,
          );

          _currentUser = User(
            userName: authResponse.userName,
            email: authResponse.email,
            roles: authResponse.roles,
          );

          return true;
        } else {
          _error = authResponse.message;
          return false;
        }
      } else {
        _error = 'Invalid email or password';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(RegisterRequest request) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _api.post(
        '/auth/register',
        body: request.toJson(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = json.decode(response.body);
        final authResponse = AuthResponse.fromJson(data);

        if (authResponse.isSuccess) {
          await _storage.saveAuthData(
            token: authResponse.token,
            refreshToken: authResponse.refreshToken,
            userName: authResponse.userName,
            email: authResponse.email,
            roles: authResponse.roles,
            expiration: authResponse.expiration,
          );

          _currentUser = User(
            userName: authResponse.userName,
            email: authResponse.email,
            roles: authResponse.roles,
          );

          return true;
        } else {
          _error = authResponse.message;
          return false;
        }
      } else {
        final errorData = json.decode(response.body);
        _error = errorData['message'] ?? 'Registration failed';
        return false;
      }
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Try to call logout endpoint
      try {
        await _api.post('/auth/logout', body: {}, requiresAuth: true);
      } catch (e) {
        // Continue with local logout even if server logout fails
      }

      await _storage.clearAuthData();
      _currentUser = null;
      _error = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> refreshToken() async {
    try {
      final token = await _storage.getToken();
      final refreshToken = await _storage.getRefreshToken();

      if (token == null || refreshToken == null) return false;

      final response = await _api.post(
        '/auth/refresh-token',
        body: {'token': token, 'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final authResponse = AuthResponse.fromJson(data);

        if (authResponse.isSuccess) {
          await _storage.saveAuthData(
            token: authResponse.token,
            refreshToken: authResponse.refreshToken,
            userName: authResponse.userName,
            email: authResponse.email,
            roles: authResponse.roles,
            expiration: authResponse.expiration,
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
