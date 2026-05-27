import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/mod_matrix.dart';
import '../providers/mod_matrix_provider.dart';
import '../providers/randomize_lock_provider.dart';
import '../theme/synth_theme.dart';

class ModMatrixPanel extends ConsumerWidget {
  const ModMatrixPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matrix = ref.watch(modMatrixProvider);
    final isLocked = ref.watch(randomizeLockProvider).contains(LockableParam.modMatrix);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SynthTheme.purple.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_fix_high,
                color: SynthTheme.purple,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'MOD MATRIX',
                style: TextStyle(
                  color: SynthTheme.purple,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              if (isLocked) ...[
                const SizedBox(width: 6),
                Icon(Icons.lock, color: SynthTheme.magenta, size: 12),
              ],
              const Spacer(),
              // Learn mode indicator
              Consumer(builder: (context, ref, _) {
                final learnSlot = ref.watch(modMatrixLearnModeProvider);
                if (learnSlot < 0) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    'LEARN: Slot ${learnSlot + 1}',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
              Text(
                '${matrix.slots.where((s) => s.enabled).length} active',
                style: TextStyle(
                  color: SynthTheme.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Slot rows
          ...List.generate(matrix.slots.length, (index) {
            final slot = matrix.slots[index];
            return _SlotRow(
              index: index,
              slot: slot,
            );
          }),
        ],
      ),
    );
  }
}

class _SlotRow extends ConsumerWidget {
  final int index;
  final ModMatrixSlot slot;

