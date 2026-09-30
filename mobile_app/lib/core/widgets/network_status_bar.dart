import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/network_connectivity_service.dart';
import '../theme/app_theme.dart';

class NetworkStatusBar extends StatefulWidget {
  final int pendingCount;
  final VoidCallback? onRetry;

  const NetworkStatusBar({
    super.key,
    this.pendingCount = 0,
    this.onRetry,
  });

  @override
  State<NetworkStatusBar> createState() => _NetworkStatusBarState();
}

class _NetworkStatusBarState extends State<NetworkStatusBar> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatLastSync(DateTime? lastSync) {
    if (lastSync == null) return 'Not synced yet';
    final diff = DateTime.now().difference(lastSync);
    if (diff.inSeconds < 5) return 'Just now';
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context) {
    final netService = NetworkConnectivityService();
    final status = netService.status;
    final lastSync = netService.lastSuccessfulPing;

    // In normal online mode without pending items, show nothing or minimal sync text
    if (status == NetworkStatus.online && widget.pendingCount == 0) {
      return const SizedBox.shrink();
    }

    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String label;

    if (status == NetworkStatus.offline) {
      bgColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
      borderColor = const Color(0xFFEF4444).withValues(alpha: 0.4);
      textColor = const Color(0xFFF87171);
      icon = Icons.wifi_off_rounded;
      label = widget.pendingCount > 0
          ? 'Offline • ${widget.pendingCount} scoring action${widget.pendingCount > 1 ? "s" : ""} pending sync'
          : 'Offline • Showing cached data (Last synced: ${_formatLastSync(lastSync)})';
    } else if (status == NetworkStatus.slow) {
      bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.15);
      borderColor = const Color(0xFFF59E0B).withValues(alpha: 0.4);
      textColor = const Color(0xFFFBBF24);
      icon = Icons.network_check_rounded;
      label = 'Slow Network • Updates may take longer (Last synced: ${_formatLastSync(lastSync)})';
    } else {
      bgColor = AppTheme.primaryBlue.withValues(alpha: 0.15);
      borderColor = AppTheme.primaryBlue.withValues(alpha: 0.4);
      textColor = const Color(0xFF60A5FA);
      icon = Icons.sync_rounded;
      label = 'Syncing ${widget.pendingCount} pending update${widget.pendingCount > 1 ? "s" : ""}...';
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (widget.onRetry != null && status == NetworkStatus.offline)
            InkWell(
              onTap: widget.onRetry,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  'Retry',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
