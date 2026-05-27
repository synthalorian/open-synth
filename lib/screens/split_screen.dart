import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/keyboard_split.dart';
import '../models/synth_preset.dart';
import '../providers/keyboard_split_provider.dart';
import '../providers/recent_presets_provider.dart';
import '../providers/synth_providers.dart';
import '../theme/synth_theme.dart';
import '../widgets/keyboard_widget.dart';
import '../widgets/split_panel.dart';


class SplitScreen extends ConsumerWidget {
  const SplitScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final split = ref.watch(keyboardSplitProvider);
    final allPresets = ref.watch(presetListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SPLIT / LAYER',
          style: GoogleFonts.orbitron(
            color: SynthTheme.cyan,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          // Quick zone A preset picker
          _ZonePresetChip(
            label: 'A',
            color: SynthTheme.cyan,
            presetName: split.presetA.name,
            onTap: () => _showPresetPicker(context, ref, isZoneB: false),
          ),
          const SizedBox(width: 8),
          // Quick zone B preset picker
          _ZonePresetChip(
            label: 'B',
            color: SynthTheme.magenta,
            presetName: split.presetB.name,
            onTap: () => _showPresetPicker(context, ref, isZoneB: true),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          // Scrollable controls
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Main split panel
                  const SplitPanel(),
                  const SizedBox(height: 12),

                  // Quick preset grid for Zone A
                  if (split.mode != SplitMode.normal) ...[
                    _ZonePresetGrid(
                      title: 'ZONE A PRESETS',
                      color: SynthTheme.cyan,
                      selectedPreset: split.presetA,
                      presets: allPresets,
                      onSelect: (p) {
                        ref.read(keyboardSplitProvider.notifier).setPresetA(p);
                        ref.read(recentPresetsProvider.notifier).track(p.id);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Quick preset grid for Zone B
                    _ZonePresetGrid(
                      title: 'ZONE B PRESETS',
                      color: SynthTheme.magenta,
                      selectedPreset: split.presetB,
                      presets: allPresets,
                      onSelect: (p) {
                        ref.read(keyboardSplitProvider.notifier).setPresetB(p);
                        ref.read(recentPresetsProvider.notifier).track(p.id);
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),

          // Fixed keyboard at bottom
          const KeyboardWidget(),
        ],
      ),
    );
  }

  void _showPresetPicker(BuildContext context, WidgetRef ref, {required bool isZoneB}) {
    final allPresets = ref.read(presetListProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: SynthTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select preset for ${isZoneB ? 'Zone B' : 'Zone A'}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 300,
                  child: ListView.separated(
                    itemCount: allPresets.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, color: Colors.transparent),
                    itemBuilder: (_, i) {
                      final p = allPresets[i];
                      return ListTile(
                        dense: true,
                        title: Text(
                          p.name,
                          style: const TextStyle(color: Colors.white, fontSize: 13),
                        ),
                        subtitle: Text(
                          p.category.displayName,
                          style: TextStyle(color: SynthTheme.textSecondary, fontSize: 10),
                        ),
                        onTap: () {
                          if (isZoneB) {
                            ref.read(keyboardSplitProvider.notifier).setPresetB(p);
                          } else {
                            ref.read(keyboardSplitProvider.notifier).setPresetA(p);
                          }
                          ref.read(recentPresetsProvider.notifier).track(p.id);
                          Navigator.pop(ctx);
                        },
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
}

class _ZonePresetChip extends StatelessWidget {
  final String label;
  final Color color;
  final String presetName;
  final VoidCallback onTap;

  const _ZonePresetChip({
    required this.label,
    required this.color,
    required this.presetName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
              child: Center(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              presetName,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _ZonePresetGrid extends ConsumerWidget {
  final String title;
  final Color color;
  final SynthPreset selectedPreset;
  final List<SynthPreset> presets;
  final ValueChanged<SynthPreset> onSelect;

  const _ZonePresetGrid({
    required this.title,
    required this.color,
    required this.selectedPreset,
    required this.presets,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: presets.length.clamp(0, 60),
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, index) {
                final p = presets[index];
                final isSelected = p.id == selectedPreset.id;
                return GestureDetector(
                  onTap: () => onSelect(p),
                  child: Container(
                    width: 100,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.2)
                          : SynthTheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSelected
                            ? color.withValues(alpha: 0.6)
                            : SynthTheme.purple.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(
                            color: isSelected ? color : Colors.white.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        Text(
                          p.category.displayName,
                          style: TextStyle(
                            color: SynthTheme.textSecondary,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
