import 'package:flutter/material.dart';
import '../theme/synth_theme.dart';

class AdsrPainter extends CustomPainter {
  final double attack;
  final double decay;
  final double sustain;
  final double release;
  final int? dragIndex; // which segment is being dragged

  AdsrPainter({
    required this.attack,
    required this.decay,
    required this.sustain,
    required this.release,
    this.dragIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final padding = 4.0;
    final usableW = w - padding * 2;
    final usableH = h - padding * 2;

    // Normalize times to total
    final total = attack + decay + release + 200; // sustain hold = 200ms visual
    final aW = (attack / total) * usableW;
    final dW = (decay / total) * usableW;
    final sW = (200 / total) * usableW; // sustain visual width
    final rW = (release / total) * usableW;

    final bottom = h - padding;
    final top = padding;
    final sustainY = top + (1.0 - sustain) * usableH;

    // Background grid
    final gridPaint = Paint()
      ..color = SynthTheme.purple.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = top + (usableH / 4) * i;
      canvas.drawLine(Offset(padding, y), Offset(w - padding, y), gridPaint);
    }

    // Build the ADSR path
    final path = Path();
    var x = padding;
    path.moveTo(x, bottom);

    // Attack
    x += aW;
    path.lineTo(x, top);

    // Decay
    final decayEndX = x + dW;
    path.lineTo(decayEndX, sustainY);

    // Sustain hold
    final sustainEndX = decayEndX + sW;
    path.lineTo(sustainEndX, sustainY);

    // Release
    final releaseEndX = sustainEndX + rW;
    path.lineTo(releaseEndX, bottom);

    // Fill gradient
    final fillPath = Path.from(path)..lineTo(padding, bottom)..close();
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        SynthTheme.magenta.withValues(alpha: 0.3),
        SynthTheme.purple.withValues(alpha: 0.05),
      ],
    );
    canvas.drawPath(
      fillPath,
      Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Segment colors
    final colors = [SynthTheme.magenta, SynthTheme.orange, SynthTheme.cyan, SynthTheme.purple];
    final segmentPaints = colors
        .map((c) => Paint()
          ..color = c
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round)
        .toList();

    // Draw segments individually
    // Attack
    canvas.drawLine(Offset(padding, bottom), Offset(padding + aW, top), segmentPaints[0]);
    // Decay
    canvas.drawLine(Offset(padding + aW, top), Offset(decayEndX, sustainY), segmentPaints[1]);
    // Sustain
    canvas.drawLine(Offset(decayEndX, sustainY), Offset(sustainEndX, sustainY), segmentPaints[2]);
    // Release
    canvas.drawLine(Offset(sustainEndX, sustainY), Offset(releaseEndX, bottom), segmentPaints[3]);

    // Control points
    final points = [
      Offset(padding + aW, top),
      Offset(decayEndX, sustainY),
      Offset(sustainEndX, sustainY),
      Offset(releaseEndX, bottom),
    ];

    for (int i = 0; i < points.length; i++) {
      final isDragging = dragIndex == i;
      final dotPaint = Paint()
        ..color = isDragging ? Colors.white : colors[i]
        ..style = PaintingStyle.fill;
      final glowPaint = Paint()
        ..color = colors[i].withValues(alpha: isDragging ? 0.6 : 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(points[i], isDragging ? 8 : 5, glowPaint);
      canvas.drawCircle(points[i], isDragging ? 5 : 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(AdsrPainter oldDelegate) =>
      attack != oldDelegate.attack ||
      decay != oldDelegate.decay ||
      sustain != oldDelegate.sustain ||
      release != oldDelegate.release ||
      dragIndex != oldDelegate.dragIndex;
}
