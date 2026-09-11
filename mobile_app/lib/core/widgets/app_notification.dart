// lib/core/widgets/app_notification.dart
// CricketVerse AI — Premium 3D Glassmorphic Stacked Notification System
// Features:
// - Single notification: Compact 3D floating glass card with top->bottom bounce entry.
// - Multiple notifications: Layered 3D card deck (stack mode) with subtle peek depth.
// - Smooth spring / bounce on new notification arrival, smoothly tucking older cards behind.
// - Tap stack to expand with full-screen Gaussian backdrop blur (sigma: 5) and subtle dimming.
// - Click outside to collapse back to compact stack.
// - Swipe-up gesture to dismiss all with velocity acceleration.
// - Individual close buttons [×] with smooth list reflow.
// - Auto-dismiss progress timer (paused when expanded or hovered).
// - Desktop / Web mouse hover support (pauses timer, subtle scale bump).
// - Responsive top-centered layout adapting to mobile, tablet, and desktop screens.
// - Dual API support: NotificationService and AppNotification facade.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Supported notification types with semantic accent colors and icons
enum AppNotificationType { success, error, warning, info }

/// View states for the notification manager
enum NotificationViewState { hidden, collapsed, expanded }

/// Internal model holding notification data
class _NotificationItem {
  final String id;
  final String title;
  final String? message;
  final AppNotificationType type;
  final Duration duration;
  final VoidCallback? onTap;
  final VoidCallback? onClose;
  final String? actionLabel;
  final VoidCallback? onAction;
  final DateTime createdAt;

  _NotificationItem({
    required this.id,
    required this.title,
    this.message,
    required this.type,
    required this.duration,
    this.onTap,
    this.onClose,
    this.actionLabel,
    this.onAction,
  }) : createdAt = DateTime.now();
}

/// Global entry point to trigger notifications from anywhere in the app
class NotificationService {
  /// Global navigator key for context-free notifications
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static _NotificationOverlayManagerState? _managerState;
  static OverlayEntry? _overlayEntry;
  static final List<_NotificationItem> _pendingItems = [];

  /// Resolves the active OverlayState safely from navigatorKey or provided context
  static OverlayState? _resolveOverlay(BuildContext? context) {
    // 1. Direct overlay from NavigatorState
    if (navigatorKey.currentState?.overlay != null) {
      return navigatorKey.currentState!.overlay;
    }

    // 2. If a local BuildContext is provided, search ancestor overlays
    if (context != null) {
      try {
        final state = Overlay.maybeOf(context, rootOverlay: true) ??
            Overlay.maybeOf(context, rootOverlay: false);
        if (state != null) return state;
      } catch (_) {}
    }

    // 3. Fallback to navigatorKey context
    final navContext = navigatorKey.currentContext;
    if (navContext != null) {
      try {
        final state = Overlay.maybeOf(navContext, rootOverlay: true) ??
            Overlay.maybeOf(navContext, rootOverlay: false);
        if (state != null) return state;
      } catch (_) {}
    }

    return null;
  }

  static void _ensureOverlayAndAdd(OverlayState overlayState, _NotificationItem item) {
    if (_overlayEntry != null && !_overlayEntry!.mounted) {
      _overlayEntry = null;
      _managerState = null;
    }

    if (_overlayEntry == null) {
      _overlayEntry = OverlayEntry(
        builder: (_) => _NotificationOverlayManager(
          onInit: (state) {
            _managerState = state;
            for (final pending in _pendingItems) {
              state.add(pending);
            }
            _pendingItems.clear();
          },
          onDispose: () {
            _managerState = null;
            _overlayEntry = null;
          },
        ),
      );
      overlayState.insert(_overlayEntry!);
    }

    if (_managerState != null) {
      _managerState!.add(item);
    } else {
      _pendingItems.add(item);
    }
  }

