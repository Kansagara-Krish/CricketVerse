// lib/screens/admin/notifications_screen.dart
// Notification list with mark-all-read

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/custom_notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late List<Map<String, dynamic>> _notifications;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _notifications = AppConstants.dummyNotifications
        .map((n) => {...n, 'read': false})
        .toList();
    _unreadCount = _notifications.length;
  }

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n['read'] = true;
      }
      _unreadCount = 0;
    });
    CustomNotification.show(
      context,
      'All notifications marked as read',
      type: NotificationType.success,
    );
  }

  void _markRead(int index) {
    setState(() {
      if (_notifications[index]['read'] == false) {
        _notifications[index]['read'] = true;
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      }
    });
  }

  void _deleteNotification(int index) {
    setState(() {
      if (_notifications[index]['read'] == false) {
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      }
      _notifications.removeAt(index);
    });
    CustomNotification.show(
      context,
      'Notification deleted',
      type: NotificationType.info,
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'match': return AppTheme.primaryGreen;
      case 'wicket': return AppTheme.accentRed;
      case 'prediction': return AppTheme.accentPurple;
      case 'milestone': return AppTheme.accentGold;
      case 'schedule': return AppTheme.primaryBlue;
      case 'alert': return AppTheme.accentOrange;
      case 'result': return AppTheme.primaryGreen;
      case 'team': return AppTheme.accentGold;
      case 'tournament': return AppTheme.accentPurple;
      default: return AppTheme.primaryBlue;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'match': return Icons.sports_cricket_rounded;
      case 'wicket': return Icons.offline_bolt_rounded;
      case 'prediction': return Icons.auto_awesome_rounded;
      case 'milestone': return Icons.star_rounded;
      case 'schedule': return Icons.calendar_today_rounded;
      case 'alert': return Icons.warning_amber_rounded;
      case 'result': return Icons.emoji_events_rounded;
      case 'team': return Icons.groups_rounded;
      case 'tournament': return Icons.emoji_events_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Text('Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.accentRed.withOpacity(0.3)),
                ),
                child: Text('$_unreadCount new',
                    style: GoogleFonts.outfit(fontSize: 10, color: AppTheme.accentRed, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _unreadCount > 0 ? _markAllRead : null,
            child: Text('Mark All Read',
                style: GoogleFonts.outfit(
                  color: _unreadCount > 0 ? AppTheme.primaryBlue : AppTheme.textMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                )),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_off_outlined, color: AppTheme.primaryBlue, size: 44),
                  ),
                  const SizedBox(height: 16),
                  Text('No Notifications', style: GoogleFonts.outfit(fontSize: 16, color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('You\'re all caught up!', style: GoogleFonts.outfit(fontSize: 12.5, color: AppTheme.textMuted)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _notifications.length,
              itemBuilder: (_, i) {
                final n = _notifications[i];
                final isRead = n['read'] as bool;
                final color = _typeColor(n['type'] as String);
                final icon = _typeIcon(n['type'] as String);

                return Dismissible(
                  key: Key('notif_${n['title']}_$i'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteNotification(i),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRed.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, color: AppTheme.accentRed),
                  ),
                  child: GestureDetector(
                    onTap: () => _markRead(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isRead ? const Color(0xFFE2E8F0) : color.withOpacity(0.3),
                          width: isRead ? 1 : 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n['title'] as String,
                                        style: GoogleFonts.outfit(
                                          fontSize: 13.5,
                                          fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                          color: isRead ? AppTheme.textSecondary : AppTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 7, height: 7,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: color,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  n['body'] as String,
                                  style: GoogleFonts.outfit(
                                    fontSize: 12.5,
                                    color: AppTheme.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  n['time'] as String,
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
