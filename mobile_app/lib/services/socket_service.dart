import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_service.dart';

class SocketService {
  static io.Socket? _socket;
  static final List<void Function(Map<String, dynamic> data)> _matchUpdateListeners = [];
  static final List<void Function(Map<String, dynamic> data)> _teamUpdateListeners = [];
  static final List<void Function(Map<String, dynamic> data)> _notificationListeners = [];

  static String get socketUrl {
    // Strips '/api/v1' from ApiService.baseUrl to get the server root
    return ApiService.baseUrl.replaceFirst('/api/v1', '');
  }

  static final Set<String> _joinedMatches = {};
  static final List<VoidCallback> _reconnectListeners = [];

  static void connect() {
    if (_socket != null && _socket!.connected) return;

    try {
      _socket = io.io(
        socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket']) // Use WebSocket only
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(1000)
            .setReconnectionAttempts(9999)
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('Socket.IO connected successfully to $socketUrl');
        _registerInternalListeners();
        // Re-join any active match rooms automatically upon reconnect
        for (final matchId in _joinedMatches) {
          _socket!.emit('join_match', {'matchId': matchId});
          debugPrint('Socket auto-rejoined match room: $matchId');
        }
        for (final listener in List.of(_reconnectListeners)) {
          try {
            listener();
          } catch (e) {
            debugPrint('Error invoking reconnect listener: $e');
          }
        }
      });

      _socket!.onReconnect((_) {
        debugPrint('Socket.IO reconnected to $socketUrl');
        for (final matchId in _joinedMatches) {
          _socket!.emit('join_match', {'matchId': matchId});
        }
      });

      _socket!.onDisconnect((_) {
        debugPrint('Socket.IO disconnected.');
      });

      _socket!.onConnectError((err) {
        debugPrint('Socket.IO connect error: $err');
      });

      _registerInternalListeners();
    } catch (e) {
      debugPrint('Error starting Socket.IO: $e');
    }
  }

  static void _registerInternalListeners() {
    if (_socket == null) return;

    _socket!.off('match_update');
    _socket!.on('match_update', _handleMatchUpdate);

    _socket!.off('global_match_update');
    _socket!.on('global_match_update', _handleMatchUpdate);

    _socket!.off('team_update');
    _socket!.on('team_update', _handleTeamUpdate);

    _socket!.off('global_team_update');
    _socket!.on('global_team_update', _handleTeamUpdate);

    _socket!.off('global_notification');
    _socket!.on('global_notification', _handleNotification);
  }

  static void _handleMatchUpdate(dynamic data) {
    debugPrint('Received match_update event from server.');
    Map<String, dynamic>? parsed;
    if (data is Map<String, dynamic>) {
      parsed = data;
    } else if (data is Map) {
      parsed = Map<String, dynamic>.from(data);
    } else if (data is String) {
      try {
        parsed = Map<String, dynamic>.from(jsonDecode(data));
      } catch (_) {}
    }

    if (parsed != null) {
      for (final listener in List.of(_matchUpdateListeners)) {
        try {
          listener(parsed);
        } catch (e) {
          debugPrint('Error invoking match_update listener: $e');
        }
      }
    }
  }

  static void _handleTeamUpdate(dynamic data) {
    debugPrint('Received team_update event from server.');
    Map<String, dynamic>? parsed;
    if (data is Map<String, dynamic>) {
      parsed = data;
    } else if (data is Map) {
      parsed = Map<String, dynamic>.from(data);
    } else if (data is String) {
      try {
        parsed = Map<String, dynamic>.from(jsonDecode(data));
      } catch (_) {}
    }

    if (parsed != null) {
      for (final listener in List.of(_teamUpdateListeners)) {
        try {
          listener(parsed);
        } catch (e) {
          debugPrint('Error invoking team_update listener: $e');
        }
      }
    }
  }

  static void _handleNotification(dynamic data) {
    debugPrint('Received global_notification event from server.');
    Map<String, dynamic>? parsed;
    if (data is Map<String, dynamic>) {
      parsed = data;
    } else if (data is Map) {
      parsed = Map<String, dynamic>.from(data);
    }

    if (parsed != null) {
      for (final listener in List.of(_notificationListeners)) {
        try {
          listener(parsed);
        } catch (e) {
          debugPrint('Error invoking notification listener: $e');
        }
      }
    }
  }

  static void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      debugPrint('Socket.IO disconnected manually.');
    }
  }

  static void joinMatch(String matchId) {
    if (matchId.isEmpty) return;
    _joinedMatches.add(matchId);
    if (_socket == null || !_socket!.connected) {
      connect();
    }
    _socket?.emit('join_match', {'matchId': matchId});
    debugPrint('Socket emitted join_match for match: $matchId');
  }

  static void leaveMatch(String matchId) {
    _joinedMatches.remove(matchId);
    _socket?.emit('leave_match', {'matchId': matchId});
    debugPrint('Socket emitted leave_match for match: $matchId');
  }

  static void addReconnectListener(VoidCallback onReconnect) {
    if (!_reconnectListeners.contains(onReconnect)) {
      _reconnectListeners.add(onReconnect);
    }
  }

  static void removeReconnectListener(VoidCallback onReconnect) {
    _reconnectListeners.remove(onReconnect);
  }

  static void listenToMatchUpdates(void Function(Map<String, dynamic> data) onUpdate) {
    if (!_matchUpdateListeners.contains(onUpdate)) {
      _matchUpdateListeners.add(onUpdate);
    }
    if (_socket == null || !_socket!.connected) {
      connect();
    }
  }

  static void removeMatchUpdateListener(void Function(Map<String, dynamic> data) onUpdate) {
    _matchUpdateListeners.remove(onUpdate);
  }

  static void listenToTeamUpdates(void Function(Map<String, dynamic> data) onUpdate) {
    if (!_teamUpdateListeners.contains(onUpdate)) {
      _teamUpdateListeners.add(onUpdate);
    }
    if (_socket == null || !_socket!.connected) {
      connect();
    }
  }

  static void removeTeamUpdateListener(void Function(Map<String, dynamic> data) onUpdate) {
    _teamUpdateListeners.remove(onUpdate);
  }

  static void listenToGlobalNotifications(void Function(Map<String, dynamic> data) onNotification) {
    if (!_notificationListeners.contains(onNotification)) {
      _notificationListeners.add(onNotification);
    }
    if (_socket == null || !_socket!.connected) {
      connect();
    }
  }

  static void removeNotificationListener(void Function(Map<String, dynamic> data) onNotification) {
    _notificationListeners.remove(onNotification);
  }

  static bool get isConnected => _socket != null && _socket!.connected;
}
