// lib/core/widgets/team_logo.dart
// Unified TeamLogo widget with custom gradients and icons based on team names

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';

class TeamLogo extends StatelessWidget {
  final String teamName;
  final String shortName;
  final String logoColorHex;
  final double size;

  const TeamLogo({
    Key? key,
    required this.teamName,
    required this.shortName,
    required this.logoColorHex,
    this.size = 40,
  }) : super(key: key);

  factory TeamLogo.fromTeam(Team team, {double size = 40}) {
    return TeamLogo(
      teamName: team.name,
      shortName: team.shortName,
      logoColorHex: team.logoColorHex,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final int intColor = int.tryParse(logoColorHex) ?? 0xFF0284C7;
    final Color primaryColor = Color(intColor);
    
    // Create a beautiful gradient using the team color and a slightly darker shade
    final HSLColor hsl = HSLColor.fromColor(primaryColor);
    final Color darkerColor = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
    final Color lighterColor = hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();

    Widget logoContent;
    final nameLower = teamName.toLowerCase();
    
    if (nameLower.contains('titan')) {
      logoContent = Icon(Icons.flash_on_rounded, color: Colors.white, size: size * 0.55);
    } else if (nameLower.contains('warrior')) {
      logoContent = Icon(Icons.shield_rounded, color: Colors.white, size: size * 0.55);
    } else if (nameLower.contains('challenger')) {
      logoContent = Icon(Icons.emoji_events_rounded, color: Colors.white, size: size * 0.55);
    } else if (nameLower.contains('striker')) {
      logoContent = Icon(Icons.bolt_rounded, color: Colors.white, size: size * 0.55);
    } else if (nameLower.contains('legend')) {
      logoContent = Icon(Icons.workspace_premium_rounded, color: Colors.white, size: size * 0.55);
    } else {
      // Fallback to stylized text logo
      logoContent = Text(
        shortName,
        style: GoogleFonts.outfit(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.35,
          letterSpacing: -0.5,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [lighterColor, darkerColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: size * 0.25,
            spreadRadius: 1,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: Center(
        child: logoContent,
      ),
    );
  }
}
