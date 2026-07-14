import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import 'admin_dashboard.dart';
import 'scorer_dashboard.dart';
import 'user_dashboard.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isSignUp = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final storage = Provider.of<StorageService>(context, listen: false);
    final email = _emailController.text.trim();
    final pass = _passwordController.text.trim();

    if (_isSignUp) {
      if (pass != _confirmPasswordController.text.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match!')),
        );
        return;
      }
      final success = storage.register(email, pass);
      if (success) {
        _navigateByUserRole();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User already exists!')),
        );
      }
    } else {
      final success = storage.login(email, pass);
      if (success) {
        _navigateByUserRole();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials! Try user@gmail.com / user123 or admin@cricketverse.ai / admin123')),
        );
      }
    }
  }

  void _navigateByUserRole() {
    final storage = Provider.of<StorageService>(context, listen: false);
    final role = storage.currentRole;

    Widget destination;
    if (role == 'Admin') {
      destination = const AdminDashboard();
    } else if (role == 'Scorer') {
      destination = const ScorerDashboard();
    } else {
      destination = const UserDashboard();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => destination),
    );
  }

  void _continueAsGuest() {
    Provider.of<StorageService>(context, listen: false).loginAsGuest();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const UserDashboard()),
    );
  }

  void _quickLogin(String email, String password) {
    final storage = Provider.of<StorageService>(context, listen: false);
    final success = storage.login(email, password);
    if (success) {
      _navigateByUserRole();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quick login failed for $email')),
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
      height: 44,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withAlpha(38), // ~15% opacity
          foregroundColor: color,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withAlpha(76), width: 1), // ~30% opacity
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Blurred background lights (simulate stadium floodlights)
          Positioned(
            top: 100,
            left: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFBBF24).withAlpha(20),
              ),
            ),
          ),
          Positioned(
            top: 120,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0284C7).withAlpha(20),
              ),
            ),
          ),
          
          SingleChildScrollView(
            child: Container(
              width: size.width,
              height: size.height,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Logo Container
                  Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF1F5F9),
                      image: DecorationImage(
                        image: AssetImage('assets/images/logo.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    'CricketVerse AI',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'The future of the game.',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 32),
    
                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(12),
                          blurRadius: 15,
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
                            style: GoogleFonts.outfit(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 20),
    
                          // Email Field
                          Text(
                            'Email Address',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: const Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _emailController,
                            style: GoogleFonts.outfit(color: Colors.black87, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Enter your email or username',
                              hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
                              fillColor: const Color(0xFFF1F5F9),
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter email/username';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
    
                          // Password Field
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Password',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: const Color(0xFF475569),
                                ),
                              ),
                              if (!_isSignUp)
                                GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Password recovery simulated!')),
                                    );
                                  },
                                  child: Text(
                                    'Forgot?',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: const Color(0xFFB45309), // Amber-Brown
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            style: GoogleFonts.outfit(color: Colors.black87, fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Enter password',
                              hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
                              fillColor: const Color(0xFFF1F5F9),
                              filled: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2),
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
                            const SizedBox(height: 16),
                            Text(
                              'Confirm Password',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF475569),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: true,
                              style: GoogleFonts.outfit(color: Colors.black87, fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Re-enter password',
                                hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8), fontSize: 13),
                                fillColor: const Color(0xFFF1F5F9),
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF0284C7), width: 2),
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
                          const SizedBox(height: 24),
    
                          // Sign In/Up Button (Dark blue style)
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF094CB2), // Darker vibrant blue
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                _isSignUp ? 'Sign Up' : 'Sign In',
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
    
                          // OR Separator
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'OR',
                                  style: GoogleFonts.outfit(fontSize: 11, color: const Color(0xFF94A3B8)),
                                ),
                              ),
                              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                            ],
                          ),
                          const SizedBox(height: 16),
    
                          // Google Login Button (Solid White)
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: _continueAsGuest,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black87,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.network(
                                    'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/24px-Google_%22G%22_logo.svg.png',
                                    height: 18,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata_rounded, color: Colors.redAccent, size: 28),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Continue with Google',
                                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Quick Role Login Buttons
                          Row(
                            children: [
                              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text(
                                  'QUICK LOGIN AS',
                                  style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF94A3B8), letterSpacing: 1),
                                ),
                              ),
                              const Expanded(child: Divider(color: Color(0xFFE2E8F0))),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _buildQuickLoginButton(
                                  label: 'Admin',
                                  color: const Color(0xFFEF4444),
                                  icon: Icons.admin_panel_settings_rounded,
                                  onTap: () => _quickLogin('admin@cricketverse.ai', 'admin123'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildQuickLoginButton(
                                  label: 'Manager',
                                  color: const Color(0xFFD97706),
                                  icon: Icons.manage_accounts_rounded,
                                  onTap: () => _quickLogin('scorer1', '123'),
                                ),
                              ),
                              const SizedBox(width: 8),
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
                          const SizedBox(height: 24),
    
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
                                  style: GoogleFonts.outfit(color: const Color(0xFF475569), fontSize: 13),
                                  children: [
                                    TextSpan(
                                      text: _isSignUp ? 'Sign In' : 'Sign Up',
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF0284C7), // Yellow
                                        fontWeight: FontWeight.bold,
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
                  const SizedBox(height: 24),
    
                  // Continue as Guest link
                  TextButton(
                    onPressed: _continueAsGuest,
                    child: Text(
                      'CONTINUE AS GUEST',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF64748B),
                        fontSize: 12,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
