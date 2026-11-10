import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum Environment { development, production }

/// Centralized Environment & Network Configuration for CricketVerse AI.
/// Provides cloud-native, globally accessible endpoints for API and real-time Socket.IO.
class AppConfig {
  // --- Compile-time definitions (e.g. flutter build apk --dart-define=ENV=production) ---
  static const String _envString = String.fromEnvironment('ENV', defaultValue: 'production');
  static const String _compileTimeApiUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  static const String _compileTimeSocketUrl = String.fromEnvironment('SOCKET_BASE_URL', defaultValue: '');

  // --- Official Public Cloud Production Endpoints ---
  static const String productionApiBaseUrl = 'https://cricketverse-n103.onrender.com/api/v1';
  static const String productionSocketBaseUrl = 'https://cricketverse-n103.onrender.com';

  // --- Development Local Endpoints (used only when ENV=development) ---
  static const String devApiBaseUrl = 'http://10.0.2.2:3000/api/v1';
  static const String devSocketBaseUrl = 'http://10.0.2.2:3000';

  static String? _customApiBaseUrl;

  /// Current active environment
  static Environment get currentEnvironment {
    if (_envString.toLowerCase() == 'dev' || _envString.toLowerCase() == 'development') {
      return Environment.development;
    }
    // Always default to production for release APKs and general builds
    return Environment.production;
  }

  static bool get isProduction => currentEnvironment == Environment.production;
  static bool get isDevelopment => currentEnvironment == Environment.development;

  /// Initialize stored preferences (e.g. custom developer override)
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('cricketverse_api_base_url');
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _customApiBaseUrl = savedUrl.trim();
      }
    } catch (e) {
      debugPrint('AppConfig init error: $e');
    }
  }

  /// Sets or clears a runtime custom base URL (persisted in SharedPreferences)
  static Future<void> setCustomBaseUrl(String? url) async {
    _customApiBaseUrl = url?.trim().isNotEmpty == true ? url!.trim() : null;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_customApiBaseUrl != null) {
        await prefs.setString('cricketverse_api_base_url', _customApiBaseUrl!);
      } else {
        await prefs.remove('cricketverse_api_base_url');
      }
    } catch (_) {}
  }

  /// Primary API Base URL used by all HTTP services across the app
  static String get apiBaseUrl {
    // 1. Runtime override if set in developer settings
    if (_customApiBaseUrl != null && _customApiBaseUrl!.isNotEmpty) {
      return _customApiBaseUrl!;
    }

    // 2. Build-time dart-define override if passed
    if (_compileTimeApiUrl.isNotEmpty) {
      return _compileTimeApiUrl;
    }

    // 3. Environment default
    if (isDevelopment && !kReleaseMode) {
      return devApiBaseUrl;
    }

    // Default globally to production cloud backend
    return productionApiBaseUrl;
  }

  /// Primary Socket.IO Server URL used by real-time scoring & events
  static String get socketBaseUrl {
    if (_compileTimeSocketUrl.isNotEmpty) {
      return _compileTimeSocketUrl;
    }

    // Derive root host from API URL by stripping trailing '/api/v1' or '/api'
    final api = apiBaseUrl;
    if (api.endsWith('/api/v1')) {
      return api.substring(0, api.length - 7);
    }
    if (api.endsWith('/api/v1/')) {
      return api.substring(0, api.length - 8);
    }
    if (api.endsWith('/api')) {
      return api.substring(0, api.length - 4);
    }
    return api;
  }

  /// Public Health check URL
  static String get healthCheckUrl => '$socketBaseUrl/health';

  /// Candidate URLs for automatic fallback and endpoint auto-discovery
  static List<String> get candidateApiBaseUrls {
    final list = <String>[];
    
    // Always start with the active primary URL
    list.add(apiBaseUrl);

    // If custom URL is active, include production as cloud backup
    if (apiBaseUrl != productionApiBaseUrl) {
      list.add(productionApiBaseUrl);
    }

    return list;
  }
}

