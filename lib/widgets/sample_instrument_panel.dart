import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/sample_presets.dart';
import '../models/sample_preset.dart';
import '../providers/sample_engine_provider.dart';
import '../theme/synth_theme.dart';

/// Panel for browsing and loading sample-based instruments (SFZ).
///
/// This sits alongside the synthesizer controls and lets the user
/// switch between synthesis and realistic sampled instruments.
class SampleInstrumentPanel extends ConsumerWidget {
  const SampleInstrumentPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(filteredSamplePresetsProvider);
    final selected = ref.watch(samplePresetProvider);
    final isLoading = ref.watch(samplePresetLoadingProvider);
    final categoryFilter = ref.watch(sampleCategoryFilterProvider);

    return Container(
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: SynthTheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected != null ? SynthTheme.cyan : SynthTheme.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'SAMPLE INSTRUMENTS',
                  style: TextStyle(
                    color: SynthTheme.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                if (isLoading) ...[
                  SizedBox(
                    width: 60,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SynthTheme.cyan,
                          ),
                        ),
                        const SizedBox(height: 2),
                        LinearProgressIndicator(
                          value: ref.watch(samplePresetLoadProgressProvider),
                          backgroundColor: SynthTheme.purple.withValues(alpha: 0.2),
                          color: SynthTheme.cyan,
                          minHeight: 2,
                        ),
                      ],
                    ),
                  ),
                ] else if (selected != null)
                  GestureDetector(
                    onTap: () {
                      ref.read(samplePresetProvider.notifier).state = null;
                    },
                    child: Icon(
                      Icons.close,
                      color: SynthTheme.textSecondary,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),

          // Category filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                _CategoryChip(
                  label: 'All',
                  isSelected: categoryFilter == null,
                  onTap: () => ref.read(sampleCategoryFilterProvider.notifier).state = null,
                ),
                ...SampleCategories.all.map((cat) => _CategoryChip(
                  label: cat,
                  isSelected: categoryFilter == cat,
                  onTap: () => ref.read(sampleCategoryFilterProvider.notifier).state = cat,
                )),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.white10),

          // Preset list
          Expanded(
            child: presets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.library_music_outlined,
                          color: SynthTheme.textSecondary.withValues(alpha: 0.3),
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No sample instruments available',
                          style: TextStyle(
                            color: SynthTheme.textSecondary.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add SFZ files to assets/samples/',
                          style: TextStyle(
                            color: SynthTheme.textSecondary.withValues(alpha: 0.3),
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    itemCount: presets.length,
                    itemBuilder: (context, index) {
                      final preset = presets[index];
                      final isSelected = selected?.id == preset.id;
                      return _PresetListTile(
                        preset: preset,
                        isSelected: isSelected,
                        onTap: () => _loadPreset(ref, preset),
                      );
                    },
                  ),
          ),

          // Selected preset info
          if (selected != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: SynthTheme.surface,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected.name.toUpperCase(),
                    style: TextStyle(
                      color: SynthTheme.magenta,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected.category,
                    style: TextStyle(
                      color: SynthTheme.textSecondary.withValues(alpha: 0.6),
                      fontSize: 9,
                    ),
                  ),
                  if (selected.description != null)
                    Text(
                      selected.description!,
                      style: TextStyle(
                        color: SynthTheme.textSecondary.withValues(alpha: 0.4),
                        fontSize: 8,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _loadPreset(WidgetRef ref, SamplePreset preset) {
    ref.read(samplePresetLoadingProvider.notifier).state = true;
    ref.read(samplePresetLoadProgressProvider.notifier).state = 0.0;
    ref.read(samplePresetProvider.notifier).state = preset;

    // The sampleAudioStreamProvider will auto-load the SFZ when the preset changes.
    // We poll the engine state to detect when loading is complete.
    _waitForLoad(ref);
  }

  void _waitForLoad(WidgetRef ref) {
    // Poll every 100ms for up to 30 seconds (large libraries take time)
    const maxAttempts = 300;
    int attempts = 0;

    void check() {
      attempts++;
      final engine = ref.read(sampleEngineProvider);
      final isLoaded = engine?.isLoaded ?? false;

      if (isLoaded) {
        ref.read(samplePresetLoadingProvider.notifier).state = false;
        ref.read(samplePresetLoadProgressProvider.notifier).state = 1.0;
        return;
      }

      if (attempts < maxAttempts) {
        final progress = (attempts / maxAttempts).clamp(0.0, 0.95);
        ref.read(samplePresetLoadProgressProvider.notifier).state = progress;
        Future.delayed(const Duration(milliseconds: 100), check);
      } else {
        // Timeout — loading failed or took too long
        ref.read(samplePresetLoadingProvider.notifier).state = false;
        ref.read(samplePresetLoadProgressProvider.notifier).state = 0.0;
        ref.read(samplePresetProvider.notifier).state = null;
      }
    }

    Future.delayed(const Duration(milliseconds: 100), check);
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? SynthTheme.cyan.withValues(alpha: 0.2)
              : SynthTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? SynthTheme.cyan
                : SynthTheme.purple.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? SynthTheme.cyan : SynthTheme.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _PresetListTile extends StatelessWidget {
  final SamplePreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetListTile({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? SynthTheme.cyan.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? SynthTheme.cyan.withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? SynthTheme.cyan : SynthTheme.purple.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.name,
                    style: TextStyle(
                      color: isSelected ? SynthTheme.cyan : Colors.white.withValues(alpha: 0.9),
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    preset.category,
                    style: TextStyle(
                      color: SynthTheme.textSecondary.withValues(alpha: 0.5),
                      fontSize: 8,
                    ),
                  ),
                ],
              ),
            ),
            if (preset.isBundled)
              Icon(
                Icons.folder_zip_outlined,
                color: SynthTheme.textSecondary.withValues(alpha: 0.3),
                size: 12,
              ),
          ],
        ),
      ),
    );
  }
}
