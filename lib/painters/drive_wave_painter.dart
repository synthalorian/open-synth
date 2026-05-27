import 'dart:math';

import 'package:flutter/material.dart';
import '../models/fx_config.dart';

/// Hyperbolic tangent — not available in dart:math.
double _tanh(double x) {
  final e2x = exp(2 * x);
  return (e2x - 1) / (e2x + 1);
}

/// Paints a visualization of the distortion curve for a given drive type.
/// Shows how a sine wave gets shaped by the distortion algorithm.
class DriveWavePainter extends CustomPainter {
  final DriveType driveType;
  final double amount;
  final bool enabled;
  final Color activeColor;

  DriveWavePainter({
    required this.driveType,
    required this.amount,
    required this.enabled,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h / 2;
    final amp = h * 0.35;
    final color = enabled ? activeColor : activeColor.withValues(alpha: 0.2);
    final effectiveAmount = enabled ? amount : 0.0;

    // Draw input wave (faint)
    final inputPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final inputPath = Path();
    inputPath.moveTo(0, midY);
    for (double x = 0; x <= w; x += 1) {
      final t = x / w;
      final y = midY - amp * 0.7 * sin(t * 4 * pi);
      inputPath.lineTo(x, y);
    }
    canvas.drawPath(inputPath, inputPaint);

    // Draw distorted output wave
    final outputPaint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final outputPath = Path();
    outputPath.moveTo(0, midY);

    for (double x = 0; x <= w; x += 1) {
      final t = x / w;
      final input = sin(t * 4 * pi);
      double output;

      switch (driveType) {
        case DriveType.overdrive:
          // Soft clipping with tanh
          final drive = 1.0 + effectiveAmount * 8.0;
          output = _tanh(input * drive) / _tanh(drive);
          break;

        case DriveType.fuzz:
          // Hard square-ish clipping
          final threshold = 1.0 - effectiveAmount * 0.8;
          if (input > threshold) {
            output = 1.0;
          } else if (input < -threshold) {
            output = -1.0;
          } else {
            output = input / threshold * 0.5;
          }
          break;

        case DriveType.tube:
          // Asymmetric tube-style clipping
          final drive = 1.0 + effectiveAmount * 6.0;
          final sign = input >= 0 ? 1.0 : -1.0;
          final abs = input.abs();
          output = sign * (1.0 - exp(-abs * drive)) / (1.0 - exp(-drive));
          break;

        case DriveType.hardClip:
          // Hard clipping at threshold
          final threshold = 1.0 - effectiveAmount * 0.7;
          output = input.clamp(-threshold, threshold) / threshold;
          break;

        case DriveType.bitCrusher:
          // Bit crushing / quantization
          final bits = (2 + (1.0 - effectiveAmount) * 6).round();
          final levels = pow(2, bits).toDouble();
          output = (input * levels).round() / levels;
          break;
      }

      final y = midY - amp * 0.7 * output.clamp(-1.0, 1.0);
      outputPath.lineTo(x, y);
    }

    canvas.drawPath(outputPath, outputPaint);

    // Reference lines
    final refPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 0.5;
    canvas.drawLine(Offset(0, midY), Offset(w, midY), refPaint);
    canvas.drawLine(Offset(0, midY - amp * 0.7), Offset(w, midY - amp * 0.7), refPaint);
    canvas.drawLine(Offset(0, midY + amp * 0.7), Offset(w, midY + amp * 0.7), refPaint);
  }

  @override
  bool shouldRepaint(covariant DriveWavePainter old) =>
      driveType != old.driveType ||
      amount != old.amount ||
      enabled != old.enabled ||
      activeColor != old.activeColor;
}
