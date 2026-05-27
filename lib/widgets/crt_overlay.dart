import 'package:flutter/material.dart';

/// Subtle CRT scanline and vignette overlay for that authentic
/// 1984 monitor look. Purely decorative — uses a Stack-friendly
/// [IgnorePointer] so it never blocks touches underneath.
class CrtOverlay extends StatelessWidget {
  final Widget child;
  final double scanlineOpacity;
  final bool enabled;

  const CrtOverlay({
    super.key,
    required this.child,
    this.scanlineOpacity = 0.06,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        IgnorePointer(
          child: CustomPaint(
            painter: _CrtPainter(scanlineOpacity: scanlineOpacity),
            size: Size.infinite,
          ),
        ),
      ],
    );
  }
}

class _CrtPainter extends CustomPainter {
  final double scanlineOpacity;

  _CrtPainter({required this.scanlineOpacity});

  @override
  void paint(Canvas canvas, Size size) {
    // Scanlines
    final linePaint = Paint()
      ..color = Colors.black.withValues(alpha: scanlineOpacity);
    const lineHeight = 3.0;
    const gapHeight = 1.0;

    for (double y = 0; y < size.height; y += lineHeight + gapHeight) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, gapHeight),
        linePaint,
      );
    }

    // Vignette
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: 0.25),
        ],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      vignettePaint,
    );

    // Subtle horizontal curvature band (top & bottom)
    final curvePaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height * 0.04),
      curvePaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, size.height * 0.96, size.width, size.height * 0.04),
      curvePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CrtPainter old) => false;
}
