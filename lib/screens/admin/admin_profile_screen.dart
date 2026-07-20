// lib/screens/admin/admin_profile_screen.dart
// Admin profile with edit, settings, and logout

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/logout_dialog.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  bool _darkMode = true;
  bool _notifications = true;
  bool _liveUpdates = true;

  void _editProfile() {
    final nameCtrl = TextEditingController(text: 'Rajesh Kumar');
    final emailCtrl = TextEditingController(text: 'admin@cricketverse.ai');
    final orgCtrl = TextEditingController(text: 'CricketVerse Organization');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
            left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),
            Text('Edit Profile', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 20),
            TextField(controller: nameCtrl, style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted))),
            const SizedBox(height: 14),
            TextField(controller: emailCtrl, style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted))),
            const SizedBox(height: 14),
            TextField(controller: orgCtrl, style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Organization', prefixIcon: Icon(Icons.business_outlined, color: AppTheme.textMuted))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Profile updated successfully!'), backgroundColor: AppTheme.primaryGreen),
                  );
                },
                child: const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changePassword() {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Change Password', style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 20),
            TextField(controller: oldPassCtrl, obscureText: true, style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Current Password', prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textMuted))),
            const SizedBox(height: 14),
            TextField(controller: newPassCtrl, obscureText: true, style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textMuted))),
            const SizedBox(height: 14),
            TextField(controller: confirmCtrl, obscureText: true, style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Confirm New Password', prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textMuted))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('🔒 Password changed successfully!'), backgroundColor: AppTheme.primaryGreen),
                  );
                },
                child: const Text('Update Password'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      appBar: AppBar(
        backgroundColor: AppTheme.bgDark,
        title: Text('My Profile', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
        actions: [
          TextButton(
            onPressed: _editProfile,
            child: Text('Edit', style: GoogleFonts.plusJakartaSans(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar section
            const SizedBox(height: 8),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                const AppLogo(size: 90, withGlow: true),
                GestureDetector(
                  onTap: _editProfile,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Rajesh Kumar',
                style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            Text('Tournament Administrator',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondary)),
            Text('admin@cricketverse.ai',
                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.primaryBlue)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Admin Access',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
            ),

            const SizedBox(height: 32),

            // Settings Section
            const _SectionHeader('ACCOUNT'),
            _SettingsTile(Icons.edit_rounded, 'Edit Profile', 'Update name, email, bio', onTap: _editProfile),
            _SettingsTile(Icons.lock_outline_rounded, 'Change Password', 'Update your login password', onTap: _changePassword),
            _SettingsTile(Icons.shield_outlined, 'Privacy & Security', 'Manage privacy settings', onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy settings')));
            }),

            const SizedBox(height: 20),
            const _SectionHeader('PREFERENCES'),
            _SwitchTile(Icons.dark_mode_outlined, 'Dark Mode', 'App theme preference', _darkMode,
                (v) => setState(() => _darkMode = v)),
            _SwitchTile(Icons.notifications_outlined, 'Push Notifications', 'Match alerts and updates', _notifications,
                (v) => setState(() => _notifications = v)),
            _SwitchTile(Icons.live_tv_outlined, 'Live Score Updates', 'Real-time score notifications', _liveUpdates,
                (v) => setState(() => _liveUpdates = v)),

            const SizedBox(height: 20),
            const _SectionHeader('MORE'),
            _SettingsTile(Icons.info_outline_rounded, 'About CricketVerse AI', 'App info and version',
                onTap: () => Navigator.pushNamed(context, AppRoutes.about)),
            _SettingsTile(Icons.help_outline_rounded, 'Help & FAQ', 'Get support',
                onTap: () => Navigator.pushNamed(context, AppRoutes.help)),
            _SettingsTile(Icons.auto_awesome_rounded, 'AI Settings', 'Configure AI features',
                onTap: () => Navigator.pushNamed(context, AppRoutes.aiSettings)),

            const SizedBox(height: 32),

            // Logout
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await LogoutDialog.show(context);
                  if (confirm == true && context.mounted) {
                    Provider.of<StorageService>(context, listen: false).logout();
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.auth, (r) => false);
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentRed.withValues(alpha: 0.15),
                  foregroundColor: AppTheme.accentRed,
                  side: BorderSide(color: AppTheme.accentRed.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title,
            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700,
                color: AppTheme.textMuted, letterSpacing: 1.4)),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final VoidCallback onTap;
  const _SettingsTile(this.icon, this.title, this.subtitle, {required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.glassCardSmall,
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryBlue, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile(this.icon, this.title, this.subtitle, this.value, this.onChanged);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: AppTheme.glassCardSmall,
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
                Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: AppTheme.primaryGreen),
        ],
      ),
    );
  }
}
