import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../models/oscillator.dart';
import '../models/waveform.dart';
import '../theme/synth_theme.dart';

/// Real-time spectrum analyzer with animated frequency bars.
/// Synthesizes approximate spectral content from the current
/// oscillator settings, similar to how the oscilloscope works.
class SpectrumAnalyzer extends StatefulWidget {
  final Oscillator osc1;
  final Oscillator osc2;
  final double masterVolume;

  const SpectrumAnalyzer({
    super.key,
    required this.osc1,
    required this.osc2,
    this.masterVolume = 0.8,
  });

  @override
  State<SpectrumAnalyzer> createState() => _SpectrumAnalyzerState();
}

class _SpectrumAnalyzerState extends State<SpectrumAnalyzer> {
  Timer? _timer;
  double _phase = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (mounted) {
        setState(() {
          _phase += 0.05;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SpectrumPainter(
        phase: _phase,
        osc1: widget.osc1,
        osc2: widget.osc2,
        masterVolume: widget.masterVolume,
      ),
      size: const Size(double.infinity, 80),
    );
  }
}

class _SpectrumPainter extends CustomPainter {
  final double phase;
  final Oscillator osc1;
  final Oscillator osc2;
  final double masterVolume;

  _SpectrumPainter({
    required this.phase,
    required this.osc1,
    required this.osc2,
    required this.masterVolume,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    const barCount = 32;
    const barGap = 2.0;
    final barWidth = (width - (barCount - 1) * barGap) / barCount;

    // Background
    final bgPaint = Paint()
      ..color = const Color(0xFF0A0118)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), bgPaint);

    if (masterVolume <= 0.01) return;

    // Compute spectral energy per bin
    final energies = List<double>.filled(barCount, 0.0);

    if (osc1.enabled) {
      _addSpectrum(osc1, energies, barCount);
    }
    if (osc2.enabled) {
      _addSpectrum(osc2, energies, barCount);
    }

    // Animate with a little temporal movement
    for (int i = 0; i < barCount; i++) {
      final anim = 0.85 + 0.15 * sin(phase * 3 + i * 0.4);
      energies[i] *= anim * masterVolume;
      energies[i] = energies[i].clamp(0.0, 1.0);
    }

    for (int i = 0; i < barCount; i++) {
      final x = i * (barWidth + barGap);
      final barHeight = energies[i] * height;
      final y = height - barHeight;

      // Gradient color based on frequency
      final t = i / barCount;
      final color = Color.lerp(
        SynthTheme.cyan,
        SynthTheme.magenta,
        t,
      )!;

      // Glow bar
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawRect(
        Rect.fromLTWH(x, y - 2, barWidth, barHeight + 4),
        glowPaint,
      );

      // Main bar
      final barPaint = Paint()
        ..color = color.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(2),
      );
      canvas.drawRRect(rrect, barPaint);

      // Top highlight dot
      if (barHeight > 4) {
        final dotPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
        canvas.drawCircle(
          Offset(x + barWidth / 2, y + 2),
          1.5,
          dotPaint,
        );
      }
    }
  }

  void _addSpectrum(Oscillator osc, List<double> energies, int binCount) {
    final octaveMul = pow(2, osc.octave).toDouble();
    final baseFreq = 220.0 * octaveMul; // A3
    final detuneMul = pow(2, osc.detune / 1200).toDouble();
    final freq = baseFreq * detuneMul;

    // Map frequency to a bin
    final nyquist = 24000.0; // 48kHz / 2
    final bin = ((freq / nyquist) * binCount).floor().clamp(0, binCount - 1);

    // Waveform determines how many harmonics are strong
    switch (osc.waveform) {
      case Waveform.sine:
        energies[bin] += 0.9 * osc.volume;
        break;
      case Waveform.triangle:
        energies[bin] += 0.7 * osc.volume;
        if (bin + 2 < binCount) energies[bin + 2] += 0.15 * osc.volume;
        if (bin + 4 < binCount) energies[bin + 4] += 0.05 * osc.volume;
        break;
      case Waveform.square:
        energies[bin] += 0.6 * osc.volume;
        for (int h = 1; h <= 5; h += 2) {
          final idx = (bin * h).clamp(0, binCount - 1);
          energies[idx] += (0.5 / h) * osc.volume;
        }
        break;
      case Waveform.saw:
        energies[bin] += 0.5 * osc.volume;
        for (int h = 2; h <= 8; h++) {
          final idx = (bin * h).clamp(0, binCount - 1);
          energies[idx] += (0.4 / h) * osc.volume;
        }
        break;
      case Waveform.noise:
        for (int i = 0; i < binCount; i++) {
          energies[i] += 0.08 * osc.volume;
        }
        break;
      case Waveform.wavetable:
        energies[bin] += 0.5 * osc.volume;
        for (int h = 1; h <= 6; h++) {
          final idx = (bin * h).clamp(0, binCount - 1);
          energies[idx] += (0.4 / h) * osc.volume;
        }
        break;

      case Waveform.wtPiano:
        energies[bin] += 0.4 * osc.volume;
        for (int h = 2; h <= 12; h += 2) {
          final idx = (bin * h).clamp(0, binCount - 1);
          energies[idx] += (0.25 / h) * osc.volume;
        }
        break;

      case Waveform.wtGuitar:
      case Waveform.wtChoir:
      case Waveform.random:
        energies[bin] += 0.45 * osc.volume;
        for (int h = 2; h <= 10; h++) {
          final idx = (bin * h).clamp(0, binCount - 1);
          energies[idx] += (0.35 / h) * osc.volume;
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _SpectrumPainter old) => true;
}
