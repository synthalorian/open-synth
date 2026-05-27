import 'package:flutter/material.dart';
import '../models/envelope.dart';
import '../painters/adsr_painter.dart';
import '../theme/synth_theme.dart';

class EnvelopeDisplay extends StatefulWidget {
  final String title;
  final Envelope envelope;
  final ValueChanged<Envelope> onChanged;
  final Color? accentColor;
  final bool isLocked;

  const EnvelopeDisplay({
    super.key,
    required this.title,
    required this.envelope,
    required this.onChanged,
    this.accentColor,
    this.isLocked = false,
  });

  @override
  State<EnvelopeDisplay> createState() => _EnvelopeDisplayState();
}

class _EnvelopeDisplayState extends State<EnvelopeDisplay> {
  int? _dragIndex;

  @override
  Widget build(BuildContext context) {
    final color = widget.accentColor ?? SynthTheme.magenta;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              if (widget.isLocked) ...[
                const SizedBox(width: 6),
                Icon(Icons.lock, color: SynthTheme.magenta, size: 12),
              ],
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 80,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onPanStart: (details) {
                    _dragIndex = _hitTest(
                      details.localPosition,
                      constraints.biggest,
                    );
                    setState(() {});
                  },
                  onPanUpdate: (details) {
                    if (_dragIndex == null) return;
                    _handleDrag(
                      _dragIndex!,
                      details.delta,
                      constraints.biggest,
                    );
                  },
                  onPanEnd: (_) {
                    setState(() => _dragIndex = null);
                  },
                  child: CustomPaint(
                    size: constraints.biggest,
                    painter: AdsrPainter(
                      attack: widget.envelope.attack,
                      decay: widget.envelope.decay,
                      sustain: widget.envelope.sustain,
                      release: widget.envelope.release,
                      dragIndex: _dragIndex,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          // Value labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ValueLabel('A', '${widget.envelope.attack.round()}ms', SynthTheme.magenta),
              _ValueLabel('D', '${widget.envelope.decay.round()}ms', SynthTheme.orange),
              _ValueLabel('S', '${(widget.envelope.sustain * 100).round()}%', SynthTheme.cyan),
              _ValueLabel('R', '${widget.envelope.release.round()}ms', SynthTheme.purple),
            ],
          ),
        ],
      ),
    );
  }

  int? _hitTest(Offset pos, Size size) {
    final w = size.width;
    final h = size.height;
    final padding = 4.0;
    final usableW = w - padding * 2;
    final usableH = h - padding * 2;
    final env = widget.envelope;
    final total = env.attack + env.decay + env.release + 200;

    final aW = (env.attack / total) * usableW;
    final dW = (env.decay / total) * usableW;
    final sW = (200 / total) * usableW;
    final rW = (env.release / total) * usableW;
    final sustainY = padding + (1.0 - env.sustain) * usableH;

    final points = [
      Offset(padding + aW, padding), // Attack peak
      Offset(padding + aW + dW, sustainY), // Decay end
      Offset(padding + aW + dW + sW, sustainY), // Sustain end
      Offset(padding + aW + dW + sW + rW, h - padding), // Release end
    ];

    for (int i = 0; i < points.length; i++) {
      if ((pos - points[i]).distance < 20) return i;
    }
    return null;
  }

  void _handleDrag(int index, Offset delta, Size size) {
    final env = widget.envelope;
    final scaleX = 5000 / size.width; // ms per pixel
    final scaleY = 1.0 / size.height;

    switch (index) {
      case 0: // Attack
        final newAttack = (env.attack + delta.dx * scaleX).clamp(0.0, 5000.0);
        widget.onChanged(env.copyWith(attack: newAttack));
        break;
      case 1: // Decay + Sustain level
        final newDecay = (env.decay + delta.dx * scaleX).clamp(0.0, 5000.0);
        final newSustain = (env.sustain - delta.dy * scaleY).clamp(0.0, 1.0);
        widget.onChanged(env.copyWith(decay: newDecay, sustain: newSustain));
        break;
      case 2: // Sustain level
        final newSustain = (env.sustain - delta.dy * scaleY).clamp(0.0, 1.0);
        widget.onChanged(env.copyWith(sustain: newSustain));
        break;
      case 3: // Release
        final newRelease = (env.release + delta.dx * scaleX).clamp(0.0, 10000.0);
        widget.onChanged(env.copyWith(release: newRelease));
        break;
    }
  }
}

class _ValueLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ValueLabel(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: SynthTheme.textSecondary,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
