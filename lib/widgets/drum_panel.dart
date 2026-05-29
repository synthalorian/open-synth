import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/drum_kit_config.dart';
import '../providers/drum_providers.dart';
import '../theme/synth_theme.dart';
import 'drum_pad_grid.dart';

/// Drum panel: kit selector, level knob, and 4×4 pad grid.
///
/// Designed for use inside a [CollapsibleSection] on mobile.
class DrumPanel extends ConsumerWidget {
  const DrumPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(drumKitConfigProvider);
    ref.watch(drumKitNativeBridgeProvider); // keep native engine synced

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Kit selector + level ──
        _buildControls(context, ref, config),
        const SizedBox(height: 8),
        // ── Pad grid ──
        const SizedBox(
          height: 340,
          child: DrumPadGrid(),
        ),
      ],
    );
  }

  Widget _buildControls(
    BuildContext context,
    WidgetRef ref,
    DrumKitConfig config,
  ) {
    final notifier = ref.read(drumKitConfigProvider.notifier);
    final kitName = DrumKitConfig.kitNames[config.kitIndex];

    return Row(
      children: [
        // Kit selector
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'KIT',
                style: TextStyle(
                  color: SynthTheme.purple.withValues(alpha: 0.6),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  _MiniButton(
                    icon: Icons.chevron_left,
                    onTap: config.kitIndex > 0
                        ? () => notifier.setKit(config.kitIndex - 1)
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: SynthTheme.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: SynthTheme.cyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        kitName,
                        style: TextStyle(
                          color: SynthTheme.cyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _MiniButton(
                    icon: Icons.chevron_right,
                    onTap: config.kitIndex < 9
                        ? () => notifier.setKit(config.kitIndex + 1)
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Level slider
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LEVEL',
                style: TextStyle(
                  color: SynthTheme.purple.withValues(alpha: 0.6),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              SizedBox(
                height: 28,
                child: SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: SynthTheme.orange,
                    inactiveTrackColor:
                        SynthTheme.orange.withValues(alpha: 0.2),
                    thumbColor: SynthTheme.orange,
                    trackHeight: 3,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                  ),
                  child: Slider(
                    value: config.level,
                    min: 0,
                    max: 1,
                    onChanged: (v) => notifier.setLevel(v),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _MiniButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: SynthTheme.card,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: onTap != null
                ? SynthTheme.magenta.withValues(alpha: 0.5)
                : SynthTheme.purple.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: onTap != null
              ? SynthTheme.magenta
              : SynthTheme.textSecondary.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}