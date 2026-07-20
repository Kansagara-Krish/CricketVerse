// lib/core/widgets/team_logo.dart
// Unified TeamLogo widget with professional sports club crests and shields

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';

class TeamLogo extends StatelessWidget {
  final String teamName;
  final String shortName;
  final String logoColorHex;
  final double size;

  const TeamLogo({
    super.key,
    required this.teamName,
    required this.shortName,
    required this.logoColorHex,
    this.size = 40,
  });

  factory TeamLogo.fromTeam(Team team, {double size = 40}) {
    return TeamLogo(
      teamName: team.name,
      shortName: team.shortName,
      logoColorHex: team.logoColorHex,
      size: size,
    );
  }

  String _getInitials() {
    final source = shortName.isNotEmpty ? shortName : teamName;
    final clean = source.replaceAll(RegExp(r'[^a-zA-Z0-9\s-]'), '');
    final parts = clean.split(RegExp(r'[\s-]+')).where((p) => p.isNotEmpty).toList();
    
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final p = parts[0];
      return p.length > 1 ? p.substring(0, 2).toUpperCase() : p.toUpperCase();
    }
    
    // Extract first letter of first part and last part (e.g. UVPCE - A -> UA)
    final first = parts.first.substring(0, 1).toUpperCase();
    final last = parts.last.substring(0, 1).toUpperCase();
    if (first == last) return first;
    return '$first$last';
  }

  @override
  Widget build(BuildContext context) {
    final int intColor = int.tryParse(logoColorHex) ?? 0xFF028A6B;
    final Color primaryColor = Color(intColor);
    
    // Calculate secondary contrasting shade for stripes/patterns
    final HSLColor hsl = HSLColor.fromColor(primaryColor);
    final Color secondaryColor = hsl.withLightness(
      (hsl.lightness > 0.5 ? hsl.lightness - 0.25 : hsl.lightness + 0.25).clamp(0.0, 1.0)
    ).toColor();

    Widget logoContent;
    final nameLower = teamName.toLowerCase();
    
    if (nameLower.contains('titan') || nameLower.contains('lightning')) {
      logoContent = Icon(Icons.flash_on_rounded, color: Colors.white, size: size * 0.45);
    } else if (nameLower.contains('warrior') || nameLower.contains('knight')) {
      logoContent = Icon(Icons.shield_rounded, color: Colors.white, size: size * 0.45);
    } else if (nameLower.contains('challenger')) {
      logoContent = Icon(Icons.emoji_events_rounded, color: Colors.white, size: size * 0.45);
    } else if (nameLower.contains('striker') || nameLower.contains('bolt')) {
      logoContent = Icon(Icons.bolt_rounded, color: Colors.white, size: size * 0.45);
    } else if (nameLower.contains('legend') || nameLower.contains('royal') || nameLower.contains('king')) {
      logoContent = Icon(Icons.workspace_premium_rounded, color: Colors.white, size: size * 0.45);
    } else if (nameLower.contains('star')) {
      logoContent = Icon(Icons.star_rounded, color: Colors.white, size: size * 0.45);
    } else if (nameLower.contains('falcon') || nameLower.contains('eagle')) {
      logoContent = Icon(Icons.air_rounded, color: Colors.white, size: size * 0.45);
    } else {
      // Initials fallback with scale safety
      final initials = _getInitials();
      logoContent = FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          initials,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.32,
            letterSpacing: -0.5,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: size * 0.2,
            spreadRadius: 0.5,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Dynamic Custom Painted Shield Crest
          Positioned.fill(
            child: CustomPaint(
              painter: CrestPainter(
                primaryColor: primaryColor,
                secondaryColor: secondaryColor,
                teamName: teamName,
              ),
            ),
          ),
          // Centered content, offset slightly upward to align with shield's center of mass
          Align(
            alignment: const Alignment(0, -0.15),
            child: FractionallySizedBox(
              widthFactor: 0.65,
              heightFactor: 0.65,
              child: Center(
                child: logoContent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CrestPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final String teamName;

  CrestPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.teamName,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()..isAntiAlias = true;

    // 1. Draw outer gold/silver border shield path
    final borderPath = Path()
      ..moveTo(w * 0.5, 0)
      ..lineTo(w, h * 0.12)
      ..lineTo(w, h * 0.6)
      ..quadraticBezierTo(w, h * 0.85, w * 0.5, h)
      ..quadraticBezierTo(0, h * 0.85, 0, h * 0.6)
      ..lineTo(0, h * 0.12)
      ..close();

    // Determine border color: silver border if primary is gold, else gold border
    final isPrimaryGold = primaryColor.r > 0.86 && primaryColor.g > 0.58 && primaryColor.b < 0.40;
    final borderGradient = isPrimaryGold
        ? const LinearGradient(
            colors: [Color(0xFFE2E8F0), Color(0xFF94A3B8), Color(0xFFF1F5F9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFD4AF37), Color(0xFFF59E0B), Color(0xFF9A7B1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    paint.shader = borderGradient.createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(borderPath, paint);

    // 2. Draw inner shield path (deflated for border spacing)
    final double borderSize = w * 0.07;
    final innerPath = Path()
      ..moveTo(w * 0.5, borderSize)
      ..lineTo(w - borderSize, h * 0.12 + borderSize * 0.4)
      ..lineTo(w - borderSize, h * 0.6 - borderSize * 0.4)
      ..quadraticBezierTo(w - borderSize, h * 0.83 - borderSize, w * 0.5, h - borderSize)
      ..quadraticBezierTo(borderSize, h * 0.83 - borderSize, borderSize, h * 0.6 - borderSize * 0.4)
      ..lineTo(borderSize, h * 0.12 + borderSize * 0.4)
      ..close();

    paint.shader = null;
    paint.color = primaryColor;
    canvas.drawPath(innerPath, paint);

    // 3. Draw vertical stripes or diagonal sash inside inner shield
    canvas.save();
    canvas.clipPath(innerPath);

    final nameLower = teamName.toLowerCase();
    if (nameLower.contains('warrior') || nameLower.contains('titan') || nameLower.contains('a')) {
      // Sporty vertical stripes
      final stripePaint = Paint()..color = secondaryColor.withValues(alpha: 0.28);
      final double stripeWidth = w * 0.12;
      for (double x = borderSize; x < w - borderSize; x += stripeWidth * 2) {
        canvas.drawRect(Rect.fromLTWH(x, 0, stripeWidth, h), stripePaint);
      }
    } else {
      // Sporty diagonal sash
      final sashPaint = Paint()
        ..color = secondaryColor.withValues(alpha: 0.32)
        ..strokeWidth = w * 0.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(borderSize, borderSize), Offset(w - borderSize, h - borderSize), sashPaint);
    }

    // 4. Subtle Radial shading inside for 3D depth
    final shadowPaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
      ).createShader(Rect.fromLTWH(borderSize, borderSize, w - borderSize * 2, h - borderSize * 2));
    canvas.drawPath(innerPath, shadowPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CrestPainter oldDelegate) =>
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.secondaryColor != secondaryColor ||
      oldDelegate.teamName != teamName;
}
