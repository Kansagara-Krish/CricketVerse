// lib/screens/admin/widgets/manager_management_dialog.dart
// Dedicated Manager & Scorer credentials management sheet for Admin

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_notification.dart';
import '../../../models/models.dart';
import '../../../services/storage_service.dart';

class ManagerManagementDialog extends StatefulWidget {
  final Function(Manager)? onManagerSelected;
  const ManagerManagementDialog({super.key, this.onManagerSelected});

  static Future<Manager?> show(BuildContext context, {Function(Manager)? onSelected}) {
    return showModalBottomSheet<Manager>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ManagerManagementDialog(onManagerSelected: onSelected),
    );
  }

  @override
  State<ManagerManagementDialog> createState() => _ManagerManagementDialogState();
}

class _ManagerManagementDialogState extends State<ManagerManagementDialog> {
  bool _isCreating = false;
  bool _isDeleting = false;
  final _createFormKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StorageService>(context, listen: false).loadManagers();
    });
  }

  void _submitCreateManager(StorageService storage) async {
    if (!_createFormKey.currentState!.validate()) return;
    final created = await storage.addManager(
      name: _nameCtrl.text.trim(),
      username: _userCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isNotEmpty ? _phoneCtrl.text.trim() : null,
    );
    if (!mounted) return;
    if (created != null) {
      _nameCtrl.clear();
      _userCtrl.clear();
      _passCtrl.clear();
      _phoneCtrl.clear();
      setState(() => _isCreating = false);
      CustomNotification.show(
        context,
        'Manager "${created.name}" created successfully!',
        type: NotificationType.success,
      );
      if (widget.onManagerSelected != null) {
        widget.onManagerSelected!(created);
        Navigator.pop(context, created);
      }
    } else {
      CustomNotification.show(
        context,
        'Failed to create manager. Username might already exist.',
        type: NotificationType.error,
      );
    }
  }

  void _showDeleteConfirmDialog(Manager manager) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.delete_forever_rounded, color: AppTheme.accentRed, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Remove Manager?',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently revoke credentials for "${manager.name}" (${manager.username})? They will no longer be able to log in or score matches.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isDeleting = true);
              final storage = Provider.of<StorageService>(context, listen: false);
              final ok = await storage.deleteManager(manager.id);
              if (!mounted) return;
              setState(() => _isDeleting = false);
              if (ok) {
                CustomNotification.show(
                  context,
                  'Manager "${manager.name}" credentials removed.',
                  type: NotificationType.success,
                );
              } else {
                CustomNotification.show(
                  context,
                  'Failed to delete manager. Please check network connection.',
                  type: NotificationType.error,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              'Delete Credential',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storage = Provider.of<StorageService>(context);
    final managers = storage.managers;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(bottom: keyboardHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.manage_accounts_rounded, color: AppTheme.primaryBlue, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manager Credentials',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Manage official match scorers & managers',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),

          // Toggle between List and Create
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _isCreating
                  ? _buildCreateForm(storage)
                  : _buildManagersList(context, managers),
            ),
          ),

          // Bottom Action Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: _isCreating
                  ? Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setState(() => _isCreating = false),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: () => _submitCreateManager(storage),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                            label: Text(
                              'Save Manager',
                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    )
                  : ElevatedButton.icon(
                      onPressed: () => setState(() => _isCreating = true),
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                      label: Text(
                        '+ Add New Manager Credential',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManagersList(BuildContext context, List<Manager> managers) {
    if (managers.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline_rounded, size: 36, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 14),
            Text(
              'No Managers Added Yet',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap "+ Add New Manager Credential" below to create login credentials for your official scorers.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACTIVE MANAGERS (${managers.length})',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.textMuted,
                letterSpacing: 1.1,
              ),
            ),
            if (_isDeleting)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentRed),
              ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: managers.length,
          separatorBuilder: (ctx, i) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) {
            final manager = managers[i];
            final initial = manager.name.trim().isNotEmpty ? manager.name.trim()[0].toUpperCase() : 'M';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFE0F2FE),
                    child: Text(
                      initial,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryBlue,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          manager.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.alternate_email_rounded, size: 12, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                manager.username,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: AppTheme.primaryBlue,
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
                  if (widget.onManagerSelected != null) ...[
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline_rounded, color: AppTheme.primaryGreen),
                      tooltip: 'Select for this match',
                      onPressed: () {
                        widget.onManagerSelected!(manager);
                        Navigator.pop(context, manager);
                      },
                    ),
                  ],
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.accentRed, size: 20),
                    tooltip: 'Revoke / Delete Credential',
                    onPressed: () => _showDeleteConfirmDialog(manager),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCreateForm(StorageService storage) {
    return Form(
      key: _createFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEW MANAGER DETAILS',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.textMuted,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _nameCtrl,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: 'e.g. Rahul Sharma',
              prefixIcon: const Icon(Icons.badge_outlined, color: AppTheme.textMuted, size: 19),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter manager name' : null,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _userCtrl,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              labelText: 'Username or Email',
              hintText: 'e.g. rahul_scorer or rahul@gmail.com',
              prefixIcon: const Icon(Icons.alternate_email_rounded, color: AppTheme.textMuted, size: 19),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter username' : null,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _passCtrl,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              labelText: 'Login Password',
              hintText: 'Create a password for manager',
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textMuted, size: 19),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? 'Please enter password' : null,
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary, fontSize: 13.5),
            decoration: InputDecoration(
              labelText: 'Phone Number (Optional)',
              hintText: 'e.g. +91 9876543210',
              prefixIcon: const Icon(Icons.phone_outlined, color: AppTheme.textMuted, size: 19),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}