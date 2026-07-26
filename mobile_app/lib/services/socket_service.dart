import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'api_service.dart';

class SocketService {
  static io.Socket? _socket;
  
  static String get socketUrl {
    // Strips '/api/v1' from ApiService.baseUrl to get the server root
    return ApiService.baseUrl.replaceFirst('/api/v1', '');
  }

  static void connect() {
    if (_socket != null && _socket!.connected) return;

    try {
      _socket = io.io(socketUrl, io.OptionBuilder()
        .setTransports(['websocket']) // Use WebSocket only
        .enableAutoConnect()
        .build()
      );

      _socket!.onConnect((_) {
        debugPrint('Socket.IO connected successfully to $socketUrl');
      });

      _socket!.onDisconnect((_) {
        debugPrint('Socket.IO disconnected.');
      });

      _socket!.onConnectError((err) {
        debugPrint('Socket.IO connect error: $err');
      });
    } catch (e) {
      debugPrint('Error starting Socket.IO: $e');
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
    if (_socket == null || !_socket!.connected) {
      connect();
    }
    _socket?.emit('join_match', {'matchId': matchId});
    debugPrint('Socket emitted join_match for match: $matchId');
  }

  static void leaveMatch(String matchId) {
    _socket?.emit('leave_match', {'matchId': matchId});
    debugPrint('Socket emitted leave_match for match: $matchId');
  }

  static void listenToMatchUpdates(void Function(Map<String, dynamic> data) onUpdate) {
    if (_socket == null) return;
    _socket!.off('match_update'); // Clear previous listeners
    _socket!.on('match_update', (data) {
      debugPrint('Received match_update event from server.');
      if (data is Map<String, dynamic>) {
        onUpdate(data);
      } else if (data is String) {
        // Fallback in case payload is encoded as a string
        try {
          onUpdate(Map<String, dynamic>.from(data as Map));
        } catch (_) {}
      }
    });
  }

  static bool get isConnected => _socket != null && _socket!.connected;
}
