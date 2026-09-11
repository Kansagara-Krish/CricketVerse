import 'package:flutter/material.dart';
import 'app_notification.dart';

enum NotificationType { success, error, info, warning }

/// Legacy compatibility bridge for [CustomNotification].
/// All notifications are seamlessly routed through the modern [AppNotification] system.
class CustomNotification {
  static void show(
    BuildContext context,
    String message, {
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    AppNotificationType mappedType;
    String defaultTitle;

    switch (type) {
      case NotificationType.success:
        mappedType = AppNotificationType.success;
        defaultTitle = 'Success';
        break;
      case NotificationType.error:
        mappedType = AppNotificationType.error;
        defaultTitle = 'Attention';
        break;
      case NotificationType.warning:
        mappedType = AppNotificationType.warning;
        defaultTitle = 'Notice';
        break;
      case NotificationType.info:
        mappedType = AppNotificationType.info;
        defaultTitle = 'Information';
        break;
    }

    AppNotification.show(
      context,
      title: defaultTitle,
      message: message,
      type: mappedType,
      duration: duration,
    );
  }
}
