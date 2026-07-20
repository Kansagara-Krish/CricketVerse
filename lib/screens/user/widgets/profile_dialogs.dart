import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/team_logo.dart';
import '../../../services/storage_service.dart';
import '../../../core/widgets/custom_notification.dart';

class ProfileDialogs {
  static void showFavoriteTeams(
    BuildContext context,
    StorageService storage,
    Set<String> favTeamIds,
    VoidCallback onUpdate,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'FavoriteTeamsDialog',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final double scale = Tween<double>(begin: 0.9, end: 1.0)
            .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack))
            .value;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: Transform.scale(
              scale: scale,
              child: Align(
                alignment: Alignment.center,
                child: StatefulBuilder(
                  builder: (ctx, setDialogState) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: Row(
                        children: [
                          const Icon(Icons.favorite, color: AppTheme.accentRed, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Favorite Teams',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: storage.teams.length,
                          itemBuilder: (context, i) {
                            final team = storage.teams[i];
                            final isFav = favTeamIds.contains(team.id);
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: TeamLogo.fromTeam(team, size: 36),
                              title: Text(team.name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13)),
                              trailing: IconButton(
                                icon: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  color: isFav ? AppTheme.accentRed : AppTheme.textMuted,
                                ),
                                onPressed: () {
                                  setDialogState(() {
                                    if (isFav) {
                                      favTeamIds.remove(team.id);
                                    } else {
                                      favTeamIds.add(team.id);
                                    }
                                  });
                                  onUpdate();
                                },
                              ),
                            );
                          },
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Close', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static void showNotifications(
    BuildContext context,
    bool matchStart,
    bool wickets,
    bool commentary,
    Function(bool, bool, bool) onChanged,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'NotificationsDialog',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final double scale = Tween<double>(begin: 0.9, end: 1.0)
            .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack))
            .value;

        bool localMatchStart = matchStart;
        bool localWickets = wickets;
        bool localCommentary = commentary;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: Transform.scale(
              scale: scale,
              child: Align(
                alignment: Alignment.center,
                child: StatefulBuilder(
                  builder: (ctx, setDialogState) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: Row(
                        children: [
                          const Icon(Icons.notifications_active, color: AppTheme.primaryBlue, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Notifications Settings',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SwitchListTile(
                            title: Text('Match Alerts', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text('Get notified when matches start', style: GoogleFonts.plusJakartaSans(fontSize: 11)),
                            value: localMatchStart,
                            activeColor: AppTheme.primaryBlue,
                            onChanged: (val) {
                              setDialogState(() => localMatchStart = val);
                              onChanged(localMatchStart, localWickets, localCommentary);
                            },
                          ),
                          SwitchListTile(
                            title: Text('Wicket Alerts', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text('Instantly receive live wicket updates', style: GoogleFonts.plusJakartaSans(fontSize: 11)),
                            value: localWickets,
                            activeColor: AppTheme.primaryBlue,
                            onChanged: (val) {
                              setDialogState(() => localWickets = val);
                              onChanged(localMatchStart, localWickets, localCommentary);
                            },
                          ),
                          SwitchListTile(
                            title: Text('Audio Commentary', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                            subtitle: Text('Auto-read live commentary feeds', style: GoogleFonts.plusJakartaSans(fontSize: 11)),
                            value: localCommentary,
                            activeColor: AppTheme.primaryBlue,
                            onChanged: (val) {
                              setDialogState(() => localCommentary = val);
                              onChanged(localMatchStart, localWickets, localCommentary);
                            },
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Close', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static void showThemeChooser(
    BuildContext context,
    String themeMode,
    ValueChanged<String> onChanged,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ThemeChooserDialog',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final double scale = Tween<double>(begin: 0.9, end: 1.0)
            .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack))
            .value;

        String localTheme = themeMode;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: Transform.scale(
              scale: scale,
              child: Align(
                alignment: Alignment.center,
                child: StatefulBuilder(
                  builder: (ctx, setDialogState) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: Row(
                        children: [
                          const Icon(Icons.palette, color: AppTheme.accentPurple, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'Choose Theme',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: ['Light', 'Dark', 'System Default'].map((theme) {
                          return RadioListTile<String>(
                            title: Text(theme, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                            value: theme,
                            groupValue: localTheme,
                            activeColor: AppTheme.accentPurple,
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => localTheme = val);
                                onChanged(localTheme);
                                CustomNotification.show(
                                  context,
                                  'Applied $theme successfully!',
                                  type: NotificationType.success,
                                );
                                Navigator.pop(ctx);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static void showLanguageChooser(
    BuildContext context,
    String language,
    ValueChanged<String> onChanged,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'LanguageChooserDialog',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final double scale = Tween<double>(begin: 0.9, end: 1.0)
            .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutBack))
            .value;

        String localLang = language;

        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5 * anim1.value, sigmaY: 5 * anim1.value),
          child: Opacity(
            opacity: anim1.value,
            child: Transform.scale(
              scale: scale,
              child: Align(
                alignment: Alignment.center,
                child: StatefulBuilder(
                  builder: (ctx, setDialogState) {
                    return AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      title: Row(
                        children: [
                          const Icon(Icons.language, color: AppTheme.primaryBlue, size: 22),
                          const SizedBox(width: 10),
                          Text(
                            'App Language',
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: ['English', 'Hindi (हिंदी)', 'Spanish (Español)'].map((lang) {
                          return RadioListTile<String>(
                            title: Text(lang, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                            value: lang.split(' ').first,
                            groupValue: localLang,
                            activeColor: AppTheme.primaryBlue,
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() => localLang = val);
                                onChanged(localLang);
                                CustomNotification.show(
                                  context,
                                  'Language changed to $lang',
                                  type: NotificationType.success,
                                );
                                Navigator.pop(ctx);
                              }
                            },
                          );
                        }).toList(),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static void showAboutApp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 22),
            const SizedBox(width: 10),
            Text(
              'About CricketVerse',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'CricketVerse AI',
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.primaryBlue),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0 (Stable)',
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'An advanced AI-powered cricket manager & real-time analytics suite, featuring smart live scoring, win probability simulators, and deep stats telemetry.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textPrimary, height: 1.45),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Awesome', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
