import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/synth_preset.dart';
import '../providers/favorites_provider.dart';
import '../theme/synth_theme.dart';
import 'preset_waveform_preview.dart';

class PresetCard extends ConsumerWidget {
  final SynthPreset preset;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const PresetCard({
    super.key,
    required this.preset,
    required this.isSelected,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesProvider).contains(preset.id);
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? SynthTheme.magenta.withValues(alpha: 0.15)
              : SynthTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? SynthTheme.magenta
                : SynthTheme.purple.withValues(alpha: 0.2),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: SynthTheme.magenta.withValues(alpha: 0.15),
                    blurRadius: 12,
                  )
                ]
              : null,
        ),
        child: Row(
          children: [
            // Waveform preview
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: PresetWaveformPreview(
                waveform: preset.osc1.waveform,
                dualOsc: preset.osc2.enabled,
                size: 28,
              ),
            ),
            // Preset name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.name,
                    style: TextStyle(
                      color: isSelected ? SynthTheme.magenta : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (preset.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        preset.tags.take(3).join(' · '),
                        style: TextStyle(
                          color: SynthTheme.textSecondary,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),

            // Favorite star
            GestureDetector(
              onTap: () => ref.read(favoritesProvider.notifier).toggle(preset.id),
              child: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? SynthTheme.orange : SynthTheme.textSecondary.withValues(alpha: 0.3),
                size: 18,
              ),
            ),
            const SizedBox(width: 6),

            // Category badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: SynthTheme.purple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: SynthTheme.purple.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                preset.category.displayName,
                style: TextStyle(
                  color: SynthTheme.purple,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // Bass badge
            if (preset.isBassPreset) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: SynthTheme.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: SynthTheme.orange.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'BASS',
                  style: TextStyle(
                    color: SynthTheme.orange,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
