import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../services/storage_service.dart';
import '../services/socket_service.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_theme.dart';
import 'package:flutter/services.dart';
import '../core/widgets/exit_app_dialog.dart';
import '../core/widgets/custom_notification.dart';
import '../core/widgets/app_notification.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  String? _emailServerError;

  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Background Video Controller
  late VideoPlayerController _videoController;

  // Form Fade Animation Controllers
  late AnimationController _fadeController;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;

  @override
  void initState() {
    super.initState();
    
    // Register global socket notification listener
    SocketService.connect();
    SocketService.listenToGlobalNotifications((data) {
      if (mounted) {
        CustomNotification.show(
          context,
          data['message'] ?? 'Notification received',
          type: NotificationType.info,
        );
      }
    });

    // Setup Background Video Player
    _videoController = VideoPlayerController.asset('assets/images/stadium_video.mp4')
      ..initialize().then((_) {
        setState(() {});
      })
      ..setLooping(true)
      ..setVolume(0)
      ..play();

    // Setup Form Entrance Animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _formFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: const Interval(0.2, 1.0, curve: Curves.easeOut)),
    );

    _formSlide = Tween<Offset>(begin: const Offset(0.0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(parent: _fadeController, curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic)),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    if (_videoController.value.isInitialized && _videoController.value.isPlaying) {
      _videoController.pause();
    }
    _videoController.dispose();
    _fadeController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading) return; // Prevent multiple requests

    setState(() {
      _emailServerError = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final storage = Provider.of<StorageService>(context, listen: false);
      final rawInput = _emailController.text.trim();
      final loginIdentifier = rawInput.contains('@') ? rawInput.toLowerCase() : rawInput;
      final pass = _passwordController.text;
      final name = _nameController.text.trim();

      if (_isSignUp) {
        final email = rawInput.toLowerCase();
        final confirmPass = _confirmPasswordController.text;
        if (pass != confirmPass) {
          AppNotification.error(
            context,
            title: 'Validation Error',
            message: 'Passwords do not match.',
          );
          return;
        }

        final success = await storage.register(
          name: name,
          email: email,
          password: pass,
          confirmPassword: confirmPass,
        );

        if (!mounted) return;

        if (success) {
          AppNotification.success(
            context,
            title: 'Success',
            message: 'Account created successfully.',
          );
          _navigateByUserRole();
        } else {
          final errorMsg = storage.lastAuthError ?? 'Registration failed. Please try again.';
          if (storage.lastAuthErrorField == 'email' || errorMsg.toLowerCase().contains('email')) {
            setState(() {
              _emailServerError = errorMsg;
            });
            _formKey.currentState?.validate();
          }
          AppNotification.error(
            context,
            title: 'Registration Error',
            message: errorMsg,
          );
        }
      } else {
        final success = await storage.login(loginIdentifier, pass);
        if (!mounted) return;
        if (success) {
          NotificationService.success(
            context: context,
            title: 'Welcome back',
          );
          _navigateByUserRole();
        } else {
          AppNotification.error(
            context,
            title: 'Authentication Failed',
            message: 'Invalid credentials! Please check your email/username and password.',
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateByUserRole() {
    final storage = Provider.of<StorageService>(context, listen: false);
    final role = storage.currentRole;

    if (role == 'Admin') {
      Navigator.pushReplacementNamed(context, AppRoutes.adminDashboard);
    } else if (role == 'Scorer') {
      Navigator.pushReplacementNamed(context, AppRoutes.scorerDashboard);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.userDashboard);
    }
  }

  Widget _buildPasswordRequirements() {
    final pass = _passwordController.text;
    if (pass.isEmpty) {
      return const SizedBox.shrink();
    }

    String? wrongCondition;
    if (pass.contains(' ')) {
      wrongCondition = 'Password cannot contain spaces';
    } else if (pass.length < 8) {
      wrongCondition = 'Must be at least 8 characters long';
    } else if (!RegExp(r'[A-Z]').hasMatch(pass)) {
      wrongCondition = 'Must contain at least one uppercase letter (A-Z)';
    } else if (!RegExp(r'[a-z]').hasMatch(pass)) {
      wrongCondition = 'Must contain at least one lowercase letter (a-z)';
    } else if (!RegExp(r'[0-9]').hasMatch(pass)) {
      wrongCondition = 'Must contain at least one number (0-9)';
    } else if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{};\x27:"\\|,.<>/?]').hasMatch(pass)) {
      wrongCondition = 'Must contain at least one special symbol (!@#\$%^&*...)';
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            child: child,
          ),
        );
      },
      child: wrongCondition != null
          ? Container(
              key: ValueKey(wrongCondition),
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.accentRed.withValues(alpha: 0.30),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 13.5,
                    color: AppTheme.accentRed,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      wrongCondition,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        color: const Color(0xFFFF6B81),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Container(
              key: const ValueKey('password_valid'),
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 13.5,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Strong password',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // 1. If currently in Sign Up mode, switch back to Sign In
        if (_isSignUp) {
          setState(() {
            _isSignUp = false;
          });
          return;
        }

        // 2. If can pop (e.g. from onboarding), pop
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
          return;
        }

        // 3. On the LAST page (Login) -> confirm before closing app
        final shouldExit = await ExitAppDialog.show(context);
        if (shouldExit) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
          // Auto-playing video player background (zoomed to crop/hide top-right watermark)
          _videoController.value.isInitialized
              ? SizedBox.expand(
                  child: ClipRect(
                    child: Transform.scale(
                      scale: 1.15,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController.value.size.width,
                          height: _videoController.value.size.height,
                          child: VideoPlayer(_videoController),
                        ),
                      ),
                    ),
                  ),
                )
              : Container(color: Colors.black),
          
          // Premium dark stadium overlay (slightly lightened to allow background details to pop)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          // Form Content
          SafeArea(
            child: SingleChildScrollView(
              child: Container(
                width: size.width,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _formFade,
                  child: SlideTransition(
                    position: _formSlide,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        // Logo Container
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryBlue.withValues(alpha: 0.3),
                                blurRadius: 16,
                              )
                            ],
                            image: const DecorationImage(
                              image: AssetImage('assets/images/logo.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Title
                        Text(
                          'CricketVerse AI',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'INTELLIGENCE MEETS ACTION',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.6),
                            letterSpacing: 2.5,
                          ),
                        ),
                        const SizedBox(height: 24),
          
                        // Form Card (Glassmorphism look)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 24,
                                    offset: const Offset(0, 10),
                                  )
                                ]
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _isSignUp ? 'Create Account' : 'Welcome Back',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
              
                                    // Full Name Field (only for Sign Up)
                                    if (_isSignUp) ...[
                                      Text(
                                        'Full Name',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withValues(alpha: 0.85),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _nameController,
                                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13.5),
                                        decoration: InputDecoration(
                                          hintText: 'Enter your full name',
                                          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.4), fontSize: 12.5),
                                          fillColor: Colors.white.withValues(alpha: 0.06),
                                          filled: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          prefixIcon: const Icon(Icons.person_outline, size: 16, color: Colors.white60),
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
                                          if (_isSignUp && (value == null || value.trim().isEmpty)) {
                                            return 'Please enter your full name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 14),
                                    ],

                                    // Email / Username Field
                                    Text(
                                      _isSignUp ? 'Email Address' : 'Email or Username',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType: _isSignUp ? TextInputType.emailAddress : TextInputType.text,
                                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13.5),
                                      onChanged: (val) {
                                        if (_emailServerError != null) {
                                          setState(() {
                                            _emailServerError = null;
                                          });
                                        }
                                      },
                                      decoration: InputDecoration(
                                        hintText: _isSignUp ? 'Enter your email address' : 'Enter your email or username',
                                        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.4), fontSize: 12.5),
                                        fillColor: Colors.white.withValues(alpha: 0.06),
                                        filled: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        prefixIcon: Icon(_isSignUp ? Icons.email_outlined : Icons.person_outline, size: 16, color: Colors.white60),
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
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: AppTheme.accentRed, width: 1.2),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: AppTheme.accentRed, width: 1.5),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (_emailServerError != null) {
                                          return _emailServerError;
                                        }
                                        if (value == null || value.trim().isEmpty) {
                                          return _isSignUp ? 'Email is required.' : 'Please enter your email or username.';
                                        }
                                        final trimmed = value.trim();
                                        if (trimmed.contains(' ')) {
                                          return _isSignUp ? 'Email cannot contain spaces.' : 'Cannot contain spaces.';
                                        }

                                        if (_isSignUp) {
                                          final atMatches = '@'.allMatches(trimmed);
                                          if (atMatches.length != 1) {
                                            return 'Please enter a valid email address.';
                                          }
                                          final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                          if (!emailRegex.hasMatch(trimmed)) {
                                            return 'Please enter a valid email address.';
                                          }
                                          final parts = trimmed.split('@');
                                          if (parts.length != 2 ||
                                              parts[0].isEmpty ||
                                              parts[1].isEmpty ||
                                              parts[1].startsWith('.') ||
                                              parts[1].endsWith('.') ||
                                              !parts[1].contains('.')) {
                                            return 'Please enter a valid email address.';
                                          }
                                        } else {
                                          // Login Mode: Allow both valid email AND manager/scorer username
                                          if (trimmed.contains('@')) {
                                            final atMatches = '@'.allMatches(trimmed);
                                            if (atMatches.length != 1) {
                                              return 'Please enter a valid email address.';
                                            }
                                            final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                                            if (!emailRegex.hasMatch(trimmed)) {
                                              return 'Please enter a valid email address.';
                                            }
                                          } else {
                                            if (trimmed.length < 2) {
                                              return 'Please enter a valid username.';
                                            }
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 14),
              
                                    // Password Field
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Password',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white.withValues(alpha: 0.85),
                                          ),
                                        ),
                                        if (!_isSignUp)
                                          GestureDetector(
                                            onTap: () {
                                              AppNotification.info(
                                                context,
                                                title: 'Password Recovery',
                                                message: 'Password recovery link simulated!',
                                              );
                                            },
                                            child: Text(
                                              'Forgot?',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 11,
                                                color: AppTheme.primaryBlue,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13.5),
                                      onChanged: (_) {
                                        if (_isSignUp) {
                                          setState(() {});
                                        }
                                      },
                                      decoration: InputDecoration(
                                        hintText: _isSignUp ? 'Create strong password' : 'Enter password',
                                        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.4), fontSize: 12.5),
                                        fillColor: Colors.white.withValues(alpha: 0.06),
                                        filled: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        prefixIcon: const Icon(Icons.lock_outline, size: 16, color: Colors.white60),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                            size: 18,
                                            color: Colors.white60,
                                          ),
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword = !_obscurePassword;
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
                                        errorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: AppTheme.accentRed, width: 1.2),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: AppTheme.accentRed, width: 1.5),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Password is required.';
                                        }
                                        if (!_isSignUp) return null;

                                        if (value.contains(' ')) {
                                          return 'Password cannot contain spaces.';
                                        }
                                        if (value.length < 8) {
                                          return 'Password must be at least 8 characters long.';
                                        }
                                        if (!RegExp(r'[A-Z]').hasMatch(value)) {
                                          return 'Password must contain at least one uppercase letter.';
                                        }
                                        if (!RegExp(r'[a-z]').hasMatch(value)) {
                                          return 'Password must contain at least one lowercase letter.';
                                        }
                                        if (!RegExp(r'[0-9]').hasMatch(value)) {
                                          return 'Password must contain at least one number.';
                                        }
                                        if (!RegExp(r'[!@#$%^&*()_+\-=\[\]{};\x27:"\\|,.<>/?]').hasMatch(value)) {
                                          return 'Password must contain at least one special symbol.';
                                        }
                                        return null;
                                      },
                                    ),

                                    // Real-Time Password Requirements Checklist (Sign Up only)
                                    if (_isSignUp)
                                      _buildPasswordRequirements(),
                                    
                                    // Confirm Password Field (only for Sign Up)
                                    if (_isSignUp) ...[
                                      const SizedBox(height: 14),
                                      Text(
                                        'Confirm Password',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white.withValues(alpha: 0.85),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _confirmPasswordController,
                                        obscureText: _obscureConfirmPassword,
                                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13.5),
                                        onChanged: (_) {
                                          if (_confirmPasswordController.text.isNotEmpty) {
                                            setState(() {});
                                          }
                                        },
                                        decoration: InputDecoration(
                                          hintText: 'Re-enter password',
                                          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.4), fontSize: 12.5),
                                          fillColor: Colors.white.withValues(alpha: 0.06),
                                          filled: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          prefixIcon: const Icon(Icons.lock_outline, size: 16, color: Colors.white60),
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
                                          errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: AppTheme.accentRed, width: 1.2),
                                          ),
                                          focusedErrorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(color: AppTheme.accentRed, width: 1.5),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (_isSignUp) {
                                            if (value == null || value.isEmpty) {
                                              return 'Confirm password is required.';
                                            }
                                            if (value != _passwordController.text) {
                                              return 'Passwords do not match.';
                                            }
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                    const SizedBox(height: 20),
              
                                    // Sign In/Up Button with Loading State
                                    SizedBox(
                                      width: double.infinity,
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryBlue,
                                          disabledBackgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.6),
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
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
                                                _isSignUp ? 'Sign Up' : 'Sign In',
                                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14.5),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    const SizedBox(height: 20),
              
                                    // Sign In/Up Toggle
                                    Center(
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _isSignUp = !_isSignUp;
                                          });
                                        },
                                        child: RichText(
                                          text: TextSpan(
                                            text: _isSignUp ? 'Already have an account? ' : 'New to CricketVerse? ',
                                            style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                                            children: [
                                              TextSpan(
                                                text: _isSignUp ? 'Sign In' : 'Sign Up',
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: AppTheme.primaryBlue,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}
