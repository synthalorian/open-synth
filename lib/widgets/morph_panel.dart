import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/morph_provider.dart';
import '../providers/synth_providers.dart';
import '../theme/synth_theme.dart';
import 'synth_knob.dart';

class MorphPanel extends ConsumerWidget {
  const MorphPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final morph = ref.watch(morphConfigProvider);
    final presets = ref.watch(presetListProvider);
    final morphed = ref.watch(morphedPresetProvider);

    final sourcePreset = presets.firstWhere(
      (p) => p.id == morph.sourcePresetId,
      orElse: () => presets.isNotEmpty ? presets.first : morphed,
    );
    final targetPreset = presets.firstWhere(
      (p) => p.id == morph.targetPresetId,
      orElse: () => presets.length > 1 ? presets[1] : morphed,
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: morph.isPlaying
              ? SynthTheme.magenta.withValues(alpha: 0.4)
              : SynthTheme.purple.withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: morph.isPlaying
                      ? SynthTheme.magenta
                      : SynthTheme.purple.withValues(alpha: 0.3),
                  boxShadow: morph.isPlaying
                      ? [BoxShadow(color: SynthTheme.magenta.withValues(alpha: 0.5), blurRadius: 8)]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PRESET MORPH',
                style: TextStyle(
                  color: morph.isPlaying ? SynthTheme.magenta : SynthTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              // Auto-morph play/pause
              GestureDetector(
                onTap: () => ref.read(morphConfigProvider.notifier).toggle(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: morph.isPlaying
                        ? SynthTheme.magenta.withValues(alpha: 0.2)
                        : SynthTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: morph.isPlaying
                          ? SynthTheme.magenta
                          : SynthTheme.purple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        morph.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: morph.isPlaying ? SynthTheme.magenta : Colors.white.withValues(alpha: 0.7),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        morph.isPlaying ? 'PAUSE' : 'MORPH',
                        style: TextStyle(
                          color: morph.isPlaying ? SynthTheme.magenta : Colors.white.withValues(alpha: 0.7),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => ref.read(morphConfigProvider.notifier).stop(),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: SynthTheme.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.stop, color: Colors.redAccent, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Source / Target preset pickers
          Row(
            children: [
              Expanded(
                child: _PresetPicker(
                  label: 'SOURCE',
                  selectedId: morph.sourcePresetId,
                  presets: presets,
                  accentColor: SynthTheme.cyan,
                  onChanged: (id) => ref.read(morphConfigProvider.notifier).setSource(id),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.arrow_forward, color: SynthTheme.purple.withValues(alpha: 0.4), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: _PresetPicker(
                  label: 'TARGET',
                  selectedId: morph.targetPresetId,
                  presets: presets,
                  accentColor: SynthTheme.magenta,
                  onChanged: (id) => ref.read(morphConfigProvider.notifier).setTarget(id),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Position slider + speed knob
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Position slider
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'POSITION  ${(morph.position * 100).round()}%',
                      style: TextStyle(
                        color: SynthTheme.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 4,
                        activeTrackColor: SynthTheme.magenta,
                        inactiveTrackColor: SynthTheme.purple.withValues(alpha: 0.15),
                        thumbColor: SynthTheme.magenta,
                        overlayColor: SynthTheme.magenta.withValues(alpha: 0.2),
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: morph.position,
                        onChanged: (v) => ref.read(morphConfigProvider.notifier).setPosition(v),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Speed knob
              SynthKnob(
                label: 'SPEED',
                value: morph.speed,
                min: 0.01,
                max: 2.0,
                size: 56,
                formatValue: (v) => '${(v * 100).round()}%',
                onChanged: (v) => ref.read(morphConfigProvider.notifier).setSpeed(v),
                activeColor: SynthTheme.magenta,
              ),
            ],
          ),

          // Preview text
          if (morph.sourcePresetId.isNotEmpty && morph.targetPresetId.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${sourcePreset.name} → ${targetPreset.name}  •  ${morphed.name}',
                style: TextStyle(
                  color: SynthTheme.textSecondary.withValues(alpha: 0.5),
                  fontSize: 9,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
    );
  }
}

class _PresetPicker extends StatelessWidget {
  final String label;
  final String selectedId;
  final List<dynamic> presets;
  final Color accentColor;
  final ValueChanged<String> onChanged;

  const _PresetPicker({
    required this.label,
    required this.selectedId,
    required this.presets,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: accentColor.withValues(alpha: 0.7),
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: SynthTheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: accentColor.withValues(alpha: 0.25)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedId.isNotEmpty ? selectedId : null,
              isDense: true,
              dropdownColor: SynthTheme.card,
              hint: Text('Select preset', style: TextStyle(color: SynthTheme.textSecondary.withValues(alpha: 0.4), fontSize: 11)),
              style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.w600),
              iconSize: 14,
              iconEnabledColor: accentColor.withValues(alpha: 0.6),
              items: presets.map((p) {
                return DropdownMenuItem(
                  value: p.id as String,
                  child: Text(p.name as String, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (id) => onChanged(id!),
            ),
          ),
        ),
      ],
    );
  }
}
