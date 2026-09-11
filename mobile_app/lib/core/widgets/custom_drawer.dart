import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom Painter for background swoosh waves matching reference deep dark teal drawer theme
class DrawerBackgroundPainter extends CustomPainter {
  const DrawerBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Gradient swoosh 1
    final path1 = Path();
    path1.moveTo(-20, size.height * 0.15);
    path1.cubicTo(
      size.width * 0.4, size.height * 0.05,
      size.width * 0.8, size.height * 0.35,
      size.width + 20, size.height * 0.25,
    );

    paint.shader = LinearGradient(
      colors: [
        const Color(0xFF028A6B).withValues(alpha: 0.15),
        const Color(0xFF10B981).withValues(alpha: 0.05),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path1, paint);

    // Gradient swoosh 2 (lower curve)
    final path2 = Path();
    path2.moveTo(-30, size.height * 0.7);
    path2.cubicTo(
      size.width * 0.5, size.height * 0.85,
      size.width * 0.7, size.height * 0.55,
      size.width + 30, size.height * 0.75,
    );

    paint.shader = LinearGradient(
      colors: [
        const Color(0xFF028A6B).withValues(alpha: 0.2),
        const Color(0xFF073835).withValues(alpha: 0.1),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(path2, paint);

    // Subtle ambient glow circles
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF028A6B).withValues(alpha: 0.12),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.2, size.height * 0.1),
        radius: 140,
      ));

    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.1), 140, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Interactive drawer item tile with touch scaling animation and active capsule gradient styling
class AnimatedDrawerTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isLogout;
  final int? badgeCount;

  const AnimatedDrawerTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isSelected = false,
    this.isLogout = false,
    this.badgeCount,
  });

  @override
  State<AnimatedDrawerTile> createState() => _AnimatedDrawerTileState();
}

class _AnimatedDrawerTileState extends State<AnimatedDrawerTile> with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _scaleController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSelected = widget.isSelected;
    final bool isLogout = widget.isLogout;

    final Color textColor = isLogout
        ? const Color(0xFFF87171)
        : (isSelected ? Colors.white : const Color(0xFF94A3B8));

    final Color iconColor = isLogout
        ? const Color(0xFFF87171)
        : (isSelected ? Colors.white : const Color(0xFF64748B));

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8, right: 36),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFF028A6B), Color(0xFF006B52)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: isLogout ? const Color(0xFFEF4444).withValues(alpha: 0.12) : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF028A6B).withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: [
              Icon(widget.icon, color: iconColor, size: 20),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  widget.title,
                  style: GoogleFonts.plusJakartaSans(
                    color: textColor,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              if (widget.badgeCount != null && widget.badgeCount! > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '${widget.badgeCount}',
                    style: GoogleFonts.plusJakartaSans(
                      color: isSelected ? const Color(0xFF028A6B) : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Profile Header Widget matching reference with active green online dot badge
class DrawerProfileHeader extends StatelessWidget {
  final String initials;
  final String name;
  final String role;

  const DrawerProfileHeader({
    super.key,
    required this.initials,
    required this.name,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Stack(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF028A6B), Color(0xFF045D48)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: const Color(0xFF064E3B), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF028A6B).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 1,
              bottom: 1,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF032221), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.6),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              role,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF6EE7B7).withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 3D Spring Animated Wrapper for main body scaling, perspective tilt, sliding and rounded border clip
class Drawer3DWrapper extends StatelessWidget {
  final AnimationController animationController;
  final Widget drawerMenu;
  final Widget child;
  final VoidCallback onTapOutsideToClose;

  const Drawer3DWrapper({
    super.key,
    required this.animationController,
    required this.drawerMenu,
    required this.child,
    required this.onTapOutsideToClose,
  });

  @override
  Widget build(BuildContext context) {
    final Animation<double> curvedAnim = CurvedAnimation(
      parent: animationController,
      curve: Curves.fastOutSlowIn,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF032221),
      body: Stack(
        children: [
          // Background Drawer Drawer View
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF032221),
                  Color(0xFF052B28),
                  Color(0xFF073835),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: CustomPaint(
              painter: const DrawerBackgroundPainter(),
              child: drawerMenu,
            ),
          ),

          // Main Body with 3D Spring Scale & Perspective Slide Animation
          AnimatedBuilder(
            animation: curvedAnim,
            builder: (context, _) {
              final double value = curvedAnim.value;
              final double slide = value * 245.0;
              final double scale = 1.0 - (value * 0.16); // 1.0 -> 0.84 scale
              final double radius = value * 28.0;

              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0008) // Subtle 3D perspective depth
                  ..multiply(Matrix4.translationValues(slide, 0.0, 0.0))
                  ..rotateY(-value * (math.pi / 30)) // Soft Y axis tilt angle
                  ..multiply(Matrix4.diagonal3Values(scale, scale, 1.0)),
                alignment: Alignment.centerLeft,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: value > 0.01
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 4,
                              offset: const Offset(-15, 15),
                            ),
                            BoxShadow(
                              color: const Color(0xFF028A6B).withValues(alpha: 0.25),
                              blurRadius: 20,
                              offset: const Offset(-5, 5),
                            ),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(radius),
                    child: Stack(
                      children: [
                        child,
                        // Gesture overlay to close drawer when tapping content area while open
                        if (value > 0)
                          Positioned.fill(
                            child: GestureDetector(
                              onTap: onTapOutsideToClose,
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                color: Colors.transparent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
