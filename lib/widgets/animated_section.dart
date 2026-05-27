import 'package:flutter/material.dart';

/// A reusable widget that fades and slides in its child when first added
/// to the tree. Provides a subtle staggered-entry animation for panels
/// on the synth screen.
class AnimatedSection extends StatefulWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const AnimatedSection({
    super.key,
    required this.child,
    this.index = 0,
    this.delay = const Duration(milliseconds: 80),
  });

  @override
  State<AnimatedSection> createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<AnimatedSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    final staggerDelay = widget.delay * widget.index;
    Future.delayed(staggerDelay, () {
      if (mounted) _controller.forward();
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
        return FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
