import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/retro_theme.dart';

/// A retro LCD display widget — dot-matrix style with phosphor glow.
///
/// Shows preset names, parameter values, or status messages with
/// that classic dark-olive background and amber pixel glow.
class RetroLcd extends StatelessWidget {
  final String text;
  final double width;
  final double height;
  final bool isBlinking;

  const RetroLcd({
    super.key,
    required this.text,
    this.width = 200,
    this.height = 32,
    this.isBlinking = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: RetroTheme.lcdBg,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: RetroTheme.shadow,
          width: 2,
        ),
        boxShadow: [
          // Inner shadow — recessed display
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          children: [
            // Subtle scanline texture
            CustomPaint(
              size: Size(width, height),
              painter: _ScanlinePainter(),
            ),
            // Text content
            Center(
              child: Text(
                text.toUpperCase(),
                style: RetroTheme.lcdText.copyWith(
                  shadows: [
                    Shadow(
                      color: RetroTheme.lcdPixel.withOpacity(0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Ghost text — previous value fading
            if (isBlinking)
              Positioned.fill(
                child: Container(
                  color: RetroTheme.lcdPixel.withOpacity(0.1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.08)
      ..strokeWidth = 1;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Subtle vertical banding (CRT phosphor stripe pattern)
    final bandPaint = Paint()
      ..color = RetroTheme.lcdPixel.withOpacity(0.02)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 2) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), bandPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
