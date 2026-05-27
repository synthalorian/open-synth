import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/synth_providers.dart';
import '../theme/synth_theme.dart';
import '../widgets/computer_keyboard_listener.dart';
import '../widgets/crt_overlay.dart';
import '../widgets/keyboard_widget.dart';
import '../widgets/retro_grid_background.dart';

/// Full-screen performance mode optimized for live playing.
/// Minimal chrome, big controls, X/Y expression pad.
class PerformanceScreen extends ConsumerStatefulWidget {
  const PerformanceScreen({super.key});

  @override
  ConsumerState<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends ConsumerState<PerformanceScreen> {
  bool _showControls = true;

  void _toggleControls() => setState(() => _showControls = !_showControls);

  @override
  Widget build(BuildContext context) {
    final preset = ref.watch(currentPresetProvider);
    final notifier = ref.read(currentPresetProvider.notifier);

    return CrtOverlay(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RetroGridBackground(
          child: ComputerKeyboardListener(
            child: GestureDetector(
              onDoubleTap: _toggleControls,
              child: SafeArea(
                child: Column(
                  children: [
                    // ── Header ──
                    if (_showControls)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 20),
                              tooltip: 'Exit Performance Mode',
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    preset.name.toUpperCase(),
                                    style: GoogleFonts.orbitron(
                                      color: SynthTheme.magenta,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    preset.category.displayName.toUpperCase(),
                                    style: TextStyle(
                                      color: SynthTheme.textSecondary,
                                      fontSize: 10,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.layers_outlined, color: Colors.white, size: 20),
                              tooltip: 'Toggle controls',
                              onPressed: _toggleControls,
                            ),
                          ],
                        ),
                      ),

                    // ── X/Y Expression Pad ──
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _ExpressionPad(
                          cutoff: preset.filter.cutoff,
                          resonance: preset.filter.resonance,
                          onChanged: (cutoff, resonance) {
                            notifier.update(
                              (p) => p.copyWith(
                                filter: p.filter.copyWith(
                                  cutoff: cutoff,
                                  resonance: resonance,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // ── Big Master Volume ──
                    if (_showControls)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: _BigMasterVolume(
                          volume: preset.masterVolume,
                          onChanged: (v) => notifier.update(
                            (p) => p.copyWith(masterVolume: v),
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // ── Active voices indicator ──
                    if (_showControls)
                      _ActiveVoicesIndicator(),

                    const SizedBox(height: 8),

                    // ── Keyboard ──
                    const KeyboardWidget(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef ExpressionPadCallback = void Function(double cutoff, double resonance);

class _ExpressionPad extends StatefulWidget {
  final double cutoff;
  final double resonance;
  final ExpressionPadCallback onChanged;

  const _ExpressionPad({
    required this.cutoff,
    required this.resonance,
    required this.onChanged,
  });

  @override
  State<_ExpressionPad> createState() => _ExpressionPadState();
}

class _ExpressionPadState extends State<_ExpressionPad> {
  Offset? _currentPos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final cutoffX = (widget.cutoff - 20) / (20000 - 20);
        final resonanceY = 1.0 - widget.resonance; // invert so up = more resonance

        final dotX = cutoffX * width;
        final dotY = resonanceY * height;

        return GestureDetector(
          onPanStart: (details) => _updatePosition(details.localPosition, width, height),
          onPanUpdate: (details) => _updatePosition(details.localPosition, width, height),
          onPanEnd: (_) => setState(() => _currentPos = null),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0118),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: SynthTheme.cyan.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: SynthTheme.cyan.withValues(alpha: 0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                painter: _ExpressionPadPainter(
                  dotX: dotX,
                  dotY: dotY,
                  isActive: _currentPos != null,
                ),
                size: Size(width, height),
              ),
            ),
          ),
        );
      },
    );
  }

  void _updatePosition(Offset pos, double width, double height) {
    final x = pos.dx.clamp(0.0, width);
    final y = pos.dy.clamp(0.0, height);
    setState(() => _currentPos = Offset(x, y));

    final cutoff = 20.0 + (x / width) * (20000.0 - 20.0);
    final resonance = 1.0 - (y / height);
    widget.onChanged(cutoff, resonance.clamp(0.0, 1.0));
  }
}

class _ExpressionPadPainter extends CustomPainter {
  final double dotX;
  final double dotY;
  final bool isActive;

  _ExpressionPadPainter({
    required this.dotX,
    required this.dotY,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Grid lines
    final gridPaint = Paint()
      ..color = SynthTheme.purple.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (int i = 1; i < 8; i++) {
      final x = width * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
      final y = height * i / 8;
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // Crosshair at dot
    final crosshairPaint = Paint()
      ..color = SynthTheme.cyan.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(dotX, 0), Offset(dotX, height), crosshairPaint);
    canvas.drawLine(Offset(0, dotY), Offset(width, dotY), crosshairPaint);

    // Glow around dot
    final glowPaint = Paint()
      ..color = SynthTheme.cyan.withValues(alpha: isActive ? 0.3 : 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(dotX, dotY), 30, glowPaint);

    // Dot
    canvas.drawCircle(
      Offset(dotX, dotY),
      8,
      Paint()..color = Colors.white.withValues(alpha: isActive ? 1.0 : 0.8),
    );

    // Ring
    canvas.drawCircle(
      Offset(dotX, dotY),
      12,
      Paint()
        ..color = SynthTheme.cyan.withValues(alpha: isActive ? 0.6 : 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Labels
    final labelStyle = TextStyle(
      color: SynthTheme.textSecondary.withValues(alpha: 0.5),
      fontSize: 10,
    );

    _drawLabel(canvas, 'FILTER CUTOFF', width / 2, height - 16, labelStyle);
    _drawLabel(canvas, 'RESONANCE', 10, height / 2, labelStyle, rotate: true);
  }

  void _drawLabel(Canvas canvas, String text, double x, double y, TextStyle style, {bool rotate = false}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    if (rotate) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(-pi / 2);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();
    } else {
      painter.paint(canvas, Offset(x - painter.width / 2, y - painter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _ExpressionPadPainter old) =>
      dotX != old.dotX || dotY != old.dotY || isActive != old.isActive;
}

class _BigMasterVolume extends StatelessWidget {
  final double volume;
  final ValueChanged<double> onChanged;

  const _BigMasterVolume({required this.volume, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 60),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: SynthTheme.orange,
              inactiveTrackColor: SynthTheme.purple.withValues(alpha: 0.2),
              thumbColor: SynthTheme.orange,
              overlayColor: SynthTheme.orange.withValues(alpha: 0.2),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            ),
            child: Slider(
              value: volume,
              min: 0,
              max: 1,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            '${(volume * 100).round()}%',
            style: TextStyle(
              color: SynthTheme.orange,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _ActiveVoicesIndicator extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeNotes = ref.watch(playbackStateProvider);
    final voices = activeNotes.length;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: voices > 0 ? SynthTheme.cyan : SynthTheme.purple.withValues(alpha: 0.3),
            boxShadow: voices > 0
                ? [BoxShadow(color: SynthTheme.cyan.withValues(alpha: 0.6), blurRadius: 6)]
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$voices VOICES ACTIVE',
          style: TextStyle(
            color: voices > 0 ? SynthTheme.cyan : SynthTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
