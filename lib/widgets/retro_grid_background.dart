import 'dart:math';

import 'package:flutter/material.dart';
import '../theme/synth_theme.dart';

/// Synthwave-style animated perspective grid background.
/// Subtle retro-futuristic grid lines that scroll upward.
class RetroGridBackground extends StatefulWidget {
  final Widget child;

  const RetroGridBackground({super.key, required this.child});

  @override
  State<RetroGridBackground> createState() => _RetroGridBackgroundState();
}

class _RetroGridBackgroundState extends State<RetroGridBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
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
        return CustomPaint(
          painter: _RetroGridPainter(progress: _controller.value),
          child: widget.child,
        );
      },
    );
  }
}

class _RetroGridPainter extends CustomPainter {
  final double progress;

  _RetroGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final horizonY = size.height * 0.55;

    // Horizon glow line
    final horizonPaint = Paint()
      ..color = SynthTheme.magenta.withValues(alpha: 0.15)
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawLine(
      Offset(0, horizonY),
      Offset(size.width, horizonY),
      horizonPaint,
    );

    // Vertical lines (perspective)
    final centerX = size.width / 2;
    final verticalPaint = Paint()
      ..color = SynthTheme.purple.withValues(alpha: 0.12)
      ..strokeWidth = 1;

    for (int i = -20; i <= 20; i++) {
      if (i == 0) continue;
      final spread = i.abs() * 40.0;
      final topX = centerX + i * 8.0;
      final bottomX = centerX + spread * (i > 0 ? 1 : -1);
      canvas.drawLine(
        Offset(topX, horizonY),
        Offset(bottomX, size.height),
        verticalPaint,
      );
    }

    // Horizontal lines (scrolling)
    final offset = progress * 60.0;
    final horizontalPaint = Paint()
      ..color = SynthTheme.purple.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (int i = 0; i < 20; i++) {
      final y = horizonY + pow(i + offset / 60, 2) * 3.5;
      if (y > size.height) continue;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        horizontalPaint,
      );
    }

    // Subtle vignette
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.75,
        colors: [
          Colors.transparent,
          SynthTheme.bg.withValues(alpha: 0.6),
        ],
        stops: const [0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      vignettePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RetroGridPainter old) => true;
}
