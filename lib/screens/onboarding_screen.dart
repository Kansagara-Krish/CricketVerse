import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _slides = [
    OnboardingData(
      title: "Follow Every Match Live",
      description: "Get real-time scores, deep AI insights, and immersive ball-by-ball commentary right from the stadium.",
      imagePath: "assets/images/onboarding_stadium.png",
      gradientStart: Color(0xFF0F4C81),
      gradientEnd: Color(0xFF1E3A8A),
      stepText: "STEP 1 OF 3",
    ),
    OnboardingData(
      title: "AI Voice Commentary",
      description: "Experience personalized match insights delivered via intelligent voice synthesis during live action.",
      imagePath: "assets/images/onboarding_commentary.png",
      gradientStart: Color(0xFF0284C7),
      gradientEnd: Color(0xFF0D9488),
      stepText: "STEP 2 OF 3",
    ),
    OnboardingData(
      title: "Real-Time Predictions",
      description: "Harness AI-driven match probabilities, live scorecards, and intelligent insights to stay ahead of every play.",
      imagePath: "assets/images/onboarding_prediction.png",
      gradientStart: Color(0xFF0284C7),
      gradientEnd: Color(0xFF10B981),
      stepText: "STEP 3 OF 3",
    ),
  ];

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToAuth();
    }
  }

  void _navigateToAuth() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final currentSlide = _slides[_currentPage];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Background Gradient decoration (Subtle light mode circles)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentSlide.gradientStart.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentSlide.gradientEnd.withValues(alpha: 0.08),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Top bar with Back/Skip
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _currentPage > 0
                          ? IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.black87),
                              onPressed: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                            )
                          : const SizedBox(width: 48),
                      TextButton(
                        onPressed: _navigateToAuth,
                        child: Text(
                          'Skip',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFF0284C7),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Carousel view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      final slide = _slides[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Illustration Container (High-fidelity Mockup style)
                            Container(
                              width: size.width * 0.85,
                              height: size.width * 0.85,
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F172A),
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                                boxShadow: [
                                  BoxShadow(
                                    color: slide.gradientStart.withValues(alpha: 0.12),
                                    blurRadius: 30,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: Image.asset(
                                  slide.imagePath,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Content Panel (floating card - Light theme white card)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Steps indicator dots
                      Row(
                        children: List.generate(
                          _slides.length,
                          (index) => Container(
                            margin: const EdgeInsets.only(right: 6),
                            width: _currentPage == index ? 24 : 8,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(3),
                              color: _currentPage == index
                                  ? const Color(0xFF0284C7)
                                  : Colors.black.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        currentSlide.title,
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Subtitle
                      Text(
                        currentSlide.description,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          height: 1.5,
                          color: const Color(0xFF475569),
                        ),
                      ),
                      
                      // Audio waves indicator for Step 2
                      if (_currentPage == 1) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 3, height: 16, decoration: BoxDecoration(color: const Color(0xFF0D9488), borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 3),
                            Container(width: 3, height: 26, decoration: BoxDecoration(color: const Color(0xFF0284C7), borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 3),
                            Container(width: 3, height: 12, decoration: BoxDecoration(color: const Color(0xFF0D9488), borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 3),
                            Container(width: 3, height: 22, decoration: BoxDecoration(color: const Color(0xFF0284C7), borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 3),
                            Container(width: 3, height: 8, decoration: BoxDecoration(color: const Color(0xFF0D9488), borderRadius: BorderRadius.circular(2))),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Action bar: Step indicator and next button
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            currentSlide.stepText,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 1.0,
                            ),
                          ),
                          
                          // Circular action button or "Get Started"
                          _currentPage == _slides.length - 1
                              ? ElevatedButton(
                                  onPressed: _navigateToAuth,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0284C7),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Get Started',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward, size: 18),
                                    ],
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentPage == 1
                                        ? const Color(0xFFFBBF24) // Yellow button for Step 2
                                        : const Color(0xFF0284C7), // Blue button for Step 1
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.arrow_forward,
                                      color: _currentPage == 1 ? Colors.black87 : Colors.white,
                                    ),
                                    onPressed: _onNext,
                                    padding: const EdgeInsets.all(16),
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final String imagePath;
  final Color gradientStart;
  final Color gradientEnd;
  final String stepText;

  OnboardingData({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.gradientStart,
    required this.gradientEnd,
    required this.stepText,
  });
}
