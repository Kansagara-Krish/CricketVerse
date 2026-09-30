import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'socket_service.dart';
import '../core/widgets/app_notification.dart';

enum NetworkStatus {
  online,
  slow,
  offline,
}

class NetworkConnectivityService {
  static final NetworkConnectivityService _instance = NetworkConnectivityService._internal();
  factory NetworkConnectivityService() => _instance;
  NetworkConnectivityService._internal();

  NetworkStatus _status = NetworkStatus.online;
  NetworkStatus get status => _status;

  DateTime? _lastSuccessfulPing;
  DateTime? get lastSuccessfulPing => _lastSuccessfulPing;

  final ValueNotifier<NetworkStatus> statusNotifier = ValueNotifier<NetworkStatus>(NetworkStatus.online);
  final ValueNotifier<DateTime?> lastSyncNotifier = ValueNotifier<DateTime?>(null);

  Timer? _pollingTimer;
  bool _isChecking = false;
  DateTime? _lastNotificationTime;
  String? _lastNotificationType;

  // Callbacks for reconnect / state recovery
  final List<Future<void> Function()> _onConnectionRestoredCallbacks = [];

  void addConnectionRestoredListener(Future<void> Function() callback) {
    if (!_onConnectionRestoredCallbacks.contains(callback)) {
      _onConnectionRestoredCallbacks.add(callback);
    }
  }

  void removeConnectionRestoredListener(Future<void> Function() callback) {
    _onConnectionRestoredCallbacks.remove(callback);
  }

  /// Initialize continuous network monitoring
  void initialize() {
    _startMonitoring();
  }

  void _startMonitoring() {
    _pollingTimer?.cancel();
    // Immediate initial check
    checkConnectivity();
    // Continuous polling every 4 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      checkConnectivity();
    });
  }

  /// Perform active health probe with latency detection
  Future<NetworkStatus> checkConnectivity() async {
    if (_isChecking) return _status;
    _isChecking = true;

    final previousStatus = _status;
    NetworkStatus newStatus;

    final stopwatch = Stopwatch()..start();

    try {
      final healthUri = Uri.parse('${ApiService.baseUrl}/health');
      final response = await http.get(healthUri).timeout(const Duration(seconds: 5));
      stopwatch.stop();

      final latencyMs = stopwatch.elapsedMilliseconds;

      if (response.statusCode == 200) {
        if (latencyMs >= 2500) {
          newStatus = NetworkStatus.slow;
        } else {
          newStatus = NetworkStatus.online;
        }
        _lastSuccessfulPing = DateTime.now();
        lastSyncNotifier.value = _lastSuccessfulPing;
      } else {
        newStatus = NetworkStatus.offline;
      }
    } on TimeoutException {
      stopwatch.stop();
      newStatus = NetworkStatus.slow; // Request timed out or network is crawling
    } on SocketException {
      stopwatch.stop();
      newStatus = NetworkStatus.offline;
    } catch (_) {
      stopwatch.stop();
      newStatus = NetworkStatus.offline;
    } finally {
      _isChecking = false;
    }

    _updateStatus(newStatus, previousStatus);
    return newStatus;
  }

  void _updateStatus(NetworkStatus newStatus, NetworkStatus previousStatus) {
    if (newStatus != previousStatus) {
      _status = newStatus;
      statusNotifier.value = newStatus;
      debugPrint('📶 Network status changed: $previousStatus -> $newStatus');

      // Handle transitions
      if (newStatus == NetworkStatus.offline) {
        _showDebouncedNotification(
          title: 'No Internet Connection',
          message: 'Please check your network. Cached data is currently displayed.',
          type: AppNotificationType.error,
          key: 'offline',
        );
      } else if (newStatus == NetworkStatus.slow) {
        _showDebouncedNotification(
          title: 'Slow Connection',
          message: 'Network is slow or unstable. Some updates may take longer.',
          type: AppNotificationType.warning,
          key: 'slow',
        );
      } else if (newStatus == NetworkStatus.online && previousStatus == NetworkStatus.offline) {
        _showDebouncedNotification(
          title: 'Connection Restored',
          message: 'Internet connection is back. Synchronizing live data...',
          type: AppNotificationType.success,
          key: 'restored',
        );

        // Reconnect real-time sockets
        SocketService.connect();

        // Trigger restore callbacks
        for (final callback in _onConnectionRestoredCallbacks) {
          try {
            callback();
          } catch (e) {
            debugPrint('Error in connection restored callback: $e');
          }
        }
      }
    }
  }

  void _showDebouncedNotification({
    required String title,
    required String message,
    required AppNotificationType type,
    required String key,
  }) {
    final now = DateTime.now();
    if (_lastNotificationType == key &&
        _lastNotificationTime != null &&
        now.difference(_lastNotificationTime!).inSeconds < 10) {
      return; // Do not spam the user repeatedly
    }

    _lastNotificationTime = now;
    _lastNotificationType = key;

    NotificationService.show(
      title: title,
      message: message,
      type: type,
      duration: const Duration(seconds: 4),
    );
  }

  void dispose() {
    _pollingTimer?.cancel();
    statusNotifier.dispose();
    lastSyncNotifier.dispose();
  }
}
