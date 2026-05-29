import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/drum_providers.dart';

/// A 4×4 grid of touch-responsive drum pads.
///
/// Velocity is determined by vertical tap position — bottom of pad = hard hit,
/// top = soft hit. Each pad is color-coded by drum type with synthwave styling.
class DrumPadGrid extends ConsumerWidget {
  const DrumPadGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final padW = (constraints.maxWidth - 12) / 4; // 3 gaps of 4px
        final padH = (constraints.maxHeight - 12) / 4;
        // Clamp to reasonable bounds
        final size = padW < padH ? padW : padH;
        final clampedSize = size.clamp(48.0, 100.0);

        return Center(
          child: SizedBox(
            width: clampedSize * 4 + 12,
            height: clampedSize * 4 + 12,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                for (final pad in drumPadGrid)
                  SizedBox(
                    width: clampedSize,
                    height: clampedSize,
                    child: _DrumPad(
                      midiNote: pad.midi,
                      label: pad.label,
                      color: Color(pad.color),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DrumPad extends ConsumerStatefulWidget {
  final int midiNote;
  final String label;
  final Color color;

  const _DrumPad({
    required this.midiNote,
    required this.label,
    required this.color,
  });

  @override
  ConsumerState<_DrumPad> createState() => _DrumPadState();
}

class _DrumPadState extends ConsumerState<_DrumPad> {
  bool _pressed = false;

  double _velocityFromPosition(Offset localPosition, Size size) {
    // Bottom = 1.0, top = 0.3 (always audible, just softer at top)
    final fraction = (localPosition.dy / size.height).clamp(0.0, 1.0);
    return 1.0 - fraction * 0.7; // range: 0.3–1.0
  }

  void _onPointerDown(PointerDownEvent event) {
    setState(() => _pressed = true);
    final vel = _velocityFromPosition(event.localPosition, (context.findRenderObject() as RenderBox).size);
    triggerDrumNote(ref, widget.midiNote, vel);
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() => _pressed = false);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.color;
    final glowColor = _pressed
        ? baseColor.withValues(alpha: 0.9)
        : baseColor.withValues(alpha: 0.25);
    final borderColor = _pressed
        ? baseColor.withValues(alpha: 1.0)
        : baseColor.withValues(alpha: 0.4);

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 40),
        decoration: BoxDecoration(
          color: glowColor,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderColor, width: _pressed ? 2 : 1),
          boxShadow: _pressed
              ? [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: baseColor.withValues(alpha: 0.15),
                    blurRadius: 4,
                  ),
                ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: TextStyle(
            color: _pressed ? Colors.white : baseColor.withValues(alpha: 0.9),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}