  const _SlotRow({required this.index, required this.slot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLearnMode = ref.watch(modMatrixLearnModeProvider) == index;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: slot.enabled
              ? SynthTheme.purple.withValues(alpha: 0.08)
              : SynthTheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isLearnMode
                ? Colors.amber.withValues(alpha: 0.5)
                : slot.enabled
                    ? SynthTheme.purple.withValues(alpha: 0.3)
                    : SynthTheme.purple.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            // Enable toggle
            GestureDetector(
              onTap: () => ref.read(modMatrixProvider.notifier).toggleSlot(index),
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: slot.enabled
                      ? SynthTheme.purple
                      : SynthTheme.purple.withValues(alpha: 0.2),
                  boxShadow: slot.enabled
                      ? [BoxShadow(color: SynthTheme.purple.withValues(alpha: 0.5), blurRadius: 4)]
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Source dropdown
            Expanded(
              flex: 2,
              child: _Dropdown<ModSource>(
                value: slot.source,
                items: ModSource.values,
                displayName: (s) => s.displayName,
                onChanged: slot.enabled
                    ? (v) => ref.read(modMatrixProvider.notifier).setSlotSource(index, v!)
                    : null,
              ),
            ),
            const SizedBox(width: 6),

            // Arrow
            Icon(
              Icons.arrow_forward,
              color: SynthTheme.textSecondary.withValues(alpha: 0.4),
              size: 12,
            ),
            const SizedBox(width: 6),

            // Destination dropdown
            Expanded(
              flex: 2,
              child: _Dropdown<ModDestination>(
                value: slot.destination,
                items: ModDestination.values,
                displayName: (d) => d.displayName,
                onChanged: slot.enabled
                    ? (v) => ref.read(modMatrixProvider.notifier).setSlotDestination(index, v!)
                    : null,
              ),
            ),
            const SizedBox(width: 8),

            // Amount knob (compact)
            SizedBox(
              width: 40,
              height: 40,
              child: _CompactKnob(
                value: slot.amount,
                onChanged: slot.enabled
                    ? (v) => ref.read(modMatrixProvider.notifier).setSlotAmount(index, v)
                    : null,
                activeColor: SynthTheme.purple,
              ),
            ),
            const SizedBox(width: 4),

            // Amount value
            SizedBox(
              width: 32,
              child: Text(
                '${(slot.amount * 100).round()}%',
                style: TextStyle(
                  color: slot.enabled ? SynthTheme.purple : SynthTheme.textSecondary.withValues(alpha: 0.4),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // Learn button
            GestureDetector(
              onTap: () {
                final currentLearn = ref.read(modMatrixLearnModeProvider);
                ref.read(modMatrixLearnModeProvider.notifier).state =
                    currentLearn == index ? -1 : index;
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLearnMode
                      ? Colors.amber.withValues(alpha: 0.2)
                      : Colors.transparent,
                  border: Border.all(
                    color: isLearnMode
                        ? Colors.amber
                        : SynthTheme.textSecondary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'L',
                  style: TextStyle(
                    color: isLearnMode
                        ? Colors.amber
                        : SynthTheme.textSecondary.withValues(alpha: 0.4),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Clear
            GestureDetector(
              onTap: () => ref.read(modMatrixProvider.notifier).clearSlot(index),
              child: Icon(
                Icons.close,
                color: SynthTheme.textSecondary.withValues(alpha: 0.3),
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<T> items;
  final String Function(T) displayName;
  final ValueChanged<T?>? onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.displayName,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: SynthTheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: onChanged != null
              ? SynthTheme.purple.withValues(alpha: 0.2)
              : SynthTheme.purple.withValues(alpha: 0.08),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          dropdownColor: SynthTheme.card,
          style: TextStyle(
            color: onChanged != null
                ? Colors.white.withValues(alpha: 0.85)
                : SynthTheme.textSecondary.withValues(alpha: 0.4),
            fontSize: 10,
          ),
          icon: Icon(
            Icons.arrow_drop_down,
            color: onChanged != null
                ? SynthTheme.purple.withValues(alpha: 0.5)
                : SynthTheme.textSecondary.withValues(alpha: 0.2),
            size: 16,
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                displayName(item),
                style: const TextStyle(fontSize: 10),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CompactKnob extends StatefulWidget {
  final double value;
  final ValueChanged<double>? onChanged;
  final Color activeColor;

  const _CompactKnob({
    required this.value,
    this.onChanged,
    required this.activeColor,
  });

  @override
  State<_CompactKnob> createState() => _CompactKnobState();
}

class _CompactKnobState extends State<_CompactKnob> {
  double _dragStartY = 0;
  double _dragStartValue = 0;

  @override
  Widget build(BuildContext context) {
    final canDrag = widget.onChanged != null;
    return GestureDetector(
      onVerticalDragStart: canDrag
          ? (details) {
              _dragStartY = details.globalPosition.dy;
              _dragStartValue = widget.value;
            }
          : null,
      onVerticalDragUpdate: canDrag
          ? (details) {
              final delta = _dragStartY - details.globalPosition.dy;
              final sensitivity = 0.01;
              final newValue = (_dragStartValue + delta * sensitivity).clamp(-1.0, 1.0);
              widget.onChanged!(newValue);
            }
          : null,
      child: CustomPaint(
        painter: _CompactKnobPainter(
          value: widget.value,
          activeColor: canDrag ? widget.activeColor : SynthTheme.textSecondary.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

class _CompactKnobPainter extends CustomPainter {
  final double value;
  final Color activeColor;

  _CompactKnobPainter({required this.value, required this.activeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Track arc
    final trackPaint = Paint()
      ..color = activeColor.withValues(alpha: 0.15)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.75 * 3.14159,
      1.5 * 3.14159,
      false,
      trackPaint,
    );

    // Active arc
    final normalized = (value + 1.0) / 2.0;
    final activeSweep = 1.5 * 3.14159 * normalized;
    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0.75 * 3.14159,
      activeSweep,
      false,
      activePaint,
    );

    // Center dot
    canvas.drawCircle(
      center,
      2,
      Paint()..color = activeColor,
    );
  }

  @override
  bool shouldRepaint(covariant _CompactKnobPainter old) =>
      value != old.value || activeColor != old.activeColor;
}
