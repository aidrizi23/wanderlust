import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:wanderlust/services/storage_service.dart';

class ApiService {
  static const String _baseUrl = 'http://192.168.224.82:5076/api';
  static const Duration _timeout = Duration(seconds: 30);

  final StorageService _storage = StorageService();

  Future<Map<String, String>> _getHeaders({bool requiresAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _storage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<http.Response> get(
    String endpoint, {
    bool requiresAuth = false,
    Map<String, String>? queryParams,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl$endpoint',
      ).replace(queryParameters: queryParams);
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await http.get(uri, headers: headers).timeout(_timeout);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<http.Response> post(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await http
          .post(uri, headers: headers, body: json.encode(body))
          .timeout(_timeout);

      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<http.Response> put(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await http
          .put(uri, headers: headers, body: json.encode(body))
          .timeout(_timeout);

      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<http.Response> delete(
    String endpoint, {
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');
      final headers = await _getHeaders(requiresAuth: requiresAuth);

      final response = await http
          .delete(uri, headers: headers)
          .timeout(_timeout);
      return response;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(dynamic error) {
    if (error is http.Response) {
      switch (error.statusCode) {
        case 400:
          return Exception('Bad request');
        case 401:
          return Exception('Unauthorized');
        case 403:
          return Exception('Forbidden');
        case 404:
          return Exception('Not found');
        case 500:
          return Exception('Server error');
        default:
          return Exception('Unknown error: ${error.statusCode}');
      }
    }
    return Exception('Network error: $error');
  }
}
