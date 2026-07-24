import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../services/storage_service.dart';
import '../core/routes/app_routes.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/custom_notification.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool _isSignUp = false;
  final _emailController = TextEditingController();
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
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final storage = Provider.of<StorageService>(context, listen: false);
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (_isSignUp) {
      if (pass != _confirmPasswordController.text.trim()) {
        CustomNotification.show(
          context,
          'Passwords do not match!',
          type: NotificationType.error,
        );
        return;
      }
      final success = await storage.register(email, pass);
      if (!mounted) return;
      if (success) {
        CustomNotification.show(
          context,
          'Account created successfully!',
          type: NotificationType.success,
        );
        _navigateByUserRole();
      } else {
        CustomNotification.show(
          context,
          'User already exists!',
          type: NotificationType.error,
        );
      }
    } else {
      final success = await storage.login(email, pass);
      if (!mounted) return;
      if (success) {
        CustomNotification.show(
          context,
          'Welcome back, ${storage.currentRole}!',
          type: NotificationType.success,
        );
        _navigateByUserRole();
      } else {
        CustomNotification.show(
          context,
          'Invalid credentials! Use admin@cricketverse.ai / admin123',
          type: NotificationType.error,
        );
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

  void _continueAsGuest() {
    Provider.of<StorageService>(context, listen: false).loginAsGuest();
    CustomNotification.show(
      context,
      'Logged in as Guest',
      type: NotificationType.info,
    );
    Navigator.pushReplacementNamed(context, AppRoutes.userDashboard);
  }

  Future<void> _quickLogin(String email, String password) async {
    final storage = Provider.of<StorageService>(context, listen: false);
    final success = await storage.login(email, password);
    if (!mounted) return;
    if (success) {
      CustomNotification.show(
        context,
        'Logged in successfully as $email',
        type: NotificationType.success,
      );
      _navigateByUserRole();
    } else {
      CustomNotification.show(
        context,
        'Quick login failed for $email',
        type: NotificationType.error,
      );
    }
  }

  Widget _buildQuickLoginButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withValues(alpha: 0.12),
          foregroundColor: color,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: color.withValues(alpha: 0.35), width: 1.2),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 11,
                color: color,
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
    
    return Scaffold(
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
                            shape: BoxShape.circle,
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
              
                                    // Email Field
                                    Text(
                                      'Email Address',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withValues(alpha: 0.85),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    TextFormField(
                                      controller: _emailController,
                                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13.5),
                                      decoration: InputDecoration(
                                        hintText: 'Enter your email or username',
                                        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.4), fontSize: 12.5),
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
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                            return 'Please enter email/username';
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
                                              CustomNotification.show(
                                                context,
                                                'Password recovery link simulated!',
                                                type: NotificationType.info,
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
                                      obscureText: true,
                                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13.5),
                                      decoration: InputDecoration(
                                        hintText: 'Enter password',
                                        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.4), fontSize: 12.5),
                                        fillColor: Colors.white.withValues(alpha: 0.06),
                                        filled: true,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                        prefixIcon: const Icon(Icons.lock_outline, size: 16, color: Colors.white60),
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
                                          return 'Please enter password';
                                        }
                                        return null;
                                      },
                                    ),
                                    
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
                                        obscureText: true,
                                        style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13.5),
                                        decoration: InputDecoration(
                                          hintText: 'Re-enter password',
                                          hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.4), fontSize: 12.5),
                                          fillColor: Colors.white.withValues(alpha: 0.06),
                                          filled: true,
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          prefixIcon: const Icon(Icons.lock_outline, size: 16, color: Colors.white60),
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
                                          if (_isSignUp && (value == null || value.isEmpty)) {
                                            return 'Please confirm password';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                    const SizedBox(height: 20),
              
                                    // Sign In/Up Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 46,
                                      child: ElevatedButton(
                                        onPressed: _submit,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.primaryBlue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: Text(
                                          _isSignUp ? 'Sign Up' : 'Sign In',
                                          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14.5),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
              
                                    // OR Separator
                                    Row(
                                      children: [
                                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.18))),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: Text(
                                            'OR',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.18))),
                                      ],
                                    ),
                                    const SizedBox(height: 14),
              
                                    // Google Login Button (Solid White)
                                    SizedBox(
                                      width: double.infinity,
                                      height: 44,
                                      child: OutlinedButton(
                                        onPressed: _continueAsGuest,
                                        style: OutlinedButton.styleFrom(
                                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                                          foregroundColor: Colors.black87,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Image.network(
                                              'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
                                              height: 16,
                                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata_rounded, color: Colors.redAccent, size: 24),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Continue with Google',
                                              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),
              
                                    // Quick Role Login Buttons
                                    Row(
                                      children: [
                                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.18))),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 10),
                                          child: Text(
                                            'QUICK LOGIN',
                                            style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white.withValues(alpha: 0.5), letterSpacing: 0.8),
                                          ),
                                        ),
                                        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.18))),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: _buildQuickLoginButton(
                                            label: 'Admin',
                                            color: AppTheme.accentRed,
                                            icon: Icons.admin_panel_settings_rounded,
                                            onTap: () => _quickLogin('admin@cricketverse.ai', 'admin123'),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: _buildQuickLoginButton(
                                            label: 'Manager',
                                            color: const Color(0xFFD97706),
                                            icon: Icons.manage_accounts_rounded,
                                            onTap: () => _quickLogin('scorer1', '123'),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: _buildQuickLoginButton(
                                            label: 'User',
                                            color: const Color(0xFF059669),
                                            icon: Icons.person_rounded,
                                            onTap: () => _quickLogin('user@gmail.com', 'user123'),
                                          ),
                                        ),
                                      ],
                                    ),
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
                        const SizedBox(height: 16),
          
                        // Continue as Guest link
                        TextButton(
                          onPressed: _continueAsGuest,
                          child: Text(
                            'CONTINUE AS GUEST',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 11,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.w800,
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
    );
  }
}
