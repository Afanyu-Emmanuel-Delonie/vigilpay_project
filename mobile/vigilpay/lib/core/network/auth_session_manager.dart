import 'dart:convert';

import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';
import '../constants/endpoint_constants.dart';
import '../errors/api_exception.dart';
import 'jwt_tokens.dart';
import 'token_storage.dart';

class AuthSessionManager {
  AuthSessionManager({
    required TokenStorage tokenStorage,
    http.Client? httpClient,
  })  : _tokenStorage = tokenStorage,
        _httpClient = httpClient ?? http.Client();

  final TokenStorage _tokenStorage;
  final http.Client _httpClient;

  Future<String?> accessToken() {
    return _tokenStorage.readAccessToken();
  }

  Future<String?> refreshToken() {
    return _tokenStorage.readRefreshToken();
  }

  Future<void> saveTokens(JwtTokens tokens) {
    return _tokenStorage.writeTokens(access: tokens.access, refresh: tokens.refresh);
  }

  Future<void> clear() {
    return _tokenStorage.clearTokens();
  }

  Future<bool> refreshAccessToken() async {
    final refresh = await _tokenStorage.readRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      return false;
    }

    final uri = Uri.parse('${ApiConstants.baseUrl}${EndpointConstants.mobileRefresh}');
    final response = await _httpClient
        .post(
          uri,
          headers: <String, String>{'Content-Type': 'application/json'},
          body: jsonEncode(<String, dynamic>{'refresh': refresh}),
        )
        .timeout(ApiConstants.timeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      await clear();
      return false;
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Invalid refresh response', statusCode: response.statusCode);
    }

    final newAccess = decoded['access']?.toString() ?? '';
    final newRefresh = decoded['refresh']?.toString() ?? refresh;

    if (newAccess.isEmpty) {
      return false;
    }

    await _tokenStorage.writeTokens(access: newAccess, refresh: newRefresh);
    return true;
  }
}
