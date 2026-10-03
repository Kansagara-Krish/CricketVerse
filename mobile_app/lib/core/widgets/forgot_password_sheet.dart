import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'app_notification.dart';

class ForgotPasswordSheet extends StatefulWidget {
  final String initialEmail;
  final Function(String email, String newPassword)? onSuccess;

  const ForgotPasswordSheet({
    super.key,
    this.initialEmail = '',
    this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    String initialEmail = '',
    Function(String email, String newPassword)? onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ForgotPasswordSheet(
        initialEmail: initialEmail,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  int _currentStep = 1; // 1: Enter Email, 2: Enter OTP & New Password
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  late TextEditingController _emailController;
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _step1FormKey = GlobalKey<FormState>();
  final _step2FormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _requestOtp() async {
    if (_isLoading) return;
    if (!_step1FormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final email = _emailController.text.trim().toLowerCase();
      final result = await storage.requestForgotPasswordOtp(email);

      if (!mounted) return;

      if (result['success'] == true) {
        AppNotification.success(
          context,
          title: 'OTP Sent',
          message: result['message'] ?? 'A 6-digit verification code has been sent to your email.',
        );

        if (result['devOtp'] != null) {
          _otpController.text = result['devOtp'].toString();
        }

        setState(() {
          _currentStep = 2;
        });
      } else {
        AppNotification.error(
          context,
          title: 'Request Failed',
          message: result['error'] ?? 'Could not send verification code.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_isLoading) return;
    if (!_step2FormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final email = _emailController.text.trim().toLowerCase();
      final otp = _otpController.text.trim();
      final newPass = _newPasswordController.text;
      final confirmPass = _confirmPasswordController.text;

      final result = await storage.resetForgotPassword(
        email: email,
        otp: otp,
        newPassword: newPass,
        confirmPassword: confirmPass,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.pop(context);
        if (widget.onSuccess != null) {
          widget.onSuccess!(email, newPass);
        }
        AppNotification.success(
          context,
          title: 'Password Reset Successful',
          message: 'Your password has been updated. You can now sign in.',
        );
      } else {
        AppNotification.error(
          context,
          title: 'Reset Failed',
          message: result['error'] ?? 'Failed to reset password. Please check your OTP.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildPasswordRequirementItem(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 13,
            color: met ? AppTheme.primaryGreen : Colors.white38,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              color: met ? Colors.white : Colors.white60,
              fontWeight: met ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordValidationBadges() {
    final val = _newPasswordController.text;
    final hasMinLength = val.length >= 8;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(val);
    final hasLower = RegExp(r'[a-z]').hasMatch(val);
    final hasNumber = RegExp(r'[0-9]').hasMatch(val);
    final hasSpecial = RegExp(r'[!@#$%^&*()_+\-=\[\]{};\x27:"\\|,.<>/?]').hasMatch(val);

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Password requirements:',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          _buildPasswordRequirementItem('At least 8 characters', hasMinLength),
          _buildPasswordRequirementItem('At least one uppercase letter (A-Z)', hasUpper),
          _buildPasswordRequirementItem('At least one lowercase letter (a-z)', hasLower),
          _buildPasswordRequirementItem('At least one number (0-9)', hasNumber),
          _buildPasswordRequirementItem('At least one special symbol (!@#\$%...)', hasSpecial),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF101927),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 30,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: bottomInset > 0 ? bottomInset + 20 : 36,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Header Row
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
                    Icons.lock_reset_rounded,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentStep == 1 ? 'Forgot Password' : 'Enter Verification Code',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _currentStep == 1
                            ? 'Enter your registered email to receive an OTP'
                            : 'Set a new password for your account',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
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
            const SizedBox(height: 20),

            if (_currentStep == 1) ...[
              // STEP 1: Enter Email
              Form(
                key: _step1FormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registered Email Address',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. user@gmail.com or admin@gmail.com',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 13,
                        ),
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        prefixIcon: const Icon(Icons.email_outlined, size: 18, color: Colors.white60),
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
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your registered email.';
                        }
                        final trimmed = value.trim();
                        if (trimmed.contains(' ') || !trimmed.contains('@') || !trimmed.contains('.')) {
                          return 'Please enter a valid email address.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _requestOtp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Send Verification Code',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // STEP 2: Enter OTP & New Password
              Form(
                key: _step2FormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email verification badge with change button
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.mark_email_read_outlined, size: 16, color: AppTheme.primaryGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _emailController.text.trim().toLowerCase(),
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _currentStep = 1;
                              });
                            },
                            child: Text(
                              'Change',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.primaryGreen,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // OTP Code Field
                    Text(
                      '6-Digit OTP Code',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 4.0,
                      ),
                      decoration: InputDecoration(
                        hintText: '123456',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.25),
                          fontSize: 16,
                          letterSpacing: 4.0,
                        ),
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        prefixIcon: const Icon(Icons.pin_outlined, size: 18, color: Colors.white60),
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
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the 6-digit OTP.';
                        }
                        if (value.trim().length < 4) {
                          return 'Please enter a valid OTP code.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // New Password Field
                    Text(
                      'New Password',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscureNewPassword,
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Enter new strong password',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 13,
                        ),
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        prefixIcon: const Icon(Icons.lock_outline, size: 18, color: Colors.white60),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                            color: Colors.white60,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureNewPassword = !_obscureNewPassword;
                            });
                          },
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'New password is required.';
                        }
                        if (value.contains(' ')) {
                          return 'Password cannot contain spaces.';
                        }
                        if (value.length < 8) {
                          return 'Password must be at least 8 characters long.';
                        }
                        if (!RegExp(r'[A-Z]').hasMatch(value)) {
                          return 'Must contain at least one uppercase letter.';
                        }
                        if (!RegExp(r'[a-z]').hasMatch(value)) {
                          return 'Must contain at least one lowercase letter.';
                        }
                        if (!RegExp(r'[0-9]').hasMatch(value)) {
                          return 'Must contain at least one number.';
                        }
                        if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{};\x27:"\\|,.<>/?]').hasMatch(value)) {
                          return 'Must contain at least one special symbol.';
                        }
                        return null;
                      },
                    ),

                    _buildPasswordValidationBadges(),

                    // Confirm New Password Field
                    Text(
                      'Confirm New Password',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Re-enter new password',
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 13,
                        ),
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        prefixIcon: const Icon(Icons.lock_outline, size: 18, color: Colors.white60),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 18,
                            color: Colors.white60,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword = !_obscureConfirmPassword;
                            });
                          },
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
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please confirm your new password.';
                        }
                        if (value != _newPasswordController.text) {
                          return 'Passwords do not match.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Reset Password Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                'Reset Password',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: TextButton(
                        onPressed: _isLoading ? null : _requestOtp,
                        child: Text(
                          'Resend OTP Code',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.primaryBlue,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
