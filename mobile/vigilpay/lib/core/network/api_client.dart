import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../errors/api_exception.dart';
import 'auth_session_manager.dart';

class ApiClient {
  ApiClient({
    required AuthSessionManager sessionManager,
    http.Client? httpClient,
  })  : _sessionManager = sessionManager,
        _httpClient = httpClient ?? http.Client();

  final AuthSessionManager _sessionManager;
  final http.Client _httpClient;

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final payload = await getAny(
      path,
      headers: headers,
      requiresAuth: requiresAuth,
    );
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    throw ApiException('Unexpected response format', statusCode: 200);
  }

  Future<dynamic> getAny(
    String path, {
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    return _sendJsonRequest(
      () async {
        final resolvedHeaders = await _headers(headers, requiresAuth: requiresAuth);
        final uri = Uri.parse('${ApiConstants.baseUrl}$path');
        return _httpClient.get(uri, headers: resolvedHeaders).timeout(ApiConstants.timeout);
      },
      requiresAuth: requiresAuth,
    );
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    return _sendMapRequest(
      () async {
        final resolvedHeaders = await _headers(headers, requiresAuth: requiresAuth);
        final uri = Uri.parse('${ApiConstants.baseUrl}$path');
        return _httpClient
            .post(
              uri,
              headers: resolvedHeaders,
              body: jsonEncode(body ?? <String, dynamic>{}),
            )
            .timeout(ApiConstants.timeout);
      },
      requiresAuth: requiresAuth,
    );
  }

  Future<dynamic> _sendJsonRequest(
    Future<http.Response> Function() requestBuilder, {
    required bool requiresAuth,
  }) async {
    var response = await requestBuilder();

    if (response.statusCode == 401 && requiresAuth) {
      final refreshed = await _sessionManager.refreshAccessToken();
      if (refreshed) {
        response = await requestBuilder();
      }
    }

    return _decodeJson(response);
  }

  Future<Map<String, dynamic>> _sendMapRequest(
    Future<http.Response> Function() requestBuilder, {
    required bool requiresAuth,
  }) async {
    final payload = await _sendJsonRequest(
      requestBuilder,
      requiresAuth: requiresAuth,
    );
    if (payload is Map<String, dynamic>) {
      return payload;
    }
    throw ApiException('Unexpected response format', statusCode: 200);
  }

  Future<Map<String, String>> _headers(
    Map<String, String>? headers, {
    required bool requiresAuth,
  }) async {
    final result = <String, String>{
      'Content-Type': 'application/json',
      ...?headers,
    };

    if (!requiresAuth) {
      return result;
    }

    final token = await _sessionManager.accessToken();
    if (token == null || token.isEmpty) {
      throw ApiException('Missing access token', statusCode: 401);
    }

    result['Authorization'] = 'Bearer $token';
    return result;
  }

  dynamic _decodeJson(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.body, statusCode: response.statusCode);
    }

    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic> || decoded is List) {
      return decoded;
    }

    throw ApiException('Unexpected response format', statusCode: response.statusCode);
  }
}
