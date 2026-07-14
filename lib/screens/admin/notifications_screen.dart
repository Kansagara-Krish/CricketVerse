// lib/screens/admin/notifications_screen.dart
// Dummy notification list with mark-all-read

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ All notifications marked as read')),
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
      default: return Colors.white38;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'match': return Icons.sports_cricket;
      case 'wicket': return Icons.offline_bolt;
      case 'prediction': return Icons.auto_awesome;
      case 'milestone': return Icons.star;
      case 'schedule': return Icons.calendar_today;
      case 'alert': return Icons.warning_amber;
      case 'result': return Icons.emoji_events;
      case 'team': return Icons.groups;
      case 'tournament': return Icons.emoji_events;
      default: return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDeep,
        title: Row(
          children: [
            Text('Notifications', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            if (_unreadCount > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$_unreadCount new',
                    style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF0F172A), fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text('Mark All Read',
                style: GoogleFonts.outfit(color: AppTheme.primaryBlue, fontSize: 12)),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.notifications_off_outlined, color: const Color(0x3D0F172A), size: 60),
                  const SizedBox(height: 16),
                  Text('No Notifications', style: GoogleFonts.outfit(fontSize: 18, color: const Color(0x8A0F172A), fontWeight: FontWeight.bold)),
                  Text('You\'re all caught up!', style: GoogleFonts.outfit(fontSize: 13, color: const Color(0x610F172A))),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _notifications.length,
              itemBuilder: (_, i) {
                final n = _notifications[i];
                final isRead = n['read'] as bool;
                final color = _typeColor(n['type'] as String);
                final icon = _typeIcon(n['type'] as String);

                return Dismissible(
                  key: Key('notif_$i${n['title']}'),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _deleteNotification(i),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.accentRed.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.delete_rounded, color: AppTheme.accentRed),
                  ),
                  child: GestureDetector(
                    onTap: () => _markRead(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isRead
                            ? Colors.white.withOpacity(0.03)
                            : color.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isRead
                              ? Colors.white.withOpacity(0.06)
                              : color.withOpacity(0.25),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 20),
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
                                          fontSize: 14,
                                          fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                                          color: isRead ? Colors.white70 : Colors.white,
                                        ),
                                      ),
                                    ),
                                    if (!isRead)
                                      Container(
                                        width: 8, height: 8,
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
                                    fontSize: 12,
                                    color: const Color(0x610F172A),
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  n['time'] as String,
                                  style: GoogleFonts.outfit(fontSize: 10, color: const Color(0x3D0F172A)),
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
