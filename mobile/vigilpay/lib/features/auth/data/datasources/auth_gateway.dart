import 'package:flutter/foundation.dart';

import '../../../../core/constants/endpoint_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/auth_session_manager.dart';
import '../../../../core/network/jwt_tokens.dart';

class AuthGateway {
  AuthGateway({
    required ApiClient apiClient,
    required AuthSessionManager sessionManager,
  })  : _apiClient = apiClient,
        _sessionManager = sessionManager;

  final ApiClient _apiClient;
  final AuthSessionManager _sessionManager;

  Future<void> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) async {
    await _apiClient.post(
      EndpointConstants.mobileRegister,
      requiresAuth: false,
      body: <String, dynamic>{
        'first_name': firstName,
        'last_name': lastName,
        'username': username,
        'email': email,
        'password': password,
      },
    );
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      EndpointConstants.mobileLogin,
      requiresAuth: false,
      body: <String, dynamic>{
        'email': email,
        'password': password,
      },
    );

    final rawTokens = response['tokens'];
    if (rawTokens is Map<String, dynamic>) {
      try {
        await _sessionManager.saveTokens(JwtTokens.fromJson(rawTokens));
      } catch (error) {
        debugPrint('Token persistence failed after login: $error');
      }
    }

    try {
      return await fetchProfile();
    } catch (_) {
      final user = response['user'];
      if (user is Map<String, dynamic>) {
        return user;
      }
    }

    return <String, dynamic>{};
  }

  Future<Map<String, dynamic>> fetchProfile() {
    return _apiClient.get(EndpointConstants.mobileMe);
  }

  Future<void> logout() async {
    final refresh = await _sessionManager.refreshToken();

    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _apiClient.post(
          EndpointConstants.mobileLogout,
          body: <String, dynamic>{'refresh': refresh},
        );
      } catch (_) {
      }
    }

    await _sessionManager.clear();
  }
}
