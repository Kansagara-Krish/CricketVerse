import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/models.dart';

// ─── Theme Colors ─────────────────────────────────────────────────────────────
class MilestoneTheme {
  static const Color primaryGreen = Color(0xFF078B70);
  static const Color darkEmerald  = Color(0xFF064E3B);
  static const Color deepEmerald  = Color(0xFF022C22);
  static const Color darkestNight = Color(0xFF011A14);
  static const Color premiumGold  = Color(0xFFD9A52A);
  static const Color accentGold   = Color(0xFFF59E0B);
  static const Color lightGold    = Color(0xFFFDE047);
  static const Color white        = Colors.white;

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFFBEB), Color(0xFFFDE047), Color(0xFFD9A52A), Color(0xFFB45309)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF064E3B), Color(0xFF022C22), Color(0xFF011A14)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient managerToastGradient = LinearGradient(
    colors: [Color(0xFF064E3B), Color(0xFF022C22)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

// ─── Confetti Particle Model & Painter ─────────────────────────────────────────
class _ConfettiParticle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  Color color;
  double rotation;
  double rotationSpeed;
  double wobble;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.color,
    required this.rotation,
    required this.rotationSpeed,
    required this.wobble,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final paint = Paint()
        ..color = p.color
        ..style = PaintingStyle.fill;

      canvas.save();
      final px = p.x * size.width;
      final py = p.y * size.height;
      canvas.translate(px, py);
      canvas.rotate(p.rotation);

      final w = p.size;
      final h = p.size * (0.4 + 0.6 * math.sin(p.wobble).abs());
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: w, height: h),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}

// ─── Fireworks Particle Model & Painter (Century Exclusive) ───────────────────
class _FireworkParticle {
  double x;
  double y;
  double vx;
  double vy;
  double alpha;
  double size;
  Color color;

  _FireworkParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.alpha,
    required this.size,
    required this.color,
  });
}

class _FireworksPainter extends CustomPainter {
  final List<_FireworkParticle> particles;

  _FireworksPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      if (p.alpha <= 0) continue;
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.alpha.clamp(0.0, 1.0))
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);

      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter oldDelegate) => true;
}

// ─── USER-SIDE CELEBRATION OVERLAY ─────────────────────────────────────────────
class MilestoneCelebrationOverlay extends StatefulWidget {
  final MilestoneCelebration milestone;
  final VoidCallback onDismiss;

  const MilestoneCelebrationOverlay({
    super.key,
    required this.milestone,
    required this.onDismiss,
  });

  @override
  State<MilestoneCelebrationOverlay> createState() => _MilestoneCelebrationOverlayState();
}

