import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../models/oscillator.dart';
import '../models/waveform.dart';
import '../theme/synth_theme.dart';

/// Real-time oscilloscope visualizer that synthesizes the expected
/// waveform from the current oscillator settings. Runs a local timer
/// so the display is always alive even when the native engine's audio
/// buffer isn't accessible from Dart.
class Oscilloscope extends StatefulWidget {
  final Oscillator osc1;
  final Oscillator osc2;
  final double masterVolume;

  const Oscilloscope({
    super.key,
    required this.osc1,
    required this.osc2,
    this.masterVolume = 0.8,
  });

  @override
  State<Oscilloscope> createState() => _OscilloscopeState();
}

class _OscilloscopeState extends State<Oscilloscope> {
  Timer? _timer;
  double _phase = 0;
  bool _frozen = false;
  List<Offset>? _frozenPoints;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (mounted && !_frozen) {
        setState(() {
          _phase += 0.08;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double? _frozenWidth;

  void _toggleFreeze() {
    setState(() {
      _frozen = !_frozen;
      if (_frozen) {
        // Capture current waveform points for overlay
        // Use a reference width; actual scaling happens in paint.
        const captureWidth = 800.0;
        _frozenPoints = _computeWaveformPoints(
          phase: _phase,
          osc1: widget.osc1,
          osc2: widget.osc2,
          masterVolume: widget.masterVolume,
          width: captureWidth,
          height: 80,
        );
        _frozenWidth = captureWidth;
      } else {
        _frozenPoints = null;
        _frozenWidth = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          painter: _OscilloscopePainter(
            phase: _phase,
            osc1: widget.osc1,
            osc2: widget.osc2,
            masterVolume: widget.masterVolume,
            frozenPoints: _frozenPoints,
            frozenWidth: _frozenWidth,
          ),
          size: const Size(double.infinity, 80),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: _toggleFreeze,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: _frozen
                    ? SynthTheme.cyan.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: _frozen
                      ? SynthTheme.cyan.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _frozen ? Icons.pause : Icons.pause_outlined,
                    color: _frozen ? SynthTheme.cyan : Colors.white.withValues(alpha: 0.5),
                    size: 10,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    _frozen ? 'FROZEN' : 'FREEZE',
                    style: TextStyle(
                      color: _frozen ? SynthTheme.cyan : Colors.white.withValues(alpha: 0.5),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OscilloscopePainter extends CustomPainter {
  final double phase;
  final Oscillator osc1;
  final Oscillator osc2;
  final double masterVolume;
  final List<Offset>? frozenPoints;
  final double? frozenWidth;

  _OscilloscopePainter({
    required this.phase,
    required this.osc1,
    required this.osc2,
    required this.masterVolume,
    this.frozenPoints,
    this.frozenWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2;
    final width = size.width;

    // Background fill
    final bgPaint = Paint()
      ..color = const Color(0xFF0A0118)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, width, size.height),
      bgPaint,
    );

    // Grid lines
    final gridPaint = Paint()
      ..color = SynthTheme.purple.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }
    for (int i = 0; i < 8; i++) {
      final x = width * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Center line
    final centerPaint = Paint()
      ..color = SynthTheme.purple.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, centerY), Offset(width, centerY), centerPaint);

    if (masterVolume <= 0.01 && (frozenPoints == null || frozenPoints!.isEmpty)) return;

    // Build waveform points
    final points = _computeWaveformPoints(
      phase: phase,
      osc1: osc1,
      osc2: osc2,
      masterVolume: masterVolume,
      width: width,
      height: size.height,
    );

    // Draw frozen overlay first (behind live waveform)
    if (frozenPoints != null && frozenPoints!.isNotEmpty) {
      final scaleX = size.width / (frozenWidth ?? size.width);
      final frozenPath = Path();
      frozenPath.moveTo(
        frozenPoints!.first.dx * scaleX,
        frozenPoints!.first.dy,
      );
      for (int i = 1; i < frozenPoints!.length; i++) {
        frozenPath.lineTo(
          frozenPoints![i].dx * scaleX,
          frozenPoints![i].dy,
        );
      }
      final frozenGlowPaint = Paint()
        ..color = SynthTheme.magenta.withValues(alpha: 0.12)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawPath(frozenPath, frozenGlowPaint);

      final frozenWavePaint = Paint()
        ..color = SynthTheme.magenta.withValues(alpha: 0.35)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(frozenPath, frozenWavePaint);
    }

    if (points.isEmpty) return;

    // Glow path
    final glowPaint = Paint()
      ..color = SynthTheme.cyan.withValues(alpha: 0.25)
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, glowPaint);

    // Main waveform
    final wavePaint = Paint()
      ..color = SynthTheme.cyan.withValues(alpha: 0.85)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, wavePaint);

    // Highlight dots at peaks
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    for (int i = 0; i < points.length; i += 20) {
      canvas.drawCircle(points[i], 1.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _OscilloscopePainter old) => true;
}

List<Offset> _computeWaveformPoints({
  required double phase,
  required Oscillator osc1,
  required Oscillator osc2,
  required double masterVolume,
  required double width,
  required double height,
}) {
  final points = <Offset>[];
  const samples = 200;
  const fundamental = 2 * pi * 220; // A3 ~ 220Hz
  final centerY = height / 2;

  for (int i = 0; i <= samples; i++) {
    final t = i / samples;
    final x = t * width;
    var y = centerY;

    if (osc1.enabled) {
      y += _sampleOscillatorPoints(osc1, fundamental, t * 2 * pi + phase, centerY);
    }
    if (osc2.enabled) {
      y += _sampleOscillatorPoints(osc2, fundamental, t * 2 * pi + phase, centerY);
    }

    y = centerY + (y - centerY) * masterVolume;
    y = y.clamp(2.0, height - 2);
    points.add(Offset(x, y));
  }

  return points;
}

double _sampleOscillatorPoints(
  Oscillator osc,
  double freq,
  double time,
  double amplitude,
) {
  final octaveMultiplier = pow(2, osc.octave).toDouble();
  final detuneMultiplier = pow(2, osc.detune / 1200).toDouble();
  final f = freq * octaveMultiplier * detuneMultiplier;
  final amp = amplitude * 0.35 * osc.volume;

  switch (osc.waveform) {
    case Waveform.sine:
      return amp * sin(f * time);
    case Waveform.saw:
      return amp * (2 * ((f * time / (2 * pi)) % 1) - 1);
    case Waveform.square:
      final pw = osc.pulseWidth.clamp(0.05, 0.95);
      return amp * (((f * time / (2 * pi)) % 1) < pw ? 1 : -1);
    case Waveform.triangle:
      final saw = 2 * ((f * time / (2 * pi)) % 1) - 1;
      return amp * (2 * saw.abs() - 1) * (saw >= 0 ? 1 : -1);
    case Waveform.noise:
      return amp * (sin(f * time * 17.3) * cos(f * time * 23.1));
    case Waveform.wavetable:
      // Wavetable: morph between sine, saw, and square based on position
      final wt = osc.wavetablePosition.clamp(0.0, 1.0);
      final sine = sin(f * time);
      final saw = 2 * ((f * time / (2 * pi)) % 1) - 1;
      final sq = saw >= 0 ? 1.0 : -1.0;
      return amp * ((1 - wt) * sine + wt * ((1 - wt) * saw + wt * sq));
  }
}
