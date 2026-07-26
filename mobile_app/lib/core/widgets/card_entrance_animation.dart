// lib/core/widgets/card_entrance_animation.dart
// Staggered card entrance animation for clean lists loading

import 'package:flutter/material.dart';

class CardEntranceAnimation extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration baseDelay;

  const CardEntranceAnimation({
    super.key,
    required this.child,
    this.index = 0,
    this.baseDelay = const Duration(milliseconds: 50),
  });

  @override
  State<CardEntranceAnimation> createState() => _CardEntranceAnimationState();
}

class _CardEntranceAnimationState extends State<CardEntranceAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
      ),
    );

    _slide = Tween<double>(begin: 30.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutBack), // spring-like slide
      ),
    );

    Future.delayed(widget.baseDelay * widget.index, () {
      if (mounted) {
        _controller.forward();
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.translate(
            offset: Offset(0.0, _slide.value),
            child: widget.child,
          ),
        );
      },
    );
  }
}
