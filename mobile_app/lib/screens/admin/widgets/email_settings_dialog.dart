import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_notification.dart';
import '../../../services/storage_service.dart';

class EmailSettingsDialog extends StatefulWidget {
  const EmailSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const EmailSettingsDialog(),
    );
  }

  @override
  State<EmailSettingsDialog> createState() => _EmailSettingsDialogState();
}

class _EmailSettingsDialogState extends State<EmailSettingsDialog> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isTesting = false;
  bool _hasExistingAppPassword = false;
  bool _obscureFreshPassword = true;

  final _formKey = GlobalKey<FormState>();
  final _senderEmailCtrl = TextEditingController();
  final _senderNameCtrl = TextEditingController(text: 'CricketVerse');
  final _appPasswordCtrl = TextEditingController();
  final _hostCtrl = TextEditingController(text: 'smtp.gmail.com');
  final _portCtrl = TextEditingController(text: '465');

  String? _statusNote;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _senderEmailCtrl.dispose();
    _senderNameCtrl.dispose();
    _appPasswordCtrl.dispose();
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final config = await storage.getEmailConfig();

      if (!mounted) return;

      if (config != null) {
        setState(() {
          _senderEmailCtrl.text = config['senderEmail'] ?? '';
          _senderNameCtrl.text = config['senderName'] ?? 'CricketVerse';
          _hostCtrl.text = config['host'] ?? 'smtp.gmail.com';
          _portCtrl.text = (config['port'] ?? 465).toString();
          _hasExistingAppPassword = config['hasAppPassword'] == true;
          _isLoading = false;
          _statusNote = config['isConfigured'] == true
              ? '✅ Email sender active & configured'
              : '⚠️ Email sender not yet configured';
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveConfig() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    if (!_hasExistingAppPassword && _appPasswordCtrl.text.trim().isEmpty) {
      AppNotification.error(
        context,
        title: 'App Password Required',
        message: 'Please enter a 16-character Google App Password to configure email.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final res = await storage.updateEmailConfig(
        senderEmail: _senderEmailCtrl.text.trim(),
        appPassword: _appPasswordCtrl.text.trim().isNotEmpty ? _appPasswordCtrl.text.trim() : null,
        senderName: _senderNameCtrl.text.trim(),
        host: _hostCtrl.text.trim(),
        port: int.tryParse(_portCtrl.text.trim()) ?? 465,
        secure: (_portCtrl.text.trim() == '465'),
      );

      if (!mounted) return;

      if (res['success'] == true) {
        setState(() {
          _hasExistingAppPassword = true;
          _appPasswordCtrl.clear();
          _statusNote = '✅ Email sender active & configured';
        });

        AppNotification.success(
          context,
          title: 'Config Saved',
          message: 'Email sender and App Password verified & saved successfully.',
        );
      } else {
        AppNotification.error(
          context,
          title: 'Verification Failed',
          message: res['error'] ?? 'Could not verify App Password with SMTP server.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _sendTestEmail() async {
    if (_isTesting) return;

    final storage = Provider.of<StorageService>(context, listen: false);
    final target = storage.currentUserEmail ?? _senderEmailCtrl.text.trim();

    if (target.isEmpty) {
      AppNotification.error(
        context,
        title: 'Error',
        message: 'No recipient email available for test.',
      );
      return;
    }

    setState(() {
      _isTesting = true;
    });

    try {
      final res = await storage.testEmailConfig(target);
      if (!mounted) return;

      if (res['success'] == true) {
        AppNotification.success(
          context,
          title: 'Test Email Sent',
          message: 'Test email successfully sent to $target.',
        );
      } else {
        AppNotification.error(
          context,
          title: 'Test Failed',
          message: res['error'] ?? 'Failed to send test email.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111928),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.2),
      ),
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 20,
        bottom: bottomInset > 0 ? bottomInset + 20 : 32,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 250,
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryBlue),
              ),
            )
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                          ),
                          child: const Icon(
                            Icons.outgoing_mail,
                            color: AppTheme.primaryGreen,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Email & App Password Settings',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Admin SMTP configuration for sending OTPs',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white60, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_statusNote != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: _hasExistingAppPassword
                              ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                              : AppTheme.accentOrange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _hasExistingAppPassword
                                ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                                : AppTheme.accentOrange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _statusNote!,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                    // Sender Email
                    Text(
                      'Sender Email Address',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _senderEmailCtrl,
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'e.g. cricketverse.app@gmail.com',
                        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 13),
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        prefixIcon: const Icon(Icons.email_outlined, size: 16, color: Colors.white60),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Sender email is required.';
                        if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email.';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // App Password Section
                    Text(
                      'App Password (Security Protected)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 6),

                    if (_hasExistingAppPassword) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.shield, color: AppTheme.primaryGreen, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '•••• •••• •••• •••• (Configured & Hidden)',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                  letterSpacing: 1.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'ℹ️ App password is never displayed for security. To replace it, enter a completely fresh 16-character App Password below:',
                        style: GoogleFonts.plusJakartaSans(color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(height: 6),
                    ],

                    TextFormField(
                      controller: _appPasswordCtrl,
                      obscureText: _obscureFreshPassword,
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: _hasExistingAppPassword
                            ? 'Enter fresh App Password to update'
                            : 'Enter 16-character App Password (e.g. abcd efgh ijkl mnop)',
                        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white38, fontSize: 12),
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        prefixIcon: const Icon(Icons.key_outlined, size: 16, color: Colors.white60),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureFreshPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                            color: Colors.white60,
                          ),
                          onPressed: () => setState(() => _obscureFreshPassword = !_obscureFreshPassword),
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Sender Name & Host Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sender Name',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _senderNameCtrl,
                                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  fillColor: Colors.white.withValues(alpha: 0.06),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Port',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _portCtrl,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
                                decoration: InputDecoration(
                                  fillColor: Colors.white.withValues(alpha: 0.06),
                                  filled: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Action Buttons
                    Row(
                      children: [
                        if (_hasExistingAppPassword)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isTesting ? null : _sendTestEmail,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                              ),
                              child: _isTesting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(
                                      'Test Email',
                                      style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                                    ),
                            ),
                          ),
                        if (_hasExistingAppPassword) const SizedBox(width: 12),
                        Expanded(
                          flex: _hasExistingAppPassword ? 1 : 2,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveConfig,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : Text(
                                    'Save & Verify',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
