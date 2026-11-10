import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../core/config/app_config.dart';

class SocketService {
  static io.Socket? _socket;
  static final List<void Function(Map<String, dynamic> data)> _matchUpdateListeners = [];
  static final List<void Function(Map<String, dynamic> data)> _teamUpdateListeners = [];
  static final List<void Function(Map<String, dynamic> data)> _notificationListeners = [];
  static final List<void Function(Map<String, dynamic> data)> _milestoneListeners = [];
  static final Set<String> _processedMilestoneEventIds = {};

  static String get socketUrl {
    return AppConfig.socketBaseUrl;
  }

  static final Set<String> _joinedMatches = {};
  static final List<VoidCallback> _reconnectListeners = [];

  static void connect() {
    if (_socket != null) {
      if (!_socket!.connected) {
        // Singleton socket already initialized and connecting/reconnecting
        _socket!.connect();
      }
      return;
    }

    try {
      _socket = io.io(
        socketUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling']) // Support WebSocket with Polling fallback
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(2000)
            .setReconnectionAttempts(9999)
            .setTimeout(25000)
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

    _socket!.off('milestone_celebration');
    _socket!.on('milestone_celebration', _handleMilestoneCelebration);
  }

  static void _handleMilestoneCelebration(dynamic data) {
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
      debugPrint('[MILESTONE_MANAGER_DEBUG] Milestone event received: eventId=${parsed['eventId']}, matchId=${parsed['matchId']}, type=${parsed['type']}, batsman=${parsed['batsmanName']}, runs=${parsed['runs']}');
      final eventId = parsed['eventId']?.toString();
      if (eventId != null && eventId.isNotEmpty) {
        if (_processedMilestoneEventIds.contains(eventId)) {
          debugPrint('[MILESTONE_MANAGER_DEBUG] Duplicate milestone event skipped: $eventId');
          return;
        }
        _processedMilestoneEventIds.add(eventId);
        if (_processedMilestoneEventIds.length > 200) {
          _processedMilestoneEventIds.remove(_processedMilestoneEventIds.first);
        }
      }

      for (final listener in List.of(_milestoneListeners)) {
        try {
          debugPrint('[MILESTONE_MANAGER_DEBUG] Invoking milestone listener for ${parsed['batsmanName']} (${parsed['type']} runs)');
          listener(parsed);
        } catch (e) {
          debugPrint('Error invoking milestone listener: $e');
        }
      }
    }
  }

  static void dispatchMilestone(dynamic data) {
    debugPrint('[MILESTONE_MANAGER_DEBUG] SocketService: dispatchMilestone locally called');
    _handleMilestoneCelebration(data);
  }

  static void emitMilestoneCelebration(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    final matchId = data['matchId']?.toString();
    debugPrint('[MILESTONE_DEBUG] SocketService: Emitting milestone_celebration to server for match $matchId');
    if (_socket != null && _socket!.connected) {
      _socket!.emit('milestone_celebration', data);
    }
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
      // Check if this match update bundles a fresh milestone event
      if (parsed['latestMilestone'] != null && parsed['latestMilestone'] is Map) {
        _handleMilestoneCelebration(parsed['latestMilestone']);
      }

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
      _socket!.dispose();
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

  static void listenToMilestoneCelebrations(void Function(Map<String, dynamic> data) onMilestone) {
    if (!_milestoneListeners.contains(onMilestone)) {
      _milestoneListeners.add(onMilestone);
    }
    if (_socket == null || !_socket!.connected) {
      connect();
    }
  }

  static void removeMilestoneCelebrationListener(void Function(Map<String, dynamic> data) onMilestone) {
    _milestoneListeners.remove(onMilestone);
  }

  static bool get isConnected => _socket != null && _socket!.connected;
}
