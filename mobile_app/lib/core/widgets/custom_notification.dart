import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum NotificationType { success, error, info, warning }

class _NotificationData {
  final String id;
  final String message;
  final NotificationType type;
  final Duration duration;

  _NotificationData({
    required this.id,
    required this.message,
    required this.type,
    required this.duration,
  });
}

class CustomNotification {
  static _NotificationManagerState? _managerState;
  static OverlayEntry? _overlayEntry;

  static void show(
    BuildContext context,
    String message, {
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlayState = Overlay.of(context);

    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(
        builder: (context) => _NotificationManager(
          onInit: (state) {
            _managerState = state;
          },
          onDispose: () {
            _managerState = null;
            _overlayEntry = null;
          },
        ),
      );
      overlayState.insert(_overlayEntry!);
    }

    // Delay addition slightly to ensure manager is mounted/initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_managerState != null) {
        _managerState!.addNotification(message, type, duration);
      }
    });
  }
}

class _NotificationManager extends StatefulWidget {
  final Function(_NotificationManagerState) onInit;
  final VoidCallback onDispose;

  const _NotificationManager({
    required this.onInit,
    required this.onDispose,
  });

  @override
  State<_NotificationManager> createState() => _NotificationManagerState();
}

class _NotificationManagerState extends State<_NotificationManager> {
  final List<_NotificationData> _notifications = [];
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    widget.onInit(this);
  }

  void addNotification(String message, NotificationType type, Duration duration) {
    // Check for duplicate messages to avoid clutter
    if (_notifications.any((n) => n.message == message)) return;

    final data = _NotificationData(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      message: message,
      type: type,
      duration: duration,
    );

    setState(() {
      _notifications.insert(0, data);
      _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 350));
    });

    Timer(duration, () {
      removeNotification(data.id);
    });
  }

  void removeNotification(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    final removedItem = _notifications[index];
    setState(() {
      _notifications.removeAt(index);
    });

    _listKey.currentState?.removeItem(
      index,
      (context, animation) => _buildAnimatedItem(removedItem, animation, isRemoving: true),
      duration: const Duration(milliseconds: 300),
    );

    if (_notifications.isEmpty) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (_notifications.isEmpty && mounted) {
          widget.onDispose();
        }
      });
    }
  }

  Widget _buildAnimatedItem(_NotificationData item, Animation<double> animation, {bool isRemoving = false}) {
    // Left-to-right slide-in and right slide-out exit animation
    final slideAnimation = Tween<Offset>(
      begin: isRemoving ? const Offset(1.2, 0.0) : const Offset(-1.2, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: animation,
      curve: isRemoving ? Curves.easeIn : Curves.easeOutBack,
    ));

    return SlideTransition(
      position: slideAnimation,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6.0),
        child: _NotificationBannerWidget(
          key: ValueKey(item.id),
          message: item.message,
          type: item.type,
          onDismiss: () => removeNotification(item.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.45,
          ),
          width: MediaQuery.of(context).size.width,
          child: Material(
            color: Colors.transparent,
            child: AnimatedList(
              key: _listKey,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              initialItemCount: _notifications.length,
              itemBuilder: (context, index, animation) {
                if (index >= _notifications.length) return const SizedBox.shrink();
                return _buildAnimatedItem(_notifications[index], animation);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationBannerWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;

  const _NotificationBannerWidget({
    super.key,
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_NotificationBannerWidget> createState() => _NotificationBannerWidgetState();
}

class _NotificationBannerWidgetState extends State<_NotificationBannerWidget> {
  void _showDetailDialog(Color primaryColor, String badgeText, IconData icon) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 12,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: primaryColor, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      badgeText,
                      style: GoogleFonts.plusJakartaSans(
                        color: primaryColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  widget.message,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 20),
                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    'Received at ${DateTime.now().toLocal().toString().substring(11, 16)}',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor;
    Color bgGradientStart;
    IconData icon;
    String badgeText;

    switch (widget.type) {
      case NotificationType.success:
        primaryColor = const Color(0xFF10B981);
        bgGradientStart = const Color(0xFFECFDF5);
        icon = Icons.check_circle_rounded;
        badgeText = 'SUCCESS';
        break;
      case NotificationType.error:
        primaryColor = const Color(0xFFEF4444);
        bgGradientStart = const Color(0xFFFEF2F2);
        icon = Icons.error_rounded;
        badgeText = 'ALERT';
        break;
      case NotificationType.warning:
        primaryColor = const Color(0xFFF59E0B);
        bgGradientStart = const Color(0xFFFFFBEB);
        icon = Icons.warning_rounded;
        badgeText = 'NOTICE';
        break;
      case NotificationType.info:
        primaryColor = const Color(0xFF028A6B);
        bgGradientStart = const Color(0xFFF0FDF4);
        icon = Icons.info_rounded;
        badgeText = 'INFO';
        break;
    }

    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => widget.onDismiss(),
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          if (details.delta.dy > 6) {
            _showDetailDialog(primaryColor, badgeText, icon);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryColor.withOpacity(0.35), width: 1.5),
            gradient: LinearGradient(
              colors: [bgGradientStart, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.12),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.plusJakartaSans(
                          color: primaryColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF94A3B8)),
                onPressed: widget.onDismiss,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
