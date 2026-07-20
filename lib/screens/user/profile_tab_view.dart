import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/logout_dialog.dart';
import '../../core/widgets/custom_notification.dart';
import '../../core/routes/app_routes.dart';
import '../../services/storage_service.dart';
import 'widgets/profile_dialogs.dart';

class ProfileTabView extends StatefulWidget {
  const ProfileTabView({super.key});

  @override
  State<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends State<ProfileTabView> {
  // Localized UI state variables
  final Set<String> _favTeamIds = {'uvpce_titans'};
  bool _notifMatchStart = true;
  bool _notifWickets = true;
  bool _notifCommentary = false;
  String _themeMode = 'Light';
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // 1. Bio Header Banner
          _buildBioHeader(storage),
          const SizedBox(height: 20),

          // 2. Stats Dashboard Row
          _buildStatsRow(),
          const SizedBox(height: 24),

          // 3. Settings Category: Account Settings
          _buildCategoryHeader('ACCOUNT & PREFERENCES'),
          const SizedBox(height: 8),
          _buildProfileTile(
            icon: Icons.favorite_border,
            title: 'Favorite Teams',
            subtitle: '${_favTeamIds.length} selected',
            onTap: () => ProfileDialogs.showFavoriteTeams(context, storage, _favTeamIds, () => setState(() {})),
          ),
          _buildProfileTile(
            icon: Icons.notifications_none,
            title: 'Notification Settings',
            subtitle: _getNotificationSummary(),
            onTap: () => ProfileDialogs.showNotifications(
              context,
              _notifMatchStart,
              _notifWickets,
              _notifCommentary,
              (m, w, c) => setState(() {
                _notifMatchStart = m;
                _notifWickets = w;
                _notifCommentary = c;
              }),
            ),
          ),
          _buildProfileTile(
            icon: Icons.palette_outlined,
            title: 'Theme Settings',
            subtitle: _themeMode,
            onTap: () => ProfileDialogs.showThemeChooser(context, _themeMode, (theme) => setState(() => _themeMode = theme)),
          ),
          _buildProfileTile(
            icon: Icons.language,
            title: 'App Language',
            subtitle: _selectedLanguage,
            onTap: () => ProfileDialogs.showLanguageChooser(context, _selectedLanguage, (lang) => setState(() => _selectedLanguage = lang)),
          ),

          const SizedBox(height: 20),

          // 4. Settings Category: Support & Legal
          _buildCategoryHeader('SUPPORT & LEGAL'),
          const SizedBox(height: 8),
          _buildProfileTile(
            icon: Icons.help_outline,
            title: 'Help & Feedback',
            subtitle: 'Get assistance or submit ideas',
            onTap: () => CustomNotification.show(context, 'Support desk is online!', type: NotificationType.success),
          ),
          _buildProfileTile(
            icon: Icons.info_outline,
            title: 'About CricketVerse',
            subtitle: 'Version 1.0.0 (Stable)',
            onTap: () => ProfileDialogs.showAboutApp(context),
          ),

          const SizedBox(height: 32),

          // 5. Sign Out Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final confirm = await LogoutDialog.show(context);
                if (confirm == true && mounted) {
                  storage.logout();
                  navigator.pushReplacementNamed(AppRoutes.auth);
                }
              },
              icon: const Icon(Icons.logout, color: AppTheme.accentRed),
              label: Text('Sign Out', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEE2E2),
                foregroundColor: AppTheme.accentRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBioHeader(StorageService storage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.bgSurface),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 46,
            backgroundImage: NetworkImage('https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=150&auto=format&fit=crop'),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Alex',
                style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, size: 10, color: Colors.white),
                    const SizedBox(width: 2),
                    Text(
                      'PRO',
                      style: GoogleFonts.plusJakartaSans(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            storage.currentUserEmail ?? 'user@gmail.com',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatItem('32', 'Predictions', Icons.online_prediction, AppTheme.primaryBlue)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem('78%', 'Accuracy', Icons.insights, AppTheme.primaryGreen)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem('Gold', 'Tier Rank', Icons.emoji_events, AppTheme.accentGold)),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.bgSurface),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMuted,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.bgSurface),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.bgSurface.withValues(alpha: 0.5),
                  child: Icon(icon, color: AppTheme.primaryBlue, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getNotificationSummary() {
    int count = 0;
    if (_notifMatchStart) count++;
    if (_notifWickets) count++;
    if (_notifCommentary) count++;
    return '$count of 3 active';
  }
}
