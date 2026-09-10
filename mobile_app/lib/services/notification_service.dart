// lib/services/notification_service.dart
// Notification Push Handling Service (Firebase Messaging + Socket.io fallback)

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'notification_cache_service.dart';
import 'socket_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling background FCM message: ${message.messageId}");
  await NotificationCacheService.init();
  final data = message.data;
  final notification = message.notification;

  await NotificationCacheService.saveOrUpdateNotification({
    'id': message.messageId ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}',
    'title': notification?.title ?? data['title'] ?? 'CricketVerse Alert',
    'body': notification?.body ?? data['body'] ?? data['message'] ?? '',
    'type': data['type'] ?? 'match',
    'timestamp': DateTime.now().toIso8601String(),
    'read': false,
    'data': data,
  });
}

class NotificationService {
  static FirebaseMessaging? _fcm;
  static bool _isFirebaseInitialized = false;

  /// Initialize Firebase Messaging & Socket listeners
  static Future<void> init() async {
    try {
      await Firebase.initializeApp();
      _isFirebaseInitialized = true;
      _fcm = FirebaseMessaging.instance;

      // Request notification permissions
      NotificationSettings settings = await _fcm!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
      }

      // Foreground FCM message listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
        debugPrint('Received foreground FCM message: ${message.notification?.title}');
        final notification = message.notification;
        final data = message.data;

        await NotificationCacheService.saveOrUpdateNotification({
          'id': message.messageId ?? 'fcm_${DateTime.now().millisecondsSinceEpoch}',
          'title': notification?.title ?? data['title'] ?? 'CricketVerse Alert',
          'body': notification?.body ?? data['body'] ?? data['message'] ?? '',
          'type': data['type'] ?? 'match',
          'timestamp': DateTime.now().toIso8601String(),
          'read': false,
          'data': data,
        });
      });

      // Background FCM handler registration
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Notification tap / deep-link handler
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Notification opened app: ${message.data}');
      });

      // Get FCM token
      final token = await _fcm!.getToken();
      if (token != null) {
        debugPrint('FCM Device Token retrieved.');
      }
    } catch (e) {
      debugPrint('NotificationService init fallback (Firebase options not set): $e');
    }

    // Connect Socket.io live notification listener as global fallback/supplement
    _initSocketNotificationListener();
  }

  /// Listen to global Socket.io notifications and cache them in Hive
  static void _initSocketNotificationListener() {
    SocketService.listenToGlobalNotifications((data) async {
      await NotificationCacheService.saveOrUpdateNotification({
        'id': data['id'] ?? 'sock_${DateTime.now().millisecondsSinceEpoch}',
        'title': data['title'] ?? 'Live Match Update',
        'body': data['message'] ?? data['body'] ?? '',
        'type': data['type'] ?? 'match',
        'timestamp': DateTime.now().toIso8601String(),
        'read': false,
        'data': data,
      });
    });
  }

  /// Get active FCM token
  static Future<String?> getDeviceToken() async {
    if (!_isFirebaseInitialized || _fcm == null) return null;
    try {
      return await _fcm!.getToken();
    } catch (e) {
      return null;
    }
  }
}
