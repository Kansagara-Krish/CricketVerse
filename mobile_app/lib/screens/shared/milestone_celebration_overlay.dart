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
  static const Color wicketRed    = Color(0xFFDC2626);
  static const Color deepRed      = Color(0xFF7F1D1D);
  static const Color darkRedNight = Color(0xFF2B0B0B);
  static const Color white        = Colors.white;

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFFBEB), Color(0xFFFDE047), Color(0xFFD9A52A), Color(0xFFB45309)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient wicketGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626), Color(0xFF991B1B), Color(0xFF7F1D1D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF064E3B), Color(0xFF022C22), Color(0xFF011A14)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
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

// ─── Fireworks Particle Model & Painter (Century & Win) ───────────────────────
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

// ─── USER-SIDE CELEBRATION OVERLAY (ALL 6 TYPES) ──────────────────────────────
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
  late AnimationController _stumpsAnimController;

  late AnimationController _particleController;
  final List<_ConfettiParticle> _confetti = [];
  final List<_FireworkParticle> _fireworks = [];
  final math.Random _random = math.Random();

  late String _type;
  bool _isCentury = false;
  bool _isMatchWon = false;
  bool _isWicket = false;
  bool _isSix = false;
  bool _isFiveWicket = false;

  @override
  void initState() {
    super.initState();
    _type = widget.milestone.type.trim().toUpperCase();
    _isCentury = _type == '100' || widget.milestone.runs >= 100;
    _isMatchWon = _type == 'MATCH_WON' || _type == 'MATCH_WIN';
    _isWicket = _type == 'WICKET';
    _isSix = _type == 'SIX';
    _isFiveWicket = _type == 'FIVE_WICKET' || _type == '5W';

    final int totalDurationMs;
    if (_isMatchWon) {
      totalDurationMs = 5500;
    } else if (_isCentury) {
      totalDurationMs = 4800;
    } else if (_isFiveWicket) {
      totalDurationMs = 3600;
    } else if (_isWicket) {
      totalDurationMs = 2800;
    } else if (_isSix) {
      totalDurationMs = 1800;
    } else {
      totalDurationMs = 2800; // 50 runs
    }

    _mainAnimController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalDurationMs),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.1, end: (_isCentury || _isMatchWon) ? 1.15 : 1.08)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 22.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: (_isCentury || _isMatchWon) ? 1.15 : 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 48.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.88)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 15.0,
      ),
    ]).animate(_mainAnimController);

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

    _glowAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.4, end: 1.0), weight: 50.0),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.4), weight: 50.0),
    ]).animate(CurvedAnimation(parent: _mainAnimController, curve: Curves.easeInOut));

    _stumpsAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (_isWicket) {
      _stumpsAnimController.forward();
    }

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
    final colors = _isWicket
        ? [
            MilestoneTheme.wicketRed,
            MilestoneTheme.lightGold,
            Colors.white,
            const Color(0xFFEF4444),
            MilestoneTheme.premiumGold,
          ]
        : [
            MilestoneTheme.premiumGold,
            MilestoneTheme.lightGold,
            MilestoneTheme.accentGold,
            MilestoneTheme.primaryGreen,
            Colors.white,
          ];

    final count = (_isCentury || _isMatchWon) ? 100 : (_isSix ? 35 : 60);
    for (int i = 0; i < count; i++) {
      _confetti.add(_ConfettiParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble() * 0.4 - 0.4,
        vx: (_random.nextDouble() - 0.5) * 0.007,
        vy: 0.004 + _random.nextDouble() * 0.009,
        size: 5.0 + _random.nextDouble() * (_isCentury ? 8.0 : 5.0),
        color: colors[_random.nextInt(colors.length)],
        rotation: _random.nextDouble() * math.pi * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 0.12,
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
    for (int i = 0; i < 30; i++) {
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 2.0 + _random.nextDouble() * 5.5;
      _fireworks.add(_FireworkParticle(
        x: cx,
        y: cy,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        alpha: 1.0,
        size: 2.2 + _random.nextDouble() * 2.8,
        color: colors[_random.nextInt(colors.length)],
      ));
    }
  }

  int _tickCount = 0;
  void _updateParticles() {
    _tickCount++;
    for (final p in _confetti) {
      p.y += p.vy;
      p.x += p.vx + math.sin(p.wobble) * 0.0015;
      p.rotation += p.rotationSpeed;
      p.wobble += 0.05;

      if (p.y > 1.1 && _mainAnimController.value < 0.75) {
        p.y = -0.1;
        p.x = _random.nextDouble();
      }
    }

    if (_isCentury || _isMatchWon) {
      if (_tickCount % 20 == 0 && _mainAnimController.value < 0.72) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final size = renderBox.size;
          _triggerFireworkBurst(
            size.width * (0.15 + _random.nextDouble() * 0.70),
            size.height * (0.12 + _random.nextDouble() * 0.48),
          );
        }
      }

      for (int i = _fireworks.length - 1; i >= 0; i--) {
        final f = _fireworks[i];
        f.x += f.vx;
        f.y += f.vy;
        f.vy += 0.11;
        f.alpha -= 0.025;
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
    _stumpsAnimController.dispose();
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
                // 1. Dynamic Backdrop Gradient
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.1),
                        radius: 1.25,
                        colors: _isWicket
                            ? [
                                MilestoneTheme.deepRed.withValues(alpha: 0.95),
                                MilestoneTheme.darkRedNight.withValues(alpha: 0.96),
                                Colors.black.withValues(alpha: 0.98),
                              ]
                            : [
                                MilestoneTheme.darkEmerald.withValues(alpha: 0.94),
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
                  if (_isCentury || _isMatchWon)
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
                    child: _buildCelebrationCard(context),
                  ),
                ),

                // 4. Tap anywhere to skip pill
                Positioned(
                  bottom: media.padding.bottom + 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: (_isWicket ? Colors.redAccent : MilestoneTheme.premiumGold).withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app_rounded,
                            size: 14,
                            color: MilestoneTheme.lightGold.withValues(alpha: 0.85),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tap anywhere to skip',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
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

  Widget _buildCelebrationCard(BuildContext context) {
    if (_isMatchWon) return _buildMatchWinningCelebrationCard(context);
    if (_isCentury) return _buildCenturyCelebrationCard(context);
    if (_isWicket) return _buildWicketCelebrationCard(context);
    if (_isSix) return _buildSixCelebrationCard(context);
    if (_isFiveWicket) return _buildFiveWicketCelebrationCard(context);
    return _buildHalfCenturyCelebrationCard(context);
  }

  // ─── A. HALF-CENTURY CARD ───────────────────────────────────────────────────
  Widget _buildHalfCenturyCelebrationCard(BuildContext context) {
    final m = widget.milestone;

    return Container(
      width: math.min(MediaQuery.of(context).size.width * 0.88, 380),
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
      decoration: BoxDecoration(
        color: MilestoneTheme.deepEmerald.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: MilestoneTheme.premiumGold.withValues(alpha: 0.85),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: MilestoneTheme.premiumGold.withValues(alpha: 0.3 * _glowAnimation.value),
            blurRadius: 36,
            spreadRadius: 6,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MilestoneTheme.premiumGold.withValues(alpha: 0.3),
                  MilestoneTheme.primaryGreen.withValues(alpha: 0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: MilestoneTheme.lightGold.withValues(alpha: 0.7),
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
          const SizedBox(height: 16),

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
          const SizedBox(height: 10),

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

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
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
                  decoration: const BoxDecoration(color: Colors.white54, shape: BoxShape.circle),
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
          const SizedBox(height: 12),

          Text(
            'A brilliant innings!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (m.teamName.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              m.teamName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white60,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── B. CENTURY CARD ────────────────────────────────────────────────────────
  Widget _buildCenturyCelebrationCard(BuildContext context) {
    final m = widget.milestone;

    return Container(
      width: math.min(MediaQuery.of(context).size.width * 0.92, 420),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: MilestoneTheme.darkestNight.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: MilestoneTheme.lightGold,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: MilestoneTheme.lightGold.withValues(alpha: 0.38 * _glowAnimation.value),
            blurRadius: 48,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: MilestoneTheme.goldGradient,
              boxShadow: [
                BoxShadow(
                  color: MilestoneTheme.premiumGold.withValues(alpha: 0.6),
                  blurRadius: 18,
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: MilestoneTheme.darkestNight,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB45309), Color(0xFFD9A52A), Color(0xFFFDE047), Color(0xFFB45309)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              'CENTURY COMPLETED!',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
                color: MilestoneTheme.darkestNight,
              ),
            ),
          ),
          const SizedBox(height: 16),

          ShaderMask(
            shaderCallback: (bounds) => MilestoneTheme.goldGradient.createShader(bounds),
            child: Text(
              '100',
              style: GoogleFonts.outfit(
                fontSize: 98,
                fontWeight: FontWeight.w900,
                letterSpacing: -4,
                height: 1.0,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            m.batsmanName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),

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
          const SizedBox(height: 12),

          Text(
            'A magnificent hundred!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ─── C. WICKET CELEBRATION CARD ─────────────────────────────────────────────
  Widget _buildWicketCelebrationCard(BuildContext context) {
    final m = widget.milestone;

    return Container(
      width: math.min(MediaQuery.of(context).size.width * 0.90, 400),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
      decoration: BoxDecoration(
        color: MilestoneTheme.darkRedNight.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: MilestoneTheme.wicketRed,
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: MilestoneTheme.wicketRed.withValues(alpha: 0.4 * _glowAnimation.value),
            blurRadius: 42,
            spreadRadius: 6,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Cricket Stumps with Flying Bails
          _buildAnimatedStumps(),
          const SizedBox(height: 14),

          // WICKET! WHAT A DELIVERY! Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
            decoration: BoxDecoration(
              gradient: MilestoneTheme.wicketGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: MilestoneTheme.wicketRed.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Text(
              'WICKET! WHAT A DELIVERY!',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Dismissed Batter Name
          Text(
            m.batsmanName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),

          // Dismissal Type & Bowler info
          if (m.dismissalType.isNotEmpty || m.bowlerName.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                m.bowlerName.isNotEmpty && !['Run Out', 'Retired Out', 'Retired Hurt'].contains(m.dismissalType)
                    ? '${m.dismissalType} b ${m.bowlerName}'
                    : (m.dismissalType.isNotEmpty ? m.dismissalType : 'Out'),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: MilestoneTheme.lightGold,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Batter stats pill: Runs (Balls)
          Text(
            '${m.runs} runs (${m.ballsFaced} balls)',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),

          if (m.teamRuns > 0 || m.teamWickets > 0) ...[
            const SizedBox(height: 10),
            Text(
              'Score: ${m.teamRuns}/${m.teamWickets}',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAnimatedStumps() {
    return AnimatedBuilder(
      animation: _stumpsAnimController,
      builder: (context, child) {
        final progress = _stumpsAnimController.value;
        final bailOffsetLeft = Offset(-progress * 25.0, -progress * 22.0 + progress * progress * 15.0);
        final bailOffsetRight = Offset(progress * 25.0, -progress * 24.0 + progress * progress * 16.0);
        final bailRotLeft = -progress * 1.8;
        final bailRotRight = progress * 2.1;

        return SizedBox(
          width: 90,
          height: 65,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // 3 Vertical Stumps
              Positioned(
                bottom: 0,
                left: 18,
                child: _buildStump(),
              ),
              Positioned(
                bottom: 0,
                left: 42,
                child: _buildStump(),
              ),
              Positioned(
                bottom: 0,
                left: 66,
                child: _buildStump(),
              ),

              // Left Flying Bail
              Positioned(
                bottom: 45,
                left: 18,
                child: Transform.translate(
                  offset: bailOffsetLeft,
                  child: Transform.rotate(
                    angle: bailRotLeft,
                    child: _buildBail(),
                  ),
                ),
              ),

              // Right Flying Bail
              Positioned(
                bottom: 45,
                left: 44,
                child: Transform.translate(
                  offset: bailOffsetRight,
                  child: Transform.rotate(
                    angle: bailRotRight,
                    child: _buildBail(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStump() {
    return Container(
      width: 7,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFDE047), Color(0xFFD97706), Color(0xFF78350F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildBail() {
    return Container(
      width: 26,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFFFDE047),
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withValues(alpha: 0.6),
            blurRadius: 6,
          ),
        ],
      ),
    );
  }

  // ─── D. SIX CELEBRATION CARD ────────────────────────────────────────────────
  Widget _buildSixCelebrationCard(BuildContext context) {
    final m = widget.milestone;

    return Container(
      width: math.min(MediaQuery.of(context).size.width * 0.85, 360),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      decoration: BoxDecoration(
        color: MilestoneTheme.deepEmerald.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: MilestoneTheme.lightGold,
          width: 2.2,
        ),
        boxShadow: [
          BoxShadow(
            color: MilestoneTheme.lightGold.withValues(alpha: 0.45 * _glowAnimation.value),
            blurRadius: 40,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated cricket ball icon with glow
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFDC2626),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withValues(alpha: 0.6),
                  blurRadius: 18,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_baseball_rounded,
              color: Colors.white,
              size: 34,
            ),
          ),
          const SizedBox(height: 14),

          // Monumental "SIX!"
          ShaderMask(
            shaderCallback: (bounds) => MilestoneTheme.goldGradient.createShader(bounds),
            child: Text(
              'SIX!',
              style: GoogleFonts.outfit(
                fontSize: 76,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                height: 1.0,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: MilestoneTheme.premiumGold.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: MilestoneTheme.lightGold.withValues(alpha: 0.6)),
            ),
            child: Text(
              'OUT OF THE PARK!',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.0,
                color: MilestoneTheme.lightGold,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Text(
            m.batsmanName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (m.bowlerName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Bowler: ${m.bowlerName}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── E. FIVE-WICKET HAUL CARD ───────────────────────────────────────────────
  Widget _buildFiveWicketCelebrationCard(BuildContext context) {
    final m = widget.milestone;

    return Container(
      width: math.min(MediaQuery.of(context).size.width * 0.90, 410),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: MilestoneTheme.darkestNight.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: MilestoneTheme.lightGold,
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: MilestoneTheme.premiumGold.withValues(alpha: 0.35 * _glowAnimation.value),
            blurRadius: 44,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.75),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row of 5 Wickets Icons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              5,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 5),
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: MilestoneTheme.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: MilestoneTheme.premiumGold.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.sports_cricket_rounded,
                  color: MilestoneTheme.darkestNight,
                  size: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // FIVE-FOR! Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB45309), Color(0xFFD9A52A), Color(0xFFFDE047), Color(0xFFB45309)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              'FIVE-FOR!',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.5,
                color: MilestoneTheme.darkestNight,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Bowler Name
          Text(
            m.bowlerName.isNotEmpty ? m.bowlerName : m.batsmanName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),

          // Bowling figures pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MilestoneTheme.lightGold.withValues(alpha: 0.4)),
            ),
            child: Text(
              m.bowlerWickets > 0
                  ? '${m.bowlerWickets} Wickets • ${m.bowlerRunsConceded} Runs'
                  : '5 Wickets',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: MilestoneTheme.lightGold,
              ),
            ),
          ),
          const SizedBox(height: 10),

          Text(
            'A phenomenal bowling performance!',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ─── F. MATCH-WINNING CELEBRATION CARD ──────────────────────────────────────
  Widget _buildMatchWinningCelebrationCard(BuildContext context) {
    final m = widget.milestone;

    return Container(
      width: math.min(MediaQuery.of(context).size.width * 0.92, 430),
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
      decoration: BoxDecoration(
        color: MilestoneTheme.darkestNight.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: MilestoneTheme.lightGold,
          width: 3.0,
        ),
        boxShadow: [
          BoxShadow(
            color: MilestoneTheme.lightGold.withValues(alpha: 0.45 * _glowAnimation.value),
            blurRadius: 54,
            spreadRadius: 12,
          ),
          BoxShadow(
            color: MilestoneTheme.primaryGreen.withValues(alpha: 0.4),
            blurRadius: 36,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.85),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grand Trophy Icon with Halo
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: MilestoneTheme.goldGradient,
              boxShadow: [
                BoxShadow(
                  color: MilestoneTheme.lightGold.withValues(alpha: 0.7),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events_rounded,
              color: MilestoneTheme.darkestNight,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),

          // CHAMPIONS! WHAT A VICTORY!
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 9),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFB45309), Color(0xFFD9A52A), Color(0xFFFDE047), Color(0xFFB45309)],
              ),
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: MilestoneTheme.premiumGold.withValues(alpha: 0.5),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Text(
              'CHAMPIONS!',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
                color: MilestoneTheme.darkestNight,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Winning Team Name
          Text(
            m.winnerTeamName.isNotEmpty ? m.winnerTeamName : (m.teamName.isNotEmpty ? m.teamName : 'Victory'),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'WHAT A VICTORY!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: MilestoneTheme.lightGold,
            ),
          ),
          const SizedBox(height: 14),

          // Match Result Text
          if (m.resultText.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Text(
                m.resultText,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── MANAGER-SIDE NON-BLOCKING TOAST (ALL 6 TYPES) ────────────────────────────
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
      duration: const Duration(milliseconds: 3200),
    );

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

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.90, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 12.0,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 76.0),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.95).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 12.0,
      ),
    ]).animate(_controller);

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 12.0),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 76.0),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 12.0),
    ]).animate(_controller);

    _controller.forward().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.milestone;
    final type = m.type.trim().toUpperCase();

    final String title;
    final String subtitle;
    final String detail;
    final IconData icon;
    final List<Color> bgColors;
    final Color borderColor;

    if (type == 'MATCH_WON' || type == 'MATCH_WIN') {
      title = 'CHAMPIONS!';
      subtitle = m.winnerTeamName.isNotEmpty ? m.winnerTeamName : 'Match Concluded';
      detail = m.resultText.isNotEmpty ? m.resultText : 'Official Result Confirmed';
      icon = Icons.emoji_events_rounded;
      bgColors = const [Color(0xFFB45309), Color(0xFF064E3B)];
      borderColor = const Color(0xFFFDE047);
    } else if (type == '100') {
      title = 'CENTURY COMPLETED!';
      subtitle = m.batsmanName;
      detail = '${m.runs} Runs • ${m.ballsFaced} Balls';
      icon = Icons.emoji_events_rounded;
      bgColors = const [Color(0xFF064E3B), Color(0xFF078B70)];
      borderColor = const Color(0xFFD9A52A);
    } else if (type == 'WICKET') {
      title = 'WICKET!';
      subtitle = m.batsmanName;
      detail = m.bowlerName.isNotEmpty && !['Run Out', 'Retired Out'].contains(m.dismissalType)
          ? '${m.dismissalType} b ${m.bowlerName}'
          : (m.dismissalType.isNotEmpty ? m.dismissalType : 'Dismissed');
      icon = Icons.sports_cricket_rounded;
      bgColors = const [Color(0xFF7F1D1D), Color(0xFF991B1B)];
      borderColor = const Color(0xFFEF4444);
    } else if (type == 'SIX') {
      title = 'MASSIVE SIX!';
      subtitle = m.batsmanName;
      detail = m.bowlerName.isNotEmpty ? 'vs ${m.bowlerName}' : '6 Runs Boundary';
      icon = Icons.sports_baseball_rounded;
      bgColors = const [Color(0xFF064E3B), Color(0xFF078B70)];
      borderColor = const Color(0xFFFDE047);
    } else if (type == 'FIVE_WICKET' || type == '5W') {
      title = 'FIVE-WICKET HAUL!';
      subtitle = m.bowlerName.isNotEmpty ? m.bowlerName : m.batsmanName;
      detail = m.bowlerWickets > 0 ? '${m.bowlerWickets} Wickets (${m.bowlerRunsConceded} Runs)' : '5-Wicket Haul';
      icon = Icons.star_rounded;
      bgColors = const [Color(0xFFB45309), Color(0xFF064E3B)];
      borderColor = const Color(0xFFD9A52A);
    } else {
      // 50 runs
      title = 'HALF CENTURY!';
      subtitle = m.batsmanName;
      detail = '${m.runs} Runs • ${m.ballsFaced} Balls';
      icon = Icons.emoji_events_rounded;
      bgColors = const [Color(0xFF064E3B), Color(0xFF078B70)];
      borderColor = const Color(0xFFD9A52A);
    }

    // Manager toast only intercepts taps on itself; underlying scoring buttons remain 100% active!
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
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: bgColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 2.0),
                  boxShadow: [
                    BoxShadow(
                      color: borderColor.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: MilestoneTheme.goldGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: borderColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: MilestoneTheme.darkestNight,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              color: borderColor,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFFFF3D4),
                            ),
                          ),
                        ],
                      ),
                    ),

                    GestureDetector(
                      onTap: widget.onDismiss,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
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
