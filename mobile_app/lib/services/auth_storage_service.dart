// lib/services/auth_storage_service.dart
// Secure Authentication Persistence Service using flutter_secure_storage

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Storage Keys
  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyUserId = 'auth_user_id';
  static const String _keyUserEmail = 'auth_user_email';
  static const String _keyUserRole = 'auth_user_role';
  static const String _keyUserName = 'auth_user_name';

  /// Save session credentials securely
  static Future<void> saveAuthData({
    required String accessToken,
    String? refreshToken,
    required String userId,
    required String userEmail,
    required String userRole,
    required String userName,
  }) async {
    try {
      await _storage.write(key: _keyAccessToken, value: accessToken);
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _storage.write(key: _keyRefreshToken, value: refreshToken);
      }
      await _storage.write(key: _keyUserId, value: userId);
      await _storage.write(key: _keyUserEmail, value: userEmail);
      await _storage.write(key: _keyUserRole, value: userRole);
      await _storage.write(key: _keyUserName, value: userName);
    } catch (e) {
      debugPrint('AuthStorageService saveAuthData error: $e');
    }
  }

  /// Get stored access token securely
  static Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _keyAccessToken);
    } catch (e) {
      debugPrint('AuthStorageService getAccessToken error: $e');
      return null;
    }
  }

  /// Get stored refresh token securely
  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken);
    } catch (e) {
      debugPrint('AuthStorageService getRefreshToken error: $e');
      return null;
    }
  }

  /// Get stored user details
  static Future<Map<String, String?>> getUserData() async {
    try {
      final email = await _storage.read(key: _keyUserEmail);
      final role = await _storage.read(key: _keyUserRole);
      final name = await _storage.read(key: _keyUserName);
      final id = await _storage.read(key: _keyUserId);
      return {
        'id': id,
        'email': email,
        'role': role,
        'name': name,
      };
    } catch (e) {
      debugPrint('AuthStorageService getUserData error: $e');
      return {};
    }
  }

  /// Check if user has an active stored token
  static Future<bool> hasValidSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Securely clear all stored credentials on logout
  static Future<void> clearAuthData() async {
    try {
      await _storage.delete(key: _keyAccessToken);
      await _storage.delete(key: _keyRefreshToken);
      await _storage.delete(key: _keyUserId);
      await _storage.delete(key: _keyUserEmail);
      await _storage.delete(key: _keyUserRole);
      await _storage.delete(key: _keyUserName);
    } catch (e) {
      debugPrint('AuthStorageService clearAuthData error: $e');
    }
  }
}
