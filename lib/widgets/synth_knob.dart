import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/synth_theme.dart';

class SynthKnob extends StatefulWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final String Function(double)? formatValue;
  final ValueChanged<double> onChanged;
  final double size;
  final Color? activeColor;

  const SynthKnob({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.formatValue,
    this.size = 60,
    this.activeColor,
  });

  @override
  State<SynthKnob> createState() => _SynthKnobState();
}

class _SynthKnobState extends State<SynthKnob> {
  double _dragStartY = 0;
  double _dragStartValue = 0;

  String get _displayValue =>
      widget.formatValue?.call(widget.value) ??
      widget.value.toStringAsFixed(widget.value == widget.value.roundToDouble() ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    final color = widget.activeColor ?? SynthTheme.magenta;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onVerticalDragStart: (details) {
            _dragStartY = details.globalPosition.dy;
            _dragStartValue = widget.value;
          },
          onVerticalDragUpdate: (details) {
            final delta = _dragStartY - details.globalPosition.dy;
            final range = widget.max - widget.min;
            final sensitivity = range / 150; // 150px drag for full range
            final newValue =
                (_dragStartValue + delta * sensitivity).clamp(widget.min, widget.max);
            widget.onChanged(newValue);
          },
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _KnobPainter(
                value: widget.value,
                min: widget.min,
                max: widget.max,
                activeColor: color,
                displayValue: _displayValue,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.label,
          style: TextStyle(
            color: SynthTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _KnobPainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final Color activeColor;
  final String displayValue;

  _KnobPainter({
    required this.value,
    required this.min,
    required this.max,
    required this.activeColor,
    required this.displayValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Arc angles: 7 o'clock (225°) to 5 o'clock (315°) = 270° sweep
    const startAngle = 135 * pi / 180; // 7 o'clock in canvas coords
    const sweepAngle = 270 * pi / 180;
    final normalized = (value - min) / (max - min);
    final activeSweep = sweepAngle * normalized;

    // Glow behind active arc
    final glowPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.25)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      activeSweep,
      false,
      glowPaint,
    );

    // Track arc (dim)
    final trackPaint = Paint()
      ..color = SynthTheme.purple.withValues(alpha: 0.3)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Active arc
    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      activeSweep,
      false,
      activePaint,
    );

    // Indicator dot
    final dotAngle = startAngle + activeSweep;
    final dotX = center.dx + radius * cos(dotAngle);
    final dotY = center.dy + radius * sin(dotAngle);
    final dotGlow = Paint()
      ..color = activeColor.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(dotX, dotY), 5, dotGlow);
    canvas.drawCircle(
      Offset(dotX, dotY),
      3,
      Paint()..color = Colors.white,
    );

    // Center value text
    final textPainter = TextPainter(
      text: TextSpan(
        text: displayValue,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: size.width * 0.18,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_KnobPainter old) =>
      value != old.value || activeColor != old.activeColor;
}
