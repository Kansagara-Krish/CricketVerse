import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';

class PlayerListItem extends StatelessWidget {
  final Player player;
  final String teamShort;
  final String teamColorHex;
  final VoidCallback onTap;

  const PlayerListItem({
    super.key,
    required this.player,
    required this.teamShort,
    required this.teamColorHex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final teamColor = Color(int.tryParse(teamColorHex) ?? 0xFF0284C7);
    final roleColor = AppTheme.roleColor(player.role);
    final initials = player.name.split(' ').map((n) => n[0]).join().toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.bgSurface),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: teamColor, width: 4),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Initials Circle Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: teamColor.withValues(alpha: 0.1),
                    child: Text(
                      initials.substring(0, initials.length > 2 ? 2 : initials.length),
                      style: GoogleFonts.plusJakartaSans(
                        color: teamColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Player Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                player.role,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 9.5,
                                  color: roleColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '$teamShort • ${player.nationality}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Score / Stats representation
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        player.role == 'Bowler' ? '${player.wicketsTaken}' : '${player.runsScored}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: player.role == 'Bowler' ? AppTheme.accentRed : AppTheme.primaryBlue,
                        ),
                      ),
                      Text(
                        player.role == 'Bowler' ? 'wickets' : 'runs',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
