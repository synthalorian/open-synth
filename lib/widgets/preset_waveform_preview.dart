import 'dart:math';

import 'package:flutter/material.dart';

import '../models/waveform.dart';
import '../theme/synth_theme.dart';

/// Tiny waveform preview for a given oscillator configuration.
/// Shows a simplified waveform shape in a small area.
class PresetWaveformPreview extends StatelessWidget {
  final Waveform waveform;
  final bool dualOsc;
  final double size;

  const PresetWaveformPreview({
    super.key,
    required this.waveform,
    this.dualOsc = false,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WaveformMiniPainter(
          waveform: waveform,
          dualOsc: dualOsc,
        ),
      ),
    );
  }
}

class _WaveformMiniPainter extends CustomPainter {
  final Waveform waveform;
  final bool dualOsc;

  _WaveformMiniPainter({required this.waveform, required this.dualOsc});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final midY = h / 2;
    final amp = h * 0.4;

    final primaryColor = SynthTheme.magenta.withValues(alpha: 0.7);
    final secondaryColor = SynthTheme.purple.withValues(alpha: 0.4);

    _drawWaveform(canvas, w, h, midY, amp, waveform, primaryColor);

    if (dualOsc) {
      _drawWaveform(canvas, w, h, midY, amp * 0.6, Waveform.sine, secondaryColor);
    }
  }

  void _drawWaveform(Canvas canvas, double w, double h, double midY, double amp, Waveform wf, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    switch (wf) {
      case Waveform.sine:
        path.moveTo(0, midY);
        for (double x = 0; x <= w; x += 0.5) {
          path.lineTo(x, midY - amp * sin((x / w) * 2 * pi));
        }
        break;

      case Waveform.saw:
        path.moveTo(0, midY + amp);
        final period = w / 2;
        for (int i = 0; i < 2; i++) {
          final startX = i * period;
          path.lineTo(startX + period, midY - amp);
          path.moveTo(startX + period, midY + amp);
        }
        break;

      case Waveform.square:
        path.moveTo(0, midY - amp);
        path.lineTo(w * 0.25, midY - amp);
        path.lineTo(w * 0.25, midY + amp);
        path.lineTo(w, midY + amp);
        break;

      case Waveform.triangle:
        path.moveTo(0, midY);
        path.lineTo(w * 0.25, midY - amp);
        path.lineTo(w * 0.75, midY + amp);
        path.lineTo(w, midY);
        break;

      case Waveform.noise:
        final rng = Random(42);
        path.moveTo(0, midY);
        for (double x = 0; x <= w; x += 2) {
          path.lineTo(x, midY + (rng.nextDouble() * 2 - 1) * amp);
        }
        break;

      case Waveform.wavetable:
        for (double x = 0; x <= w; x += 1) {
          final t = x / w;
          final sine = sin(t * 2 * pi * 1.5);
          final saw = 2 * (t * 1.5 - (t * 1.5).floor()) - 1;
          final blend = 0.5 + 0.5 * sin(t * pi * 2);
          final y = midY - amp * (blend * sine + (1 - blend) * saw * 0.5);
          if (x == 0) {
            path.moveTo(0, y);
          } else {
            path.lineTo(x, y);
          }
        }
        break;
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WaveformMiniPainter old) =>
      waveform != old.waveform || dualOsc != old.dualOsc;
}