class _MilestoneCelebrationOverlayState extends State<MilestoneCelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glowAnimation;

  late AnimationController _particleController;
  final List<_ConfettiParticle> _confetti = [];
  final List<_FireworkParticle> _fireworks = [];
  final math.Random _random = math.Random();

  bool _isCentury = false;

  @override
  void initState() {
    super.initState();
    _isCentury = widget.milestone.type == '100' || widget.milestone.runs >= 100;
    final totalDurationMs = _isCentury ? 5000 : 3000;

    // Main entrance & exit controller
    _mainAnimController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalDurationMs),
    );

    // Dramatic entrance with overshoot
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.1, end: _isCentury ? 1.15 : 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 25.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: _isCentury ? 1.15 : 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 45.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 15.0,
      ),
    ]).animate(_mainAnimController);

    // Fade in and out
    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 70.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 15.0,
      ),
    ]).animate(_mainAnimController);

    // Continuous golden glow pulse
    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.4, end: 1.0), weight: 50.0),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.4), weight: 50.0),
    ]).animate(CurvedAnimation(parent: _mainAnimController, curve: Curves.easeInOut));

    // Particle simulation loop
    _initParticles();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(_updateParticles);
    _particleController.repeat();

    _mainAnimController.forward().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  void _initParticles() {
    final colors = [
      MilestoneTheme.premiumGold,
      MilestoneTheme.lightGold,
      MilestoneTheme.accentGold,
      MilestoneTheme.primaryGreen,
      Colors.white,
    ];

    final count = _isCentury ? 110 : 60;
    for (int i = 0; i < count; i++) {
      _confetti.add(_ConfettiParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble() * 0.4 - 0.4, // Staggered entry from top
        vx: (_random.nextDouble() - 0.5) * 0.006,
        vy: 0.004 + _random.nextDouble() * 0.008,
        size: 6.0 + _random.nextDouble() * (_isCentury ? 8.0 : 5.0),
        color: colors[_random.nextInt(colors.length)],
        rotation: _random.nextDouble() * math.pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.1,
        wobble: _random.nextDouble() * math.pi * 2,
      ));
    }
  }

  void _triggerFireworkBurst(double cx, double cy) {
    final colors = [
      MilestoneTheme.lightGold,
      MilestoneTheme.premiumGold,
      const Color(0xFFFDE047),
      Colors.white,
      MilestoneTheme.primaryGreen,
    ];
    for (int i = 0; i < 35; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 2.0 + _random.nextDouble() * 6.0;
      _fireworks.add(_FireworkParticle(
        x: cx,
        y: cy,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        alpha: 1.0,
        size: 2.5 + _random.nextDouble() * 3.0,
        color: colors[_random.nextInt(colors.length)],
      ));
    }
  }

  int _tickCount = 0;
  void _updateParticles() {
    _tickCount++;
    // Confetti physics
    for (final p in _confetti) {
      p.y += p.vy;
      p.x += p.vx + math.sin(p.wobble) * 0.0015;
      p.rotation += p.rotationSpeed;
      p.wobble += 0.05;

      // Wrap around top if still early in celebration
      if (p.y > 1.1 && _mainAnimController.value < 0.75) {
        p.y = -0.1;
        p.x = _random.nextDouble();
      }
    }

    // Fireworks physics (Century only)
    if (_isCentury) {
      if (_tickCount % 22 == 0 && _mainAnimController.value < 0.7) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final size = renderBox.size;
          _triggerFireworkBurst(
            size.width * (0.2 + _random.nextDouble() * 0.6),
            size.height * (0.15 + _random.nextDouble() * 0.45),
          );
        }
      }

      for (int i = _fireworks.length - 1; i >= 0; i--) {
        final f = _fireworks[i];
        f.x += f.vx;
        f.y += f.vy;
        f.vy += 0.12; // Gravity
        f.alpha -= 0.024;
        if (f.alpha <= 0) {
          _fireworks.removeAt(i);
        }
      }
    }

    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _particleController.dispose();
    _mainAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final isReducedMotion = media.disableAnimations;

    return GestureDetector(
      onTap: widget.onDismiss,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _mainAnimController,
        builder: (context, child) {
          final opacity = isReducedMotion ? 1.0 : _fadeAnimation.value.clamp(0.0, 1.0);
          final scale = isReducedMotion ? 1.0 : _scaleAnimation.value;

          return Opacity(
            opacity: opacity,
            child: Stack(
              children: [
                // 1. Dark Emerald Backdrop with Subtle Radiant Light
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.1),
                        radius: _isCentury ? 1.3 : 1.0,
                        colors: [
                          MilestoneTheme.darkEmerald.withValues(alpha: _isCentury ? 0.96 : 0.92),
                          MilestoneTheme.deepEmerald.withValues(alpha: 0.95),
                          MilestoneTheme.darkestNight.withValues(alpha: 0.98),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),
                ),

                // 2. Animated Particles (Confetti & Fireworks)
                if (!isReducedMotion) ...[
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ConfettiPainter(particles: _confetti),
                    ),
                  ),
                  if (_isCentury)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _FireworksPainter(particles: _fireworks),
                      ),
                    ),
                ],

                // 3. Central Celebration Content Card
                Center(
                  child: Transform.scale(
                    scale: scale,
                    child: _isCentury
                        ? _buildCenturyCelebrationCard(context)
                        : _buildHalfCenturyCelebrationCard(context),
                  ),
                ),

                // 4. Subtle Tap anywhere hint
                Positioned(
                  bottom: media.padding.bottom + 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: MilestoneTheme.premiumGold.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            size: 14,
                            color: MilestoneTheme.lightGold.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tap anywhere to resume match',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── HALF-CENTURY CELEBRATION CARD (Centered Overlay) ──────────────────────
  Widget _buildHalfCenturyCelebrationCard(BuildContext context) {
    final m = widget.milestone;

    return Container(
      width: math.min(MediaQuery.of(context).size.width * 0.88, 380),
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
      decoration: BoxDecoration(
        color: MilestoneTheme.deepEmerald.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: MilestoneTheme.premiumGold.withValues(alpha: 0.75),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: MilestoneTheme.premiumGold.withValues(alpha: 0.25 * _glowAnimation.value),
            blurRadius: 36,
            spreadRadius: 6,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Sparkle Heading Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MilestoneTheme.premiumGold.withValues(alpha: 0.25),
                  MilestoneTheme.primaryGreen.withValues(alpha: 0.35),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: MilestoneTheme.lightGold.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: MilestoneTheme.lightGold, size: 16),
                const SizedBox(width: 8),
                Text(
                  'HALF CENTURY!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.2,
                    color: MilestoneTheme.lightGold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.auto_awesome, color: MilestoneTheme.lightGold, size: 16),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Big Golden "50" with metallic gradient shader
          ShaderMask(
            shaderCallback: (bounds) => MilestoneTheme.goldGradient.createShader(bounds),
            child: Text(
              '50',
              style: GoogleFonts.outfit(
                fontSize: 84,
                fontWeight: FontWeight.w900,
                letterSpacing: -2,
                height: 1.0,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Batsman Full Name
          Text(
            m.batsmanName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),

          // Stats Pill: Runs & Balls Faced
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${m.runs} Runs',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: MilestoneTheme.lightGold,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Colors.white54,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  '${m.ballsFaced} Balls',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Team Name & Logo/Badge
          if (m.teamName.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _parseHexColor(m.teamColorHex).withValues(alpha: 0.3),
                    border: Border.all(
                      color: _parseHexColor(m.teamColorHex),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(Icons.sports_cricket_rounded, size: 14, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  m.teamName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ─── CENTURY CELEBRATION CARD (Grand Spectacular Full-Screen) ──────────────
  Widget _buildCenturyCelebrationCard(BuildContext context) {
    final m = widget.milestone;

    return Container(
      width: math.min(MediaQuery.of(context).size.width * 0.92, 440),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: MilestoneTheme.darkestNight.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: MilestoneTheme.lightGold,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: MilestoneTheme.lightGold.withValues(alpha: 0.35 * _glowAnimation.value),
            blurRadius: 48,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: MilestoneTheme.primaryGreen.withValues(alpha: 0.4),
            blurRadius: 36,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.75),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crown / Trophy Top Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: MilestoneTheme.goldGradient,
              boxShadow: [
                BoxShadow(
                  color: MilestoneTheme.premiumGold.withValues(alpha: 0.6),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: MilestoneTheme.darkestNight,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),

          // CENTURY COMPLETED! Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB45309), Color(0xFFD9A52A), Color(0xFFFDE047), Color(0xFFB45309)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: MilestoneTheme.premiumGold.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Text(
              'CENTURY COMPLETED!',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
                color: MilestoneTheme.darkestNight,
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Monumental Golden "100" with Outer Radiant Rings
          Stack(
            alignment: Alignment.center,
            children: [
              // Outer soft gold halo
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      MilestoneTheme.lightGold.withValues(alpha: 0.2 * _glowAnimation.value),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              ShaderMask(
                shaderCallback: (bounds) => MilestoneTheme.goldGradient.createShader(bounds),
                child: Text(
                  '100',
                  style: GoogleFonts.outfit(
                    fontSize: 104,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -4,
                    height: 1.0,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Batsman Full Name
          Text(
            m.batsmanName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          // Century Stats Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MilestoneTheme.darkEmerald.withValues(alpha: 0.7),
                  Colors.white.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: MilestoneTheme.lightGold.withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${m.runs} Runs',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: MilestoneTheme.lightGold,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: MilestoneTheme.lightGold,
                    shape: BoxShape.circle,
                  ),
                ),
                Text(
                  '${m.ballsFaced} Balls',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Team Badge & Name
          if (m.teamName.isNotEmpty)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _parseHexColor(m.teamColorHex).withValues(alpha: 0.35),
                    border: Border.all(
                      color: MilestoneTheme.lightGold,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(Icons.sports_cricket_rounded, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Text(
                  m.teamName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Color _parseHexColor(String hex) {
    try {
      final clean = hex.replaceAll('#', '').replaceAll('0x', '').replaceAll('0X', '');
      if (clean.length == 6) {
        return Color(int.parse('FF$clean', radix: 16));
      } else if (clean.length == 8) {
        return Color(int.parse(clean, radix: 16));
      }
    } catch (_) {}
    return MilestoneTheme.primaryGreen;
  }
}

// ─── MANAGER-SIDE NON-BLOCKING TOAST / BANNER ─────────────────────────────────
class MilestoneManagerToast extends StatefulWidget {
  final MilestoneCelebration milestone;
  final VoidCallback onDismiss;
  final double topOffset;

  const MilestoneManagerToast({
    super.key,
    required this.milestone,
    required this.onDismiss,
    this.topOffset = 10.0,
  });

  @override
  State<MilestoneManagerToast> createState() => _MilestoneManagerToastState();
}

class _MilestoneManagerToastState extends State<MilestoneManagerToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );

    // Slide down from top, hold, slide up
    _slideAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(0, -1.2), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 12.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<Offset>(Offset.zero),
        weight: 76.0,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1.2))
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 12.0,
      ),
    ]).animate(_controller);

    // Slight scale-up effect
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.90, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 12.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 76.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 12.0,
      ),
    ]).animate(_controller);

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 12.0),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 76.0),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 12.0),
    ]).animate(_controller);

    _controller.forward().then((_) {
      if (mounted) {
        debugPrint('[MILESTONE_MANAGER_DEBUG] Toast dismissed: eventId=${widget.milestone.eventId}');
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[MILESTONE_MANAGER_DEBUG] Toast widget rendered: ${widget.milestone.type} for ${widget.milestone.batsmanName}');
    final m = widget.milestone;
    final isCentury = m.type == '100' || m.runs >= 100;
    final achievementTitle = isCentury ? 'CENTURY COMPLETED!' : 'HALF CENTURY!';
    final scoreBallsText = '${m.runs} Runs • ${m.ballsFaced} Balls';

    return Positioned(
      top: widget.topOffset,
      left: 14,
      right: 14,
      child: SlideTransition(
        position: _slideAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Material(
              color: Colors.transparent,
              elevation: 12,
              shadowColor: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF064E3B), // Dark emerald
                      Color(0xFF078B70), // Primary emerald
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFD9A52A), // Premium gold
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFD9A52A).withValues(alpha: 0.35),
                      blurRadius: 18,
                      spreadRadius: 1,
                      offset: const Offset(0, 4),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Trophy Icon badge in gold
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFDF00), Color(0xFFD9A52A), Color(0xFFB8860B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD9A52A).withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.emoji_events_rounded,
                          color: Color(0xFF064E3B),
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Batsman & Achievement Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            achievementTitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.3,
                              color: const Color(0xFFD9A52A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            m.batsmanName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            scoreBallsText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFFFF3D4),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Dismiss close icon button
                    GestureDetector(
                      onTap: () {
                        debugPrint('[MILESTONE_MANAGER_DEBUG] Toast dismissed via tap: eventId=${widget.milestone.eventId}');
                        widget.onDismiss();
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: Colors.white70,
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
      ),
    );
  }
}