  /// Display a notification. If multiple arrive, they automatically stack in a 3D card deck.
  static void show({
    BuildContext? context,
    required String title,
    String? message,
    AppNotificationType type = AppNotificationType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
    VoidCallback? onClose,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final item = _NotificationItem(
      id: 'notif_${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      message: message,
      type: type,
      duration: duration,
      onTap: onTap,
      onClose: onClose,
      actionLabel: actionLabel,
      onAction: onAction,
    );

    final overlayState = _resolveOverlay(context);
    if (overlayState == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final retryOverlay = _resolveOverlay(context);
        if (retryOverlay != null) {
          _ensureOverlayAndAdd(retryOverlay, item);
        } else {
          debugPrint('NotificationService: No valid Overlay found to display notification.');
        }
      });
      return;
    }

    _ensureOverlayAndAdd(overlayState, item);
  }

  /// Convenience helper: Success notification (Mint / Emerald)
  static void success({
    BuildContext? context,
    required String title,
    String? message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
    VoidCallback? onClose,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: AppNotificationType.success,
      duration: duration,
      onTap: onTap,
      onClose: onClose,
    );
  }

  /// Convenience helper: Error notification (Crimson Red)
  static void error({
    BuildContext? context,
    required String title,
    String? message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
    VoidCallback? onClose,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: AppNotificationType.error,
      duration: duration,
      onTap: onTap,
      onClose: onClose,
    );
  }

  /// Convenience helper: Warning notification (Amber Gold)
  static void warning({
    BuildContext? context,
    required String title,
    String? message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
    VoidCallback? onClose,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: AppNotificationType.warning,
      duration: duration,
      onTap: onTap,
      onClose: onClose,
    );
  }

  /// Convenience helper: Info notification (Deep Teal / Cyan)
  static void info({
    BuildContext? context,
    required String title,
    String? message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
    VoidCallback? onClose,
  }) {
    show(
      context: context,
      title: title,
      message: message,
      type: AppNotificationType.info,
      duration: duration,
      onTap: onTap,
      onClose: onClose,
    );
  }

  /// Dismiss all currently active notifications
  static void dismissAll() {
    _managerState?.clearAll();
  }
}

/// Backwards-compatible facade for existing code calling AppNotification
class AppNotification {
  static GlobalKey<NavigatorState> get navigatorKey => NotificationService.navigatorKey;

