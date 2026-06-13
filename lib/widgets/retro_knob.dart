import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/retro_theme.dart';

/// A retro rotary knob widget with tick marks, LED ring, and smooth drag.
///
/// Inspired by hardware synth knobs — bakelite body, amber indicator,
/// and a ring of tick marks showing the value range.
class RetroKnob extends StatefulWidget {
  final double value; // 0.0 - 1.0
  final ValueChanged<double>? onChanged;
  final double size;
  final String? label;
  final String? valueLabel;
  final bool isActive;

  const RetroKnob({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 56,
    this.label,
    this.valueLabel,
    this.isActive = true,
  });

  @override
  State<RetroKnob> createState() => _RetroKnobState();
}

class _RetroKnobState extends State<RetroKnob> {
  double _currentValue = 0.0;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value.clamp(0.0, 1.0);
  }

  @override
  void didUpdateWidget(RetroKnob old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _currentValue = widget.value.clamp(0.0, 1.0);
    }
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (widget.onChanged == null) return;
    setState(() {
      _currentValue = (_currentValue - details.delta.dy * 0.005).clamp(0.0, 1.0);
    });
    widget.onChanged!(_currentValue);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Knob body
        GestureDetector(
          onVerticalDragUpdate: _onDragUpdate,
          child: CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _KnobPainter(
              value: _currentValue,
              isActive: widget.isActive,
            ),
          ),
        ),
        // Label
        if (widget.label != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.label!.toUpperCase(),
              style: RetroTheme.labelText.copyWith(
                color: widget.isActive
                    ? RetroTheme.textSecondary
                    : RetroTheme.textSecondary.withOpacity(0.4),
              ),
            ),
          ),
        // Value readout
        if (widget.valueLabel != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              widget.valueLabel!,
              style: RetroTheme.valueText.copyWith(
                color: widget.isActive
                    ? RetroTheme.neonYellow
                    : RetroTheme.neonYellow.withOpacity(0.3),
              ),
            ),
          ),
      ],
    );
  }
}

class _KnobPainter extends CustomPainter {
  final double value;
  final bool isActive;

  _KnobPainter({required this.value, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const tickCount = 31;
    const startAngle = -225 * math.pi / 180;
    const endAngle = 45 * math.pi / 180;
    const sweep = endAngle - startAngle;

    // ── Tick marks ─────────────────────────────────────────────────
    final tickPaint = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < tickCount; i++) {
      final t = i / (tickCount - 1);
      final angle = startAngle + sweep * t;
      final isLit = t <= value;

      final innerR = radius * 0.72;
      final outerR = radius * 0.82;

      final inner = center + Offset(math.cos(angle) * innerR, math.sin(angle) * innerR);
      final outer = center + Offset(math.cos(angle) * outerR, math.sin(angle) * outerR);

      tickPaint.color = isLit && isActive
          ? RetroTheme.neonYellow.withOpacity(0.6 + 0.4 * math.sin(t * math.pi))
          : RetroTheme.knobTicks.withOpacity(0.3);

      canvas.drawLine(inner, outer, tickPaint);
    }

    // ── Knob body (recessed) ───────────────────────────────────────
    final bodyPaint = Paint()
      ..color = RetroTheme.knobBody
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.68, bodyPaint);

    // ── Inner shadow for depth ─────────────────────────────────────
    final shadowPaint = Paint()
      ..color = RetroTheme.shadow.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.65, shadowPaint);

    // ── Knob cap ───────────────────────────────────────────────────
    final capPaint = Paint()
      ..color = RetroTheme.knobCap
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.58, capPaint);

    // ── Indicator line ─────────────────────────────────────────────
    final indicatorAngle = startAngle + sweep * value;
    final indicatorR = radius * 0.52;
    final indicatorStart = center + Offset(
      math.cos(indicatorAngle) * radius * 0.2,
      math.sin(indicatorAngle) * radius * 0.2,
    );
    final indicatorEnd = center + Offset(
      math.cos(indicatorAngle) * indicatorR,
      math.sin(indicatorAngle) * indicatorR,
    );

    final indicatorPaint = Paint()
      ..color = isActive ? RetroTheme.knobIndicator : RetroTheme.knobIndicator.withOpacity(0.3)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(indicatorStart, indicatorEnd, indicatorPaint);

    // ── Center dot ─────────────────────────────────────────────────
    final dotPaint = Paint()
      ..color = isActive
          ? RetroTheme.neonYellow.withOpacity(0.8)
          : RetroTheme.neonYellow.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.08, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _KnobPainter old) {
    return old.value != value || old.isActive != isActive;
  }
}
