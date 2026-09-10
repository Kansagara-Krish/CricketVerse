// lib/services/notification_cache_service.dart
// Local Notification Cache Service using Hive CE

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class NotificationCacheService {
  static const String _boxName = 'notification_cache_box';
  static Box? _box;
  static const int _maxCacheLimit = 50;

  /// Initialize Hive CE box for notification history
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      _box = await Hive.openBox(_boxName);
    } catch (e) {
      debugPrint('NotificationCacheService init error: $e');
    }
  }

  static Box get _getBox {
    if (_box == null || !_box!.isOpen) {
      throw Exception('NotificationCacheService Hive box is not initialized.');
    }
    return _box!;
  }

  /// Retrieve all cached notifications sorted by timestamp (newest first)
  static List<Map<String, dynamic>> getCachedNotifications() {
    try {
      final box = _getBox;
      final rawList = box.values.toList();
      final List<Map<String, dynamic>> notifications = [];

      for (final item in rawList) {
        if (item is Map) {
          notifications.add(Map<String, dynamic>.from(item));
        }
      }

      // Sort by timestamp descending
      notifications.sort((a, b) {
        final tA = a['timestamp'] ?? a['time'] ?? '';
        final tB = b['timestamp'] ?? b['time'] ?? '';
        return tB.toString().compareTo(tA.toString());
      });

      return notifications;
    } catch (e) {
      debugPrint('NotificationCacheService getCachedNotifications error: $e');
      return [];
    }
  }

  /// Add or update a notification in Hive CE (De-duplicates by ID)
  static Future<void> saveOrUpdateNotification(Map<String, dynamic> notif) async {
    try {
      final box = _getBox;
      final String id = notif['id']?.toString() ?? 'notif_${DateTime.now().millisecondsSinceEpoch}';
      
      final Map<String, dynamic> formattedNotif = {
        'id': id,
        'title': notif['title'] ?? 'Match Update',
        'body': notif['body'] ?? notif['message'] ?? '',
        'type': notif['type'] ?? 'match',
        'time': notif['time'] ?? notif['timestamp'] ?? 'Just now',
        'timestamp': notif['timestamp'] ?? DateTime.now().toIso8601String(),
        'read': notif['read'] ?? notif['isRead'] ?? false,
        'data': notif['data'] ?? {},
      };

      // Store in Hive box
      await box.put(id, formattedNotif);

      // Enforce maximum cache limit (keep latest 50)
      if (box.length > _maxCacheLimit) {
        final allNotifs = getCachedNotifications();
        if (allNotifs.length > _maxCacheLimit) {
          final toRemove = allNotifs.sublist(_maxCacheLimit);
          for (final item in toRemove) {
            await box.delete(item['id']);
          }
        }
      }
    } catch (e) {
      debugPrint('NotificationCacheService saveOrUpdateNotification error: $e');
    }
  }

  /// Save multiple notifications fetched from API (Merge with Hive cache)
  static Future<void> mergeNotifications(List<Map<String, dynamic>> apiNotifications) async {
    for (final notif in apiNotifications) {
      await saveOrUpdateNotification(notif);
    }
  }

  /// Mark single notification as read
  static Future<void> markAsRead(String id) async {
    try {
      final box = _getBox;
      final existing = box.get(id);
      if (existing is Map) {
        final updated = Map<String, dynamic>.from(existing);
        updated['read'] = true;
        await box.put(id, updated);
      }
    } catch (e) {
      debugPrint('NotificationCacheService markAsRead error: $e');
    }
  }

  /// Mark all cached notifications as read
  static Future<void> markAllAsRead() async {
    try {
      final box = _getBox;
      for (final key in box.keys) {
        final existing = box.get(key);
        if (existing is Map) {
          final updated = Map<String, dynamic>.from(existing);
          updated['read'] = true;
          await box.put(key, updated);
        }
      }
    } catch (e) {
      debugPrint('NotificationCacheService markAllAsRead error: $e');
    }
  }

  /// Delete a single notification from Hive
  static Future<void> deleteNotification(String id) async {
    try {
      final box = _getBox;
      await box.delete(id);
    } catch (e) {
      debugPrint('NotificationCacheService deleteNotification error: $e');
    }
  }

  /// Calculate total persistent unread notification count
  static int getUnreadCount() {
    try {
      final notifs = getCachedNotifications();
      return notifs.where((n) => (n['read'] ?? false) == false).length;
    } catch (e) {
      return 0;
    }
  }

  /// Clear all cached notifications (on logout)
  static Future<void> clearCache() async {
    try {
      final box = _getBox;
      await box.clear();
    } catch (e) {
      debugPrint('NotificationCacheService clearCache error: $e');
    }
  }
}
