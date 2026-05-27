import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/macro_config.dart';
import '../providers/macro_provider.dart';
import '../theme/synth_theme.dart';
import 'synth_knob.dart';

class MacroPanel extends ConsumerWidget {
  const MacroPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bank = ref.watch(macroBankProvider);
    final learnIndex = ref.watch(macroLearnModeProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: learnIndex >= 0
              ? SynthTheme.orange.withValues(alpha: 0.5)
              : SynthTheme.magenta.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: learnIndex >= 0
                      ? SynthTheme.orange
                      : SynthTheme.magenta.withValues(alpha: 0.6),
                  boxShadow: learnIndex >= 0
                      ? [
                          BoxShadow(
                            color: SynthTheme.orange.withValues(alpha: 0.6),
                            blurRadius: 6,
                          )
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'MACRO CONTROLS',
                style: TextStyle(
                  color: learnIndex >= 0 ? SynthTheme.orange : SynthTheme.magenta,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              if (learnIndex >= 0) ...[
                const SizedBox(width: 8),
                Text(
                  '(LEARN: M${learnIndex + 1})',
                  style: TextStyle(
                    color: SynthTheme.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const Spacer(),
              _SmallBtn(
                label: 'Reset',
                onTap: () => ref.read(macroBankProvider.notifier).resetAll(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (int i = 0; i < 4; i++) ...[
                Expanded(
                  child: _MacroKnob(index: i, macro: bank.getMacro(i)),
                ),
                if (i < 3) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MacroKnob extends ConsumerStatefulWidget {
  final int index;
  final MacroConfig macro;

  const _MacroKnob({required this.index, required this.macro});

  @override
  ConsumerState<_MacroKnob> createState() => _MacroKnobState();
}

class _MacroKnobState extends ConsumerState<_MacroKnob> {
  bool _isEditingName = false;
  late final _nameController = TextEditingController();

  @override
  void didUpdateWidget(covariant _MacroKnob oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.macro.name != widget.macro.name && !_isEditingName) {
      _nameController.text = widget.macro.name;
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.macro.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showCcPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SynthTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assign CC for "${widget.macro.name}"',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 200,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 8,
                      childAspectRatio: 1.2,
                    ),
                    itemCount: 128,
                    itemBuilder: (context, cc) {
                      final isSelected = widget.macro.ccNumber == cc;
                      final labels = {
                        1: 'Mod',
                        2: 'Breath',
                        7: 'Vol',
                        10: 'Pan',
                        11: 'Expr',
                        64: 'Sustain',
                        71: 'Res',
                        74: 'Cutoff',
                        91: 'Rev',
                        93: 'Chorus',
                        94: 'Detune',
                      };
                      return GestureDetector(
                        onTap: () {
                          ref
                              .read(macroBankProvider.notifier)
                              .setMacroCc(widget.index, cc);
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? SynthTheme.magenta.withValues(alpha: 0.4)
                                : SynthTheme.surface,
                            borderRadius: BorderRadius.circular(3),
                            border: Border.all(
                              color: isSelected
                                  ? SynthTheme.magenta
                                  : SynthTheme.purple.withValues(alpha: 0.2),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            labels[cc] ?? '$cc',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : SynthTheme.textSecondary,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final macro = widget.macro;
    final range = macro.maxValue - macro.minValue;
    final normalized = range > 0 ? (macro.value - macro.minValue) / range : 0.0;

    return Column(
      children: [
        GestureDetector(
          onLongPress: () => _showCcPicker(),
          child: SynthKnob(
            label: '',
            value: normalized,
            min: 0,
            max: 1,
            size: 56,
            formatValue: (_) => '${(normalized * 100).round()}',
            onChanged: (v) {
              final scaled = macro.minValue + v * range;
              ref
                  .read(macroBankProvider.notifier)
                  .setMacroValue(widget.index, scaled);
            },
            activeColor: SynthTheme.magenta,
          ),
        ),
        const SizedBox(height: 4),
        if (_isEditingName)
          SizedBox(
            height: 20,
            child: TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white, fontSize: 9),
              textAlign: TextAlign.center,
              maxLines: 1,
              decoration: InputDecoration(
                contentPadding: EdgeInsets.zero,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(3),
                  borderSide: BorderSide(color: SynthTheme.magenta.withValues(alpha: 0.4)),
                ),
              ),
              onSubmitted: (value) {
                ref
                    .read(macroBankProvider.notifier)
                    .setMacroName(widget.index, value.trim());
                setState(() => _isEditingName = false);
              },
              autofocus: true,
            ),
          )
        else
          GestureDetector(
            onTap: () => setState(() => _isEditingName = true),
            child: Text(
              macro.name,
              style: TextStyle(
                color: SynthTheme.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        const SizedBox(height: 2),
        GestureDetector(
          onTap: _showCcPicker,
          onLongPress: () => _showCcPicker(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: SynthTheme.surface,
              borderRadius: BorderRadius.circular(3),
              border: Border.all(
                color: SynthTheme.purple.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              'CC${macro.ccNumber}',
              style: TextStyle(
                color: SynthTheme.purple,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () {
            final currentLearn = ref.read(macroLearnModeProvider);
            if (currentLearn == widget.index) {
              ref.read(macroLearnModeProvider.notifier).state = -1;
            } else {
              ref.read(macroLearnModeProvider.notifier).state = widget.index;
            }
          },
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ref.watch(macroLearnModeProvider) == widget.index
                  ? SynthTheme.orange.withValues(alpha: 0.3)
                  : SynthTheme.surface,
              border: Border.all(
                color: ref.watch(macroLearnModeProvider) == widget.index
                    ? SynthTheme.orange
                    : SynthTheme.purple.withValues(alpha: 0.3),
                width: ref.watch(macroLearnModeProvider) == widget.index ? 1.5 : 1.0,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'L',
              style: TextStyle(
                color: ref.watch(macroLearnModeProvider) == widget.index
                    ? SynthTheme.orange
                    : SynthTheme.textSecondary,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SmallBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: SynthTheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: SynthTheme.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
