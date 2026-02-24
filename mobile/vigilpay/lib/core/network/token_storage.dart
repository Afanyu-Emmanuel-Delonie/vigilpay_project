import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _accessKey = 'vp_access_token';
  static const String _refreshKey = 'vp_refresh_token';
  static const String _accessFallbackKey = 'vp_access_token_fallback';
  static const String _refreshFallbackKey = 'vp_refresh_token_fallback';

  final FlutterSecureStorage _secureStorage;
  String? _accessTokenMemory;
  String? _refreshTokenMemory;

  Future<String?> readAccessToken() async {
    try {
      final token = await _secureStorage.read(key: _accessKey);
      if (token != null && token.isNotEmpty) {
        _accessTokenMemory = token;
        return token;
      }
    } catch (_) {}

    final fallback = await _readFallback(_accessFallbackKey);
    if (fallback != null && fallback.isNotEmpty) {
      _accessTokenMemory = fallback;
      return fallback;
    }

    return _accessTokenMemory;
  }

  Future<String?> readRefreshToken() async {
    try {
      final token = await _secureStorage.read(key: _refreshKey);
      if (token != null && token.isNotEmpty) {
        _refreshTokenMemory = token;
        return token;
      }
    } catch (_) {}

    final fallback = await _readFallback(_refreshFallbackKey);
    if (fallback != null && fallback.isNotEmpty) {
      _refreshTokenMemory = fallback;
      return fallback;
    }

    return _refreshTokenMemory;
  }

  Future<void> writeTokens({required String access, required String refresh}) async {
    _accessTokenMemory = access;
    _refreshTokenMemory = refresh;

    try {
      await _secureStorage.write(key: _accessKey, value: access);
      await _secureStorage.write(key: _refreshKey, value: refresh);
    } catch (_) {}

    await _writeFallback(_accessFallbackKey, access);
    await _writeFallback(_refreshFallbackKey, refresh);
  }

  Future<void> clearTokens() async {
    _accessTokenMemory = null;
    _refreshTokenMemory = null;

    try {
      await _secureStorage.delete(key: _accessKey);
      await _secureStorage.delete(key: _refreshKey);
    } catch (_) {}

    await _deleteFallback(_accessFallbackKey);
    await _deleteFallback(_refreshFallbackKey);
  }

  Future<String?> _readFallback(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeFallback(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } catch (_) {}
  }

  Future<void> _deleteFallback(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }
}
