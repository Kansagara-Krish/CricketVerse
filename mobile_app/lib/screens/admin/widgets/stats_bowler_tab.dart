import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/routes/app_routes.dart';
import '../../../models/models.dart';

class StatsBowlerTab extends StatelessWidget {
  final List<Player> players;

  const StatsBowlerTab({super.key, required this.players});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: players.length,
      itemBuilder: (context, i) {
        final p = players[i];
        final eco = p.oversBowled > 0 ? p.runsConceded / p.oversBowled : 0.0;
        final initials = p.name.split(' ').map((n) => n[0]).join().toUpperCase();

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.bgSurface),
          ),
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.playerDetail, arguments: p),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Rank Badge
                  _buildRankBadge(i),
                  const SizedBox(width: 14),

                  // Player initials avatar
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.bgSurface,
                    child: Text(
                      initials.substring(0, initials.length > 2 ? 2 : initials.length),
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondary, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name & Role
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${p.role} • ${p.nationality}',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),

                  // Stats values
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${p.wicketsTaken}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.accentRed),
                          ),
                          Text(
                            'wkts',
                            style: GoogleFonts.plusJakartaSans(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(width: 18),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            eco.toStringAsFixed(1),
                            style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                          ),
                          Text(
                            'eco',
                            style: GoogleFonts.plusJakartaSans(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRankBadge(int index) {
    final rank = index + 1;
    Color badgeColor = AppTheme.bgSurface;
    Color textColor = AppTheme.textSecondary;
    IconData? medalIcon;

    if (rank == 1) {
      badgeColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFB45309);
      medalIcon = Icons.emoji_events;
    } else if (rank == 2) {
      badgeColor = const Color(0xFFF1F5F9);
      textColor = const Color(0xFF475569);
      medalIcon = Icons.emoji_events;
    } else if (rank == 3) {
      badgeColor = const Color(0xFFFFEDD5);
      textColor = const Color(0xFFC2410C);
      medalIcon = Icons.emoji_events;
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: medalIcon != null
            ? Icon(medalIcon, color: textColor, size: 14)
            : Text(
                '$rank',
                style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w800, color: textColor),
              ),
      ),
    );
  }
}
