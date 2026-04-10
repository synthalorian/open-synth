import 'dart:math';
import 'package:flutter/material.dart';

class WaveformIconPainter extends CustomPainter {
  final String type; // sine, saw, square, triangle, noise
  final Color color;
  final double strokeWidth;

  WaveformIconPainter({
    required this.type,
    required this.color,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = size.width;
    final h = size.height;
    final midY = h / 2;
    final amp = h * 0.35;

    final path = Path();

    switch (type) {
      case 'sine':
        path.moveTo(0, midY);
        for (double x = 0; x <= w; x += 0.5) {
          final y = midY - amp * sin((x / w) * 2 * pi);
          path.lineTo(x, y);
        }
        break;

      case 'saw':
        final period = w / 2;
        path.moveTo(0, midY + amp);
        for (int i = 0; i < 2; i++) {
          final startX = i * period;
          path.lineTo(startX + period, midY - amp);
          path.moveTo(startX + period, midY + amp);
        }
        break;

      case 'square':
        final period = w / 2;
        path.moveTo(0, midY - amp);
        path.lineTo(period * 0.5, midY - amp);
        path.lineTo(period * 0.5, midY + amp);
        path.lineTo(period, midY + amp);
        path.lineTo(period, midY - amp);
        path.lineTo(period * 1.5, midY - amp);
        path.lineTo(period * 1.5, midY + amp);
        path.lineTo(w, midY + amp);
        break;

      case 'triangle':
        final quarter = w / 4;
        path.moveTo(0, midY);
        path.lineTo(quarter, midY - amp);
        path.lineTo(quarter * 2, midY);
        path.lineTo(quarter * 3, midY + amp);
        path.lineTo(w, midY);
        break;

      case 'noise':
        final rng = Random(42); // deterministic
        path.moveTo(0, midY);
        for (double x = 0; x <= w; x += 3) {
          path.lineTo(x, midY + (rng.nextDouble() * 2 - 1) * amp);
        }
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WaveformIconPainter oldDelegate) =>
      type != oldDelegate.type || color != oldDelegate.color;
}
