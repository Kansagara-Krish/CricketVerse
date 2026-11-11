import 'dart:async';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/logout_dialog.dart';
import '../../core/widgets/custom_notification.dart';
import '../../core/routes/app_routes.dart';
import '../../services/storage_service.dart';

class ProfileTabView extends StatefulWidget {
  const ProfileTabView({super.key});

  @override
  State<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends State<ProfileTabView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final storage = Provider.of<StorageService>(context, listen: false);
      storage.refreshCurrentProfile();
    });
  }

  ({Country country, String digits}) _parseStoredPhone(String? rawPhone) {
    final defaultCountry = CountryParser.parseCountryCode('IN');
    if (rawPhone == null || rawPhone.trim().isEmpty) {
      return (country: defaultCountry, digits: '');
    }
    final cleaned = rawPhone.replaceAll(RegExp(r'[\s\-()]'), '').trim();
    if (!cleaned.startsWith('+')) {
      return (country: defaultCountry, digits: cleaned);
    }
    final digitsOnly = cleaned.substring(1);
    final countries = CountryService().getAll()
      ..sort((a, b) => b.phoneCode.length.compareTo(a.phoneCode.length));
    for (final c in countries) {
      if (digitsOnly.startsWith(c.phoneCode)) {
        return (country: c, digits: digitsOnly.substring(c.phoneCode.length));
      }
    }
    return (country: defaultCountry, digits: digitsOnly);
  }

  String _formatPhoneForDisplay(String? rawPhone) {
    final trimmed = rawPhone?.trim() ?? '';
    if (trimmed.isEmpty) return '';
    final parsed = _parseStoredPhone(trimmed);
    if (parsed.digits.isEmpty) return trimmed;
    return '+${parsed.country.phoneCode} ${parsed.digits}';
  }

  void _editProfile(StorageService storage) {
    final nameCtrl = TextEditingController(text: storage.currentUserName ?? '');
    final emailCtrl = TextEditingController(text: storage.currentUserEmail ?? '');
    final parsedInitial = _parseStoredPhone(storage.currentUserPhone);
    Country selectedCountry = parsedInitial.country;
    final phoneCtrl = TextEditingController(text: parsedInitial.digits);
    final otpCtrl = TextEditingController();

    String originalPhoneE164 = parsedInitial.digits.isNotEmpty
        ? '+${parsedInitial.country.phoneCode}${parsedInitial.digits}'
        : '';

    bool didStartFetch = false;
    bool isFetchingProfile = true;
    bool isSaving = false;
    bool userEditedName = false;
    bool userEditedEmail = false;
    bool userEditedPhone = false;

    bool requiresOtpStep = false;
    String? phoneChangeToken;
    String? pendingPhone;
    String? inlineError;
    int cooldownSeconds = 0;
    Timer? cooldownTimer;

    void startCooldown(StateSetter setModalState, BuildContext modalCtx) {
      cooldownTimer?.cancel();
      cooldownSeconds = 60;
      cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!modalCtx.mounted) {
          timer.cancel();
          return;
        }
        if (cooldownSeconds <= 1) {
          timer.cancel();
          setModalState(() => cooldownSeconds = 0);
        } else {
          setModalState(() => cooldownSeconds--);
        }
      });
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          if (!didStartFetch) {
            didStartFetch = true;
            storage.refreshCurrentProfile().then((fresh) {
              if (!modalCtx.mounted) return;
              setModalState(() {
                isFetchingProfile = false;
                if (fresh['success'] == true) {
                  final freshName = fresh['name']?.toString() ?? '';
                  final freshEmail = fresh['email']?.toString() ?? '';
                  final freshPhone = fresh['phone']?.toString() ?? '';
                  final freshParsed = _parseStoredPhone(freshPhone);

                  originalPhoneE164 = freshParsed.digits.isNotEmpty
                      ? '+${freshParsed.country.phoneCode}${freshParsed.digits}'
                      : '';

                  if (!userEditedName && freshName.isNotEmpty) {
                    nameCtrl.text = freshName;
                  }
                  if (!userEditedEmail && freshEmail.isNotEmpty) {
                    emailCtrl.text = freshEmail;
                  }
                  if (!userEditedPhone) {
                    selectedCountry = freshParsed.country;
                    phoneCtrl.text = freshParsed.digits;
                  }
                }
              });
            });
          }

          Future<void> handleSaveTap() async {
            if (isSaving || isFetchingProfile) return;

            final name = nameCtrl.text.trim();
            final email = emailCtrl.text.trim();
            final phoneDigits = phoneCtrl.text.trim();
            final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

            if (name.isEmpty || email.isEmpty) {
              setModalState(() => inlineError = 'Name and email cannot be empty.');
              return;
            }
            if (!emailRegex.hasMatch(email)) {
              setModalState(() => inlineError = 'Please enter a valid email address.');
              return;
            }
            if (originalPhoneE164.isNotEmpty && phoneDigits.isEmpty) {
              setModalState(() => inlineError = 'Please enter a valid 10-digit mobile number.');
              return;
            }
            if (phoneDigits.isNotEmpty && phoneDigits.length != 10) {
              setModalState(() => inlineError = 'Phone number must be exactly 10 digits.');
              return;
            }

            final fullPhone = phoneDigits.isNotEmpty
                ? '+${selectedCountry.phoneCode}$phoneDigits'
                : '';

            setModalState(() {
              isSaving = true;
              inlineError = null;
            });

            final res = await storage.saveProfileChanges(
              name: name,
              email: email,
              phone: fullPhone,
            );

            if (!modalCtx.mounted) return;

            if (res['requiresPhoneVerification'] == true) {
              otpCtrl.clear();
              startCooldown(setModalState, modalCtx);
              setModalState(() {
                isSaving = false;
                requiresOtpStep = true;
                phoneChangeToken = res['phoneChangeToken']?.toString();
                pendingPhone = res['pendingPhone']?.toString() ?? fullPhone;
                inlineError = null;
              });
              return;
            }

            if (res['success'] == true) {
              setModalState(() => isSaving = false);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                CustomNotification.show(
                  context,
                  'Profile updated successfully!',
                  type: NotificationType.success,
                );
                setState(() {});
              }
            } else {
              setModalState(() {
                isSaving = false;
                inlineError = res['error']?.toString() ??
                    'Update failed. Email or phone may already be taken.';
              });
            }
          }

          Future<void> handleVerifyOtpTap() async {
            if (isSaving) return;
            final otp = otpCtrl.text.trim();
            if (otp.length != 6) {
              setModalState(() => inlineError = 'Please enter the 6-digit verification code.');
              return;
            }

            setModalState(() {
              isSaving = true;
              inlineError = null;
            });

            final res = await storage.saveProfileChanges(
              name: nameCtrl.text.trim(),
              email: emailCtrl.text.trim(),
              phone: pendingPhone,
              phoneOtp: otp,
              phoneChangeToken: phoneChangeToken,
            );

            if (!modalCtx.mounted) return;

            if (res['success'] == true && res['requiresPhoneVerification'] != true) {
              cooldownTimer?.cancel();
              setModalState(() => isSaving = false);
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) {
                CustomNotification.show(
                  context,
                  'Profile and verified mobile number updated!',
                  type: NotificationType.success,
                );
                setState(() {});
              }
            } else {
              setModalState(() {
                isSaving = false;
                inlineError = res['error']?.toString() ?? 'Invalid or expired verification code.';
              });
            }
          }

          Future<void> handleResendOtpTap() async {
            if (isSaving || cooldownSeconds > 0 || pendingPhone == null) return;
            setModalState(() {
              isSaving = true;
              inlineError = null;
            });

            final res = await storage.saveProfileChanges(
              name: nameCtrl.text.trim(),
              email: emailCtrl.text.trim(),
              phone: pendingPhone,
            );

            if (!modalCtx.mounted) return;

            if (res['requiresPhoneVerification'] == true) {
              otpCtrl.clear();
              startCooldown(setModalState, modalCtx);
              setModalState(() {
                isSaving = false;
                phoneChangeToken = res['phoneChangeToken']?.toString();
              });
              if (mounted) {
                CustomNotification.show(
                  context,
                  'New verification code sent via SMS.',
                  type: NotificationType.success,
                );
              }
            } else {
              setModalState(() {
                isSaving = false;
                inlineError = res['error']?.toString() ?? 'Failed to resend verification code.';
              });
            }
          }

          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      requiresOtpStep ? 'Verify Mobile Number' : 'Edit Profile',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    if (isFetchingProfile && !requiresOtpStep)
                      Row(
                        children: [
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Loading...',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                if (!requiresOtpStep) ...[
                  TextField(
                    controller: nameCtrl,
                    onChanged: (_) => userEditedName = true,
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: Icon(Icons.person_outline, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: emailCtrl,
                    onChanged: (_) => userEditedEmail = true,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: Icon(Icons.email_outlined, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          showCountryPicker(
                            context: modalCtx,
                            showPhoneCode: true,
                            onSelect: (Country c) {
                              userEditedPhone = true;
                              setModalState(() => selectedCountry = c);
                            },
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppTheme.bgSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(selectedCountry.flagEmoji, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 4),
                              Text(
                                '+${selectedCountry.phoneCode}',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppTheme.textMuted),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: phoneCtrl,
                          onChanged: (_) => userEditedPhone = true,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Phone Number',
                            hintText: '10-digit number',
                            prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.sms_outlined, color: AppTheme.primaryGreen, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Enter the 6-digit SMS code sent to ${_formatPhoneForDisplay(pendingPhone)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpCtrl,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    autofocus: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 6,
                    ),
                    decoration: const InputDecoration(
                      labelText: '6-Digit Verification Code',
                      hintText: '000000',
                      counterText: '',
                      prefixIcon: Icon(Icons.verified_user_outlined, color: AppTheme.textMuted),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: isSaving
                            ? null
                            : () {
                                setModalState(() {
                                  requiresOtpStep = false;
                                  inlineError = null;
                                });
                              },
                        icon: const Icon(Icons.arrow_back_rounded, size: 16),
                        label: const Text('Change Number'),
                      ),
                      TextButton(
                        onPressed: (isSaving || cooldownSeconds > 0)
                            ? null
                            : handleResendOtpTap,
                        child: Text(
                          cooldownSeconds > 0
                              ? 'Resend in ${cooldownSeconds}s'
                              : 'Resend Code',
                        ),
                      ),
                    ],
                  ),
                ],
                if (inlineError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCA5A5)),
                    ),
                    child: Text(
                      inlineError!,
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFFB91C1C),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (isSaving || isFetchingProfile)
                        ? null
                        : (requiresOtpStep ? handleVerifyOtpTap : handleSaveTap),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(requiresOtpStep ? 'Verify & Save' : 'Save Changes'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).whenComplete(() {
      cooldownTimer?.cancel();
      nameCtrl.dispose();
      emailCtrl.dispose();
      phoneCtrl.dispose();
      otpCtrl.dispose();
    });
  }

  void _changePassword(StorageService storage) async {
    // Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    final otpCode = await storage.requestPasswordOtp();
    if (!mounted) return;
    Navigator.pop(context); // Dismiss loading indicator
    
    if (otpCode == null) {
      CustomNotification.show(context, 'Failed to request OTP code.', type: NotificationType.error);
      return;
    }

    // Show dialog/modal informing the OTP code (prototype validation)
    CustomNotification.show(
      context,
      'Verification Code: $otpCode (staged for prototype)',
      type: NotificationType.success,
      duration: const Duration(seconds: 6),
    );

    final otpCtrl = TextEditingController(text: otpCode); // Autofill for convenience in prototype!
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
            TextField(
              controller: otpCtrl, 
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '4-Digit OTP Code', 
                prefixIcon: Icon(Icons.pin_outlined, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: newPassCtrl, 
              obscureText: true, 
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'New Password', 
                prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: confirmCtrl, 
              obscureText: true, 
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Confirm New Password', 
                prefixIcon: Icon(Icons.lock_outline, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final otp = otpCtrl.text.trim();
                  final newPass = newPassCtrl.text.trim();
                  final confirm = confirmCtrl.text.trim();

                  if (otp.isEmpty || newPass.isEmpty || confirm.isEmpty) {
                    CustomNotification.show(context, 'All fields are required', type: NotificationType.error);
                    return;
                  }
                  if (newPass != confirm) {
                    CustomNotification.show(context, 'Passwords do not match', type: NotificationType.error);
                    return;
                  }

                  final ok = await storage.updatePassword(otp, newPass);
                  if (ok) {
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      CustomNotification.show(context, 'Password updated successfully!', type: NotificationType.success);
                    }
                  } else {
                    if (mounted) {
                      CustomNotification.show(context, 'Failed to update password. Invalid or expired OTP.', type: NotificationType.error);
                    }
                  }
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
          _buildCategoryHeader('ACCOUNT SETTINGS'),
          const SizedBox(height: 8),
          _buildProfileTile(
            icon: Icons.edit_rounded,
            title: 'Edit Profile',
            subtitle: 'Change name, email or phone',
            onTap: () => _editProfile(storage),
          ),
          _buildProfileTile(
            icon: Icons.lock_outline_rounded,
            title: 'Change Password',
            subtitle: 'Secure your account',
            onTap: () => _changePassword(storage),
          ),

          const SizedBox(height: 32),

          // 4. Sign Out Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                final navigator = Navigator.of(context);
                final confirm = await LogoutDialog.show(context);
                if (confirm == true && mounted) {
                  await storage.logout();
                  if (context.mounted) {
                    CustomNotification.show(context, 'Successfully logged out!', type: NotificationType.success);
                    navigator.pushReplacementNamed(AppRoutes.auth);
                  }
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
    final displayName = storage.currentUserName ?? 'Fan';
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
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryGreen.withOpacity(0.12),
              border: Border.all(
                color: AppTheme.primaryGreen.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.person_rounded,
                size: 48,
                color: AppTheme.primaryGreen,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            storage.currentUserEmail ?? 'Guest User',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
          ),
          if (storage.currentUserPhone != null && storage.currentUserPhone!.trim().isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              _formatPhoneForDisplay(storage.currentUserPhone),
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.primaryGreen, fontWeight: FontWeight.w700),
            ),
          ],
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
            backgroundColor: color.withOpacity(0.1),
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
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE6F4EA),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, color: const Color(0xFF047857), size: 19),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
