// lib/core/widgets/app_logo.dart
// Reusable logo widget — falls back gracefully if asset missing

import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool withGlow;

  const AppLogo({super.key, this.size = 40, this.withGlow = false});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.22);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: withGlow
            ? [
                BoxShadow(
                  color: const Color(0xFF028A6B).withValues(alpha: 0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          'assets/images/logo.jpg',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: const LinearGradient(
                colors: [Color(0xFF028A6B), Color(0xFF10B981)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Icon(
              Icons.sports_cricket,
              color: Colors.white,
              size: size * 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
