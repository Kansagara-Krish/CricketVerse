// lib/core/widgets/logout_dialog.dart
// Premium animated logout dialog matching exact reference screenshot with mint watermarks, red icon badge, and green CTA

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LogoutDialog {
  static Future<bool?> show(BuildContext context) {
    return showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'LogoutConfirmDialog',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final double scale = Tween<double>(begin: 0.85, end: 1.0)
            .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack))
            .value;
        final double opacity = anim1.value;

        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8.0 * anim1.value,
            sigmaY: 8.0 * anim1.value,
          ),
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Align(
                alignment: Alignment.center,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 360),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28.0),
                        child: CustomPaint(
                          painter: const _LogoutDialogWatermarkPainter(),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24.0, 32.0, 24.0, 24.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Top Red/Pink Logout Badge
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF1F2),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF43F5E).withValues(alpha: 0.12),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 60,
                                      height: 60,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFE4E6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.logout_rounded,
                                          color: Color(0xFFE11D48),
                                          size: 30,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 22),

                                // Title
                                Text(
                                  'Logout Confirmation',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF0F172A),
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                // Subtitle message
                                Text(
                                  'Are you sure you want to sign out of CricketVerse AI? Your active session will be closed.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13.5,
                                    color: const Color(0xFF64748B),
                                    height: 1.45,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 26),

                                // Action Buttons Row
                                Row(
                                  children: [
                                    // Cancel Button (Soft white pill)
                                    Expanded(
                                      child: SizedBox(
                                        height: 50,
                                        child: OutlinedButton(
                                          onPressed: () => Navigator.pop(ctx, false),
                                          style: OutlinedButton.styleFrom(
                                            backgroundColor: const Color(0xFFF8FAFC),
                                            foregroundColor: const Color(0xFF334155),
                                            side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.2),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(28),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: Text(
                                            'Cancel',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Sign Out Button (Deep emerald green pill with arrow)
                                    Expanded(
                                      child: SizedBox(
                                        height: 50,
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF028A6B),
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(28),
                                            ),
                                            elevation: 4,
                                            shadowColor: const Color(0xFF028A6B).withValues(alpha: 0.35),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Sign Out',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14.5,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 17,
                                                color: Colors.white,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Footer subtext
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(width: 24, height: 1, color: const Color(0xFFCBD5E1)),
                                    const SizedBox(width: 8),
                                    Text(
                                      'See you again soon!',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11.5,
                                        color: const Color(0xFF94A3B8),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(width: 24, height: 1, color: const Color(0xFFCBD5E1)),
                                  ],
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
            ),
          ),
        );
      },
    );
  }
}

/// Watermark Custom Painter for Logout Dialog matching light mint background swooshes
class _LogoutDialogWatermarkPainter extends CustomPainter {
  const _LogoutDialogWatermarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Top-right mint wave curve
    final topWavePaint = Paint()
      ..color = const Color(0xFFE6F4EA).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final topPath = Path()
      ..moveTo(size.width * 0.45, 0)
      ..cubicTo(
        size.width * 0.65,
        size.height * 0.25,
        size.width * 0.75,
        size.height * 0.05,
        size.width,
        size.height * 0.35,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(topPath, topWavePaint);

    // Bottom-right soft mint wave curve
    final bottomWavePaint = Paint()
      ..color = const Color(0xFFD1FAE5).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;

    final bottomPath = Path()
      ..moveTo(size.width * 0.55, size.height)
      ..cubicTo(
        size.width * 0.7,
        size.height * 0.75,
        size.width * 0.85,
        size.height * 0.9,
        size.width,
        size.height * 0.65,
      )
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(bottomPath, bottomWavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