  static void show(
    BuildContext? context, {
    required String title,
    String? message,
    AppNotificationType type = AppNotificationType.info,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
    VoidCallback? onClose,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    NotificationService.show(
      context: context,
      title: title,
      message: message,
      type: type,
      duration: duration,
      onTap: onTap,
      onClose: onClose,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  static void success(
    BuildContext? context, {
    required String title,
    String? message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
    VoidCallback? onClose,
  }) {
    NotificationService.success(
      context: context,
      title: title,
      message: message,
      duration: duration,
      onTap: onTap,
      onClose: onClose,
    );
  }

  static void error(
    BuildContext? context, {
    required String title,
    String? message,
    Duration duration = const Duration(seconds: 4),
    VoidCallback? onTap,
    VoidCallback? onClose,
  }) {
    NotificationService.error(
      context: context,
      title: title,
      message: message,
      duration: duration,
      onTap: onTap,
      onClose: onClose,
    );
  }

  static void warning(
    BuildContext? context, {
    required String title,
    String? message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
    VoidCallback? onClose,
  }) {
    NotificationService.warning(
      context: context,
      title: title,
      message: message,
      duration: duration,
      onTap: onTap,
      onClose: onClose,
    );
  }

  static void info(
    BuildContext? context, {
    required String title,
    String? message,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
    VoidCallback? onClose,
  }) {
    NotificationService.info(
      context: context,
      title: title,
      message: message,
      duration: duration,
      onTap: onTap,
      onClose: onClose,
    );
  }

  static void dismissAll() => NotificationService.dismissAll();
}

// ─────────────────────────────────────────────────────────────────────────────
// OVERLAY MANAGER: Handles 3D Stack, Expansion, Blur Backdrop, Gestures & Queue
// ─────────────────────────────────────────────────────────────────────────────

class _NotificationOverlayManager extends StatefulWidget {
  final void Function(_NotificationOverlayManagerState state) onInit;
  final VoidCallback onDispose;

  const _NotificationOverlayManager({
    required this.onInit,
    required this.onDispose,
  });

  @override
  State<_NotificationOverlayManager> createState() => _NotificationOverlayManagerState();
}

class _NotificationOverlayManagerState extends State<_NotificationOverlayManager>
    with TickerProviderStateMixin {
  final List<_NotificationItem> _items = [];
  NotificationViewState _viewState = NotificationViewState.collapsed;

  // Controllers
  late AnimationController _entryController;
  late Animation<double> _dropAnimation;
  late Animation<double> _rotationZAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  late AnimationController _progressController;
  late AnimationController _swipeDismissController;
  late Animation<Offset> _swipeDismissOffset;
  late Animation<double> _swipeDismissOpacity;

  bool _isHovered = false;
  double _dragOffsetY = 0.0;

  @override
  void initState() {
    super.initState();

    // 1. Drop-bounce entry controller (750ms)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );

    _dropAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -150.0, end: 15.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 15.0, end: -4.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -4.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 20,
      ),
    ]).animate(_entryController);

    _rotationZAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.016, end: 0.008)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.008, end: -0.002)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.002, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 20,
      ),
    ]).animate(_entryController);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.94, end: 1.025)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.025, end: 0.995)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.995, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 20,
      ),
    ]).animate(_entryController);

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.40, curve: Curves.easeOut),
      ),
    );

    // 2. Expand/Collapse controller (400ms)
    _expandController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // 3. Progress timeout controller (defaults to 3s, dynamically reset for front card)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
      value: 1.0,
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        _onFrontCardTimeout();
      }
    });

    // 4. Swipe dismiss controller
    _swipeDismissController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _swipeDismissOffset = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.0, -1.2),
    ).animate(CurvedAnimation(parent: _swipeDismissController, curve: Curves.easeInOutQuad));
    _swipeDismissOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _swipeDismissController, curve: Curves.easeInQuad),
    );

    widget.onInit(this);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _expandController.dispose();
    _progressController.dispose();
    _swipeDismissController.dispose();
    widget.onDispose();
    super.dispose();
  }

  void _restartFrontTimer() {
    if (_items.isEmpty || _viewState == NotificationViewState.expanded || _isHovered) {
      _progressController.stop();
      return;
    }
    _progressController.duration = _items.first.duration;
    _progressController.value = 1.0;
    _progressController.reverse();
  }

  void _onFrontCardTimeout() {
    if (!mounted || _items.isEmpty || _viewState == NotificationViewState.expanded) return;
    _removeFrontCard();
  }

  void _removeFrontCard() {
    if (_items.isEmpty) return;
    final item = _items.first;
    item.onClose?.call();
    setState(() {
      _items.removeAt(0);
      if (_items.isNotEmpty) {
        _entryController.forward(from: 0.45);
        _restartFrontTimer();
      } else {
        _viewState = NotificationViewState.collapsed;
        _progressController.stop();
      }
    });
  }

  void add(_NotificationItem item) {
    if (!mounted) return;
    setState(() {
      // New notification arrives at the FRONT (index 0)
      _items.insert(0, item);

      // Reset swipe animation if any
      _swipeDismissController.value = 0.0;
      _dragOffsetY = 0.0;

      // Trigger top drop bounce animation for new front card
      _entryController.forward(from: 0.0);

      // Start front timer if collapsed
      if (_viewState != NotificationViewState.expanded) {
        _restartFrontTimer();
      }
    });
  }

  void remove(String id) {
    if (!mounted) return;
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      _items[idx].onClose?.call();
      setState(() {
        _items.removeAt(idx);
        if (_items.isEmpty) {
          _viewState = NotificationViewState.collapsed;
          _expandController.value = 0.0;
          _progressController.stop();
        } else if (idx == 0 && _viewState != NotificationViewState.expanded) {
          _restartFrontTimer();
        }
      });
    }
  }

  void clearAll() {
    if (!mounted) return;
    for (final item in _items) {
      item.onClose?.call();
    }
    setState(() {
      _items.clear();
      _viewState = NotificationViewState.collapsed;
      _expandController.value = 0.0;
      _progressController.stop();
    });
  }

  void _expand() {
    if (_items.isEmpty || _viewState == NotificationViewState.expanded) return;
    setState(() {
      _viewState = NotificationViewState.expanded;
      _progressController.stop(); // Pause auto-dismiss when expanded
    });
    _expandController.forward();
  }

  void _collapse() {
    if (_viewState != NotificationViewState.expanded) return;
    _expandController.reverse().then((_) {
      if (mounted) {
        setState(() {
          _viewState = NotificationViewState.collapsed;
          _restartFrontTimer(); // Resume auto-dismiss after collapsing
        });
      }
    });
  }

  void _onSwipeDismissAll() {
    _swipeDismissController.forward().then((_) {
      if (mounted) {
        clearAll();
      }
    });
  }

  // --- Style Helpers ---
  Color _accentColor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.success:
        return const Color(0xFF10B981); // Emerald / Mint green
      case AppNotificationType.error:
        return const Color(0xFFEF4444); // Crimson red
      case AppNotificationType.warning:
        return const Color(0xFFF59E0B); // Amber gold
      case AppNotificationType.info:
        return const Color(0xFF028A6B); // Deep teal / cyan
    }
  }

  List<Color> _badgeGradient(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.success:
        return const [Color(0xFF028A6B), Color(0xFF10B981)];
      case AppNotificationType.error:
        return const [Color(0xFFDC2626), Color(0xFFF87171)];
      case AppNotificationType.warning:
        return const [Color(0xFFD97706), Color(0xFFFBBF24)];
      case AppNotificationType.info:
        return const [Color(0xFF028A6B), Color(0xFF14B8A6)];
    }
  }

  IconData _badgeIcon(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.success:
        return Icons.check_rounded;
      case AppNotificationType.error:
        return Icons.close_rounded;
      case AppNotificationType.warning:
        return Icons.priority_high_rounded;
      case AppNotificationType.info:
        return Icons.info_outline_rounded;
    }
  }

  String _cleanText(_NotificationItem item) {
    final title = item.title.trim();
    final message = item.message?.trim() ?? '';
    final isGeneric = [
      'success',
      'attention',
      'notice',
      'information',
      'error',
      'info',
      'warning',
    ].contains(title.toLowerCase());

    String raw = (isGeneric && message.isNotEmpty) ? message : (title.isNotEmpty ? title : message);

    if (raw.contains('!')) {
      raw = raw.split('!').first.trim();
    } else if (raw.contains('.')) {
      raw = raw.split('.').first.trim();
    }

    raw = raw.replaceAll(' successfully', '')
             .replaceAll('Please enter ', 'Enter ')
             .replaceAll('Please check ', 'Check ')
             .trim();

    return raw.isNotEmpty ? raw : (title.isNotEmpty ? title : 'Notification');
  }

  Widget _buildRadiantRays(Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: -0.42,
            child: Container(
              width: 2.2,
              height: 6.5,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 2.2,
            height: 8.0,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 5),
          Transform.rotate(
            angle: 0.42,
            child: Container(
              width: 2.2,
              height: 6.5,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mediaQuery = MediaQuery.of(context);
    final safeTop = mediaQuery.padding.top;
    final screenWidth = mediaQuery.size.width;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _entryController,
        _expandController,
        _progressController,
        _swipeDismissController,
      ]),
      builder: (context, _) {
        final isExpanded = _viewState == NotificationViewState.expanded || _expandController.value > 0.0;
        final expandProgress = _expandAnimation.value;

        return Stack(
          children: [
            // ─────────────────────────────────────────────────────────────
            // 1. FULL-SCREEN BLUR BACKDROP (Only active during expansion)
            // ─────────────────────────────────────────────────────────────
            if (isExpanded)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _collapse, // Tap outside closes/collapses
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 5.0 * expandProgress,
                      sigmaY: 5.0 * expandProgress,
                    ),
                    child: Container(
                      color: (isDark ? Colors.black : const Color(0xFF0F172A))
                          .withValues(alpha: 0.14 * expandProgress),
                    ),
                  ),
                ),
              ),

            // ─────────────────────────────────────────────────────────────
            // 2. TOP-CENTERED NOTIFICATION CONTAINER
            // ─────────────────────────────────────────────────────────────
            Positioned(
              top: safeTop + 10,
              left: 0,
              right: 0,
              child: Material(
                color: Colors.transparent,
                child: SlideTransition(
                  position: _swipeDismissOffset,
                  child: FadeTransition(
                    opacity: _swipeDismissOpacity,
                    child: Transform.translate(
                      offset: Offset(0, _dragOffsetY),
                      child: GestureDetector(
                        // Swipe gestures
                        onVerticalDragUpdate: (details) {
                          if (details.delta.dy < 0) {
                            setState(() {
                              _dragOffsetY = (_dragOffsetY + details.delta.dy).clamp(-120.0, 0.0);
                            });
                          }
                        },
                        onVerticalDragEnd: (details) {
                          if (_dragOffsetY < -45 ||
                              (details.primaryVelocity != null && details.primaryVelocity! < -180)) {
                            _onSwipeDismissAll();
                          } else {
                            setState(() => _dragOffsetY = 0.0);
                          }
                        },
                        child: Align(
                          alignment: Alignment.topCenter,
                          child: MouseRegion(
                            onEnter: (_) {
                              setState(() => _isHovered = true);
                              _progressController.stop();
                            },
                            onExit: (_) {
                              setState(() => _isHovered = false);
                              if (_viewState != NotificationViewState.expanded) {
                                _progressController.reverse();
                              }
                            },
                            child: isExpanded
                                ? _buildExpandedPanel(context, isDark, screenWidth, expandProgress)
                                : _buildCollapsedStack(context, isDark, screenWidth),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // COLLAPSED 3D STACKED DECK VIEW (Max 3 visible cards)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildCollapsedStack(BuildContext context, bool isDark, double screenWidth) {
    final entryVal = _entryController.value;
    final currentY = _dropAnimation.value;
    final currentRotation = _rotationZAnimation.value;
    final currentScale = _scaleAnimation.value * (_isHovered ? 1.012 : 1.0);
    final currentOpacity = _opacityAnimation.value.clamp(0.0, 1.0);

    final isOvershoot = entryVal > 0.45 && entryVal < 0.75;
    final shadowBlur = isOvershoot ? 24.0 : 16.0;

    // Up to 3 visible cards
    final visibleCount = _items.length.clamp(1, 3);
    final frontItem = _items.first;
    final accent = _accentColor(frontItem.type);

    return GestureDetector(
      onTap: _items.length > 1 ? _expand : null, // Tap stack to expand
      child: Transform.translate(
        offset: Offset(0, currentY),
        child: Transform.rotate(
          angle: currentRotation,
          child: Transform.scale(
            scale: currentScale,
            child: Opacity(
              opacity: currentOpacity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Radiant rays on top of front success card
                  if (frontItem.type == AppNotificationType.success)
                    _buildRadiantRays(accent),

                  // The 3D Layered Card Stack
                  SizedBox(
                    height: 52.0 + (visibleCount > 1 ? (visibleCount - 1) * 10.0 : 0.0),
                    child: Stack(
                      alignment: Alignment.topCenter,
                      clipBehavior: Clip.none,
                      children: [
                        // Cards rendered from back to front (reverse order)
                        for (int i = visibleCount - 1; i >= 0; i--)
                          _buildStackedCardLayer(
                            context: context,
                            item: _items[i],
                            index: i,
                            isFront: i == 0,
                            isDark: isDark,
                            screenWidth: screenWidth,
                            shadowBlur: shadowBlur,
                            isOvershoot: isOvershoot,
                          ),
                      ],
                    ),
                  ),

                  // Subtle count indicator pill (e.g. "● 2 more")
                  if (_items.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: _expand,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E293B).withValues(alpha: 0.85)
                                : Colors.white.withValues(alpha: 0.90),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.16)
                                  : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5.5,
                                height: 5.5,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF028A6B),
                                ),
                              ),
                              const SizedBox(width: 5.5),
                              Text(
                                '${_items.length - 1} more',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Single Layer in the 3D Stack ---
  Widget _buildStackedCardLayer({
    required BuildContext context,
    required _NotificationItem item,
    required int index,
    required bool isFront,
    required bool isDark,
    required double screenWidth,
    required double shadowBlur,
    required bool isOvershoot,
  }) {
    final accent = _accentColor(item.type);

    // Layer 3D styling:
    // Front card: scale 1.0, offset 0, opacity 1.0
    // 2nd card: scale 0.96, offset 10px, opacity 0.75
    // 3rd card: scale 0.92, offset 20px, opacity 0.45
    final verticalOffset = index * 10.0;
    final scale = 1.0 - (index * 0.04);
    final opacity = index == 0 ? 1.0 : (index == 1 ? 0.75 : 0.45);
    final blurSigma = index == 0 ? 0.0 : (index == 1 ? 0.5 : 1.0);

    return Positioned(
      top: verticalOffset,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: Container(
              constraints: BoxConstraints(
                minWidth: 150,
                maxWidth: (screenWidth * 0.85).clamp(200.0, 320.0),
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: isFront ? 0.20 : 0.12)
                      : Colors.white.withValues(alpha: isFront ? 0.95 : 0.80),
                  width: 1.2,
                ),
                boxShadow: isFront
                    ? [
                        // Soft glowing colored ambient tint
                        BoxShadow(
                          color: accent.withValues(alpha: isDark ? 0.22 : 0.16),
                          blurRadius: shadowBlur,
                          spreadRadius: isOvershoot ? 1.0 : 0.2,
                          offset: Offset(0, isOvershoot ? 6 : 3.5),
                        ),
                        // Soft drop shadow
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isDark
                            ? [
                                const Color(0xFF1E293B).withValues(alpha: 0.94),
                                const Color(0xFF0F172A).withValues(alpha: 0.96),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.97),
                                const Color(0xFFF2FBF7).withValues(alpha: 0.92),
                              ],
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Card Content Row
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7.5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Circular Icon Badge
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: _badgeGradient(item.type),
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: accent.withValues(alpha: 0.36),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    _badgeIcon(item.type),
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 9),

                              // Title Text
                              Flexible(
                                child: Text(
                                  _cleanText(item),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    letterSpacing: -0.15,
                                  ),
                                ),
                              ),

                              // Close button [×] on front card
                              if (isFront) ...[
                                const SizedBox(width: 8),
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: _removeFrontCard,
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.10)
                                          : Colors.black.withValues(alpha: 0.05),
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Shrinking Progress line along bottom of front card
                        if (isFront)
                          Positioned(
                            bottom: 0,
                            left: 14,
                            right: 14,
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _progressController.value.clamp(0.0, 1.0),
                              child: Container(
                                height: 1.8,
                                decoration: BoxDecoration(
                                  color: accent.withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // EXPANDED NOTIFICATION PANEL
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildExpandedPanel(
    BuildContext context,
    bool isDark,
    double screenWidth,
    double progress,
  ) {
    final panelWidth = (screenWidth * 0.90).clamp(280.0, 420.0);

    return Container(
      width: panelWidth,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.70,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle pill at top
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white38 : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),

          // Scrollable list of full glassmorphic notification cards
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.only(bottom: 8),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = _items[index];
                return _buildExpandedCardItem(context, item, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedCardItem(
    BuildContext context,
    _NotificationItem item,
    bool isDark,
  ) {
    final accent = _accentColor(item.type);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => remove(item.id),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.18)
                : Colors.white.withValues(alpha: 0.92),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: isDark ? 0.16 : 0.12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.30 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          const Color(0xFF1E293B).withValues(alpha: 0.94),
                          const Color(0xFF0F172A).withValues(alpha: 0.96),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.97),
                          const Color(0xFFF8FAFC).withValues(alpha: 0.92),
                        ],
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    item.onTap?.call();
                    remove(item.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        // Circular Icon Badge
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _badgeGradient(item.type),
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              _badgeIcon(item.type),
                              size: 17,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Title & Optional Message
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.title.trim().isNotEmpty ? item.title.trim() : _cleanText(item),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  letterSpacing: -0.15,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (item.message != null && item.message!.trim().isNotEmpty && item.message!.trim() != item.title.trim()) ...[
                                const SizedBox(height: 2),
                                Text(
                                  item.message!.trim(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),

                        // Individual Close button [×]
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => remove(item.id),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.10)
                                  : Colors.black.withValues(alpha: 0.05),
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              size: 15,
                              color: isDark ? Colors.white70 : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
