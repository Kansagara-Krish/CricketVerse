import 'dart:async';
import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'app_notification.dart';

class ForgotPasswordSheet extends StatefulWidget {
  final String initialPhone;
  final Function(String phone, String newPassword)? onSuccess;

  const ForgotPasswordSheet({
    super.key,
    this.initialPhone = '',
    this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    String initialPhone = '',
    Function(String phone, String newPassword)? onSuccess,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ForgotPasswordSheet(
        initialPhone: initialPhone,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet>
    with SingleTickerProviderStateMixin {
  // Steps:
  // 1: Enter Phone Number
  // 2: SMS OTP Verification Screen
  // 3: Create New Password Screen
  // 4: Password Reset Success Screen
  int _currentStep = 1;
  bool _isLoading = false;

  // Step 1: International Phone Input
  late TextEditingController _phoneController;
  Country _selectedCountry = CountryParser.parseCountryCode('IN');
  final _step1FormKey = GlobalKey<FormState>();

  String get _fullPhoneE164 => '+${_selectedCountry.phoneCode}${_phoneController.text.trim()}';

  // Step 2: 6 individual OTP boxes
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());

  Timer? _expiryTimer;
  int _expiryRemainingSeconds = 300; // 5 minutes

  Timer? _cooldownTimer;
  int _cooldownRemainingSeconds = 60; // 60s cooldown

  String? _resetToken; // Single-use reset authorization token

  // Step 3: Create New Password
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _step3FormKey = GlobalKey<FormState>();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Step 4: Success animation controller
  late AnimationController _successAnimController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone);
    _successAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _successAnimController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _cooldownTimer?.cancel();
    _successAnimController.dispose();
    _phoneController.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Masking format matching: +91 ******3210
  String _maskPhone(String phone) {
    final trimmed = phone.trim();
    if (trimmed.length <= 4) return trimmed;
    final prefix = '+${_selectedCountry.phoneCode}';
    final last4 = trimmed.substring(trimmed.length - 4);
    return '$prefix ******$last4';
  }

  void _openCountryPicker() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      countryListTheme: CountryListThemeData(
        backgroundColor: const Color(0xFF0E1726),
        bottomSheetHeight: MediaQuery.of(context).size.height * 0.65,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        textStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13.5),
        searchTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13.5),
        inputDecoration: InputDecoration(
          hintText: 'Search country or dialing code...',
          hintStyle: GoogleFonts.plusJakartaSans(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 13,
          ),
          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.white60),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.06),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 1.5),
          ),
        ),
      ),
      onSelect: (Country country) {
        if (mounted) {
          setState(() {
            _selectedCountry = country;
          });
        }
      },
    );
  }

  // --- Timers ---
  void _startExpiryTimer() {
    _expiryTimer?.cancel();
    _expiryRemainingSeconds = 300; // 5 minutes
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_expiryRemainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _expiryRemainingSeconds = 0;
        });
      } else {
        setState(() {
          _expiryRemainingSeconds--;
        });
      }
    });
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    _cooldownRemainingSeconds = 60; // 60s
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownRemainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _cooldownRemainingSeconds = 0;
        });
      } else {
        setState(() {
          _cooldownRemainingSeconds--;
        });
      }
    });
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _clearOtpBoxes() {
    for (final controller in _otpControllers) {
      controller.clear();
    }
  }

  String _getEnteredOtp() {
    return _otpControllers.map((c) => c.text.trim()).join();
  }

  // --- Step 1: Request SMS OTP ---
  Future<void> _requestOtp() async {
    final requestId = 'fp_${DateTime.now().millisecondsSinceEpoch}';
    debugPrint('[FP_TRACE][$requestId] Send Verification Code button tapped (isLoading=$_isLoading)');
    if (_isLoading) return;
    if (!_step1FormKey.currentState!.validate()) {
      debugPrint('[FP_TRACE][$requestId] Phone form validation failed');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final phone = _fullPhoneE164;
      final suffix = phone.length >= 4 ? phone.substring(phone.length - 4) : 'xxxx';
      debugPrint('[FP_TRACE][$requestId] Phone validated (ending=***$suffix). Calling storage.requestForgotPasswordOtp');
      final result = await storage.requestForgotPasswordOtp(phone, requestId: requestId);
      debugPrint('[FP_TRACE][$requestId] Result received: success=${result['success']}');

      if (!mounted) return;

      if (result['success'] == true) {
        AppNotification.success(
          context,
          title: 'SMS Code Sent',
          message: result['message'] ??
              'A 6-digit verification code has been sent via SMS.',
        );

        _clearOtpBoxes();
        _startExpiryTimer();
        _startCooldownTimer();

        setState(() {
          _currentStep = 2; // Transition to OTP Verification Screen
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _otpFocusNodes[0].canRequestFocus) {
            _otpFocusNodes[0].requestFocus();
          }
        });
      } else {
        AppNotification.error(
          context,
          title: 'Request Failed',
          message: result['error'] ?? 'Could not send verification SMS.',
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

  // --- Step 2: Resend SMS OTP ---
  Future<void> _resendOtp() async {
    if (_isLoading || _cooldownRemainingSeconds > 0) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final result = await storage.resendForgotPasswordOtp(_fullPhoneE164);

      if (!mounted) return;

      if (result['success'] == true) {
        AppNotification.success(
          context,
          title: 'New Code Sent',
          message: result['message'] ??
              'A fresh 6-digit verification code has been sent via SMS.',
        );

        _clearOtpBoxes();
        _startExpiryTimer();
        _startCooldownTimer();

        if (_otpFocusNodes[0].canRequestFocus) {
          _otpFocusNodes[0].requestFocus();
        }
      } else {
        AppNotification.error(
          context,
          title: 'Resend Failed',
          message: result['error'] ?? 'Failed to resend verification SMS.',
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

  // --- Step 2: Verify OTP ---
  Future<void> _verifyOtp() async {
    if (_isLoading) return;

    final otp = _getEnteredOtp();
    if (otp.length != 6) {
      AppNotification.warning(
        context,
        title: 'Incomplete OTP',
        message: 'Please enter all 6 digits of the verification code.',
      );
      return;
    }

    if (_expiryRemainingSeconds <= 0) {
      AppNotification.error(
        context,
        title: 'OTP Expired',
        message: 'The verification code has expired. Please tap Resend Code.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final result = await storage.verifyForgotPasswordOtp(_fullPhoneE164, otp);

      if (!mounted) return;

      if (result['success'] == true) {
        _resetToken = result['resetToken']?.toString();
        _expiryTimer?.cancel();
        _cooldownTimer?.cancel();

        AppNotification.success(
          context,
          title: 'Phone Verified',
          message: 'Code verified successfully. Please create a new password.',
        );

        setState(() {
          _currentStep = 3; // Navigate to Create New Password Screen
        });
      } else {
        AppNotification.error(
          context,
          title: 'Verification Failed',
          message: result['error'] ?? 'Invalid verification code.',
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

  // --- Step 3: Reset Password ---
  Future<void> _resetPassword() async {
    if (_isLoading) return;
    if (!_step3FormKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final newPass = _newPasswordController.text;
      final confirmPass = _confirmPasswordController.text;

      final result = await storage.resetForgotPassword(
        phone: _fullPhoneE164,
        resetToken: _resetToken,
        otp: _getEnteredOtp(),
        newPassword: newPass,
        confirmPassword: confirmPass,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        _successAnimController.forward(from: 0.0);
        setState(() {
          _currentStep = 4; // Navigate to Password Reset Success Screen!
        });
      } else {
        AppNotification.error(
          context,
          title: 'Reset Failed',
          message: result['error'] ?? 'Failed to reset password. Please try again.',
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

  // --- OTP Box Input Handler with Auto-Focus & Paste Support ---
  void _onOtpDigitChanged(int index, String value) {
    if (value.length > 1) {
      // User pasted multiple characters (e.g. 6-digit OTP)
      final digits = value.replaceAll(RegExp(r'\D'), '');
      if (digits.isNotEmpty) {
        for (int i = 0; i < 6; i++) {
          if (i < digits.length) {
            _otpControllers[i].text = digits[i];
          }
        }
        final targetIndex = (digits.length - 1).clamp(0, 5);
        _otpFocusNodes[targetIndex].requestFocus();
        setState(() {});
        return;
      }
    }

    if (value.isNotEmpty) {
      // Advance to next box
      if (index < 5) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
      }
    }
    setState(() {});
  }

  Widget _buildSingleOtpBox(int index) {
    final hasValue = _otpControllers[index].text.isNotEmpty;
    final isFocused = _otpFocusNodes[index].hasFocus;

    return Expanded(
      child: Container(
        height: 52,
        margin: EdgeInsets.symmetric(horizontal: index == 0 || index == 5 ? 2 : 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isFocused
                ? AppTheme.primaryBlue
                : hasValue
                    ? AppTheme.primaryGreen.withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.15),
            width: isFocused ? 2.0 : 1.2,
          ),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Focus(
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.backspace) {
              if (_otpControllers[index].text.isEmpty && index > 0) {
                _otpFocusNodes[index - 1].requestFocus();
                _otpControllers[index - 1].clear();
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          child: TextFormField(
            controller: _otpControllers[index],
            focusNode: _otpFocusNodes[index],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6, // Allows paste of complete 6 digits into any field
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
            ],
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: (val) => _onOtpDigitChanged(index, val),
          ),
        ),
      ),
    );
  }

  // --- Password Strength Badges ---
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

    String headerTitle;
    String headerSubtitle;
    IconData headerIcon;

    if (_currentStep == 1) {
      headerTitle = 'Forgot Password';
      headerSubtitle = 'Enter your registered phone number to receive an SMS OTP';
      headerIcon = Icons.lock_reset_rounded;
    } else if (_currentStep == 2) {
      headerTitle = 'Verify Your Phone';
      headerSubtitle = "We've sent a 6-digit SMS verification code to your phone number.";
      headerIcon = Icons.sms_outlined;
    } else if (_currentStep == 3) {
      headerTitle = 'Create New Password';
      headerSubtitle = 'Your phone has been verified. Create a new password for your account.';
      headerIcon = Icons.security_rounded;
    } else {
      headerTitle = 'Password Reset Successful!';
      headerSubtitle = 'Your password has been updated successfully.';
      headerIcon = Icons.check_circle_outline_rounded;
    }

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

            // Header Row (if not success step)
            if (_currentStep != 4)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
                    ),
                    child: Icon(
                      headerIcon,
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
                          headerTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          headerSubtitle,
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
            if (_currentStep != 4) const SizedBox(height: 20),

            // STEP CONTENT
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _buildCurrentStepContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStep1Phone();
      case 2:
        return _buildStep2Otp();
      case 3:
        return _buildStep3NewPassword();
      case 4:
        return _buildStep4Success();
      default:
        return const SizedBox.shrink();
    }
  }

  // --- Step 1 View: International Phone Number Input ---
  Widget _buildStep1Phone() {
    return Form(
      key: _step1FormKey,
      child: Column(
        key: const ValueKey('step1'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registered Phone Number',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: _openCountryPicker,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCountry.flagEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '+${_selectedCountry.phoneCode}',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: Colors.white60,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter 10-digit phone number',
                    hintStyle: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 13,
                    ),
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    filled: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: Colors.white60),
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
                    final digits = (value ?? '').trim();
                    if (digits.isEmpty) {
                      return 'Please enter your registered phone number.';
                    }
                    if (digits.length != 10) {
                      return 'Phone number must be exactly 10 digits.';
                    }
                    return null;
                  },
                ),
              ),
            ],
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
    );
  }

  // --- Step 2 View: 6-Digit SMS OTP Verification Screen ---
  Widget _buildStep2Otp() {
    final isExpired = _expiryRemainingSeconds <= 0;
    final canResend = _cooldownRemainingSeconds == 0 && !_isLoading;
    final enteredOtp = _getEnteredOtp();
    final canVerify = enteredOtp.length == 6 && !_isLoading && !isExpired;

    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Masked phone pill with option to edit
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.sms_outlined, size: 16, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sent via SMS to: ${_maskPhone(_phoneController.text)}',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              GestureDetector(
                onTap: _isLoading
                    ? null
                    : () {
                        setState(() {
                          _currentStep = 1;
                        });
                      },
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    'Change',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.primaryGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 6 Individual OTP Digit Input Boxes
        Text(
          'Enter 6-Digit Verification Code',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
        const SizedBox(height: 10),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (index) => _buildSingleOtpBox(index)),
        ),
        const SizedBox(height: 14),

        // Expiration Countdown & Cooldown Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 5-min Expiration Timer
            Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 15,
                  color: isExpired
                      ? const Color(0xFFEF4444)
                      : _expiryRemainingSeconds < 60
                          ? const Color(0xFFF59E0B)
                          : AppTheme.primaryBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  isExpired
                      ? 'Code expired'
                      : 'Expires in ${_formatTimer(_expiryRemainingSeconds)}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isExpired
                        ? const Color(0xFFEF4444)
                        : _expiryRemainingSeconds < 60
                            ? const Color(0xFFF59E0B)
                            : Colors.white70,
                  ),
                ),
              ],
            ),

            // 60-second Cooldown / Resend Action
            canResend
                ? GestureDetector(
                    onTap: _resendOtp,
                    child: Text(
                      'Resend Code',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryGreen,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                : Text(
                    'Resend in ${_cooldownRemainingSeconds}s',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white38,
                    ),
                  ),
          ],
        ),
        const SizedBox(height: 22),

        // Verify OTP Button (Disabled until 6 digits entered)
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: canVerify ? _verifyOtp : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              disabledBackgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.35),
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white38,
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
                    'Verify Code',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 12),

        // Back option to return to email input screen
        Center(
          child: TextButton.icon(
            onPressed: _isLoading
                ? null
                : () {
                    setState(() {
                      _currentStep = 1;
                    });
                  },
            icon: const Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white70),
            label: Text(
              'Back to Email',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white70,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Step 3 View: Create New Password Screen ---
  Widget _buildStep3NewPassword() {
    return Form(
      key: _step3FormKey,
      child: Column(
        key: const ValueKey('step3'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 22),

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
        ],
      ),
    );
  }

  // --- Step 4 View: Password Reset Success Screen ---
  Widget _buildStep4Success() {
    return Column(
      key: const ValueKey('step4'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 12),
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryGreen.withValues(alpha: 0.15),
              border: Border.all(color: AppTheme.primaryGreen, width: 2.5),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppTheme.primaryGreen,
              size: 46,
            ),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Password Reset Successful!',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Your password has been updated successfully. You can now sign in using your new password.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              color: Colors.white70,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.onSuccess != null) {
                widget.onSuccess!(
                  _fullPhoneE164,
                  _newPasswordController.text,
                );
              }
              AppNotification.success(
                context,
                title: 'Password Updated',
                message: 'You can now sign in with your new password.',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(
              'Back to Login',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
