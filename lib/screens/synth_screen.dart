import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/synth_providers.dart';
import '../theme/synth_theme.dart';
import '../widgets/envelope_display.dart';
import '../widgets/filter_panel.dart';
import '../widgets/keyboard_widget.dart';
import '../widgets/lfo_panel.dart';
import '../widgets/oscillator_panel.dart';
import '../widgets/synth_knob.dart';
import 'preset_editor_screen.dart';

class SynthScreen extends ConsumerWidget {
  const SynthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preset = ref.watch(currentPresetProvider);
    final notifier = ref.read(currentPresetProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          preset.name,
          style: GoogleFonts.orbitron(
            color: SynthTheme.magenta,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.edit_outlined, color: SynthTheme.cyan, size: 20),
            tooltip: 'Edit Preset Info',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PresetEditorScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.save_outlined, color: SynthTheme.orange, size: 20),
            tooltip: 'Save Preset',
            onPressed: () {
              ref.read(presetListProvider.notifier).updatePreset(preset);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Preset "${preset.name}" saved'),
                  backgroundColor: SynthTheme.card,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Scrollable synth controls
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // ── Row 1: Oscillators ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: OscillatorPanel(
                          title: 'OSC 1',
                          oscillator: preset.osc1,
                          onChanged: (osc) =>
                              notifier.update((p) => p.copyWith(osc1: osc)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OscillatorPanel(
                          title: 'OSC 2',
                          oscillator: preset.osc2,
                          onChanged: (osc) =>
                              notifier.update((p) => p.copyWith(osc2: osc)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Row 2: Filter + Amp Envelope ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: FilterPanel(
                          filter: preset.filter,
                          onChanged: (f) =>
                              notifier.update((p) => p.copyWith(filter: f)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: EnvelopeDisplay(
                          title: 'AMP ENV',
                          envelope: preset.ampEnvelope,
                          accentColor: SynthTheme.magenta,
                          onChanged: (e) =>
                              notifier.update((p) => p.copyWith(ampEnvelope: e)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Row 3: Filter Envelope + LFO 1 ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: EnvelopeDisplay(
                          title: 'FILTER ENV',
                          envelope: preset.filterEnvelope,
                          accentColor: SynthTheme.orange,
                          onChanged: (e) =>
                              notifier.update((p) => p.copyWith(filterEnvelope: e)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: LfoPanel(
                          title: 'LFO 1',
                          lfo: preset.lfo1,
                          accentColor: SynthTheme.cyan,
                          onChanged: (l) =>
                              notifier.update((p) => p.copyWith(lfo1: l)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // ── Row 4: LFO 2 + Master Volume ──
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LfoPanel(
                          title: 'LFO 2',
                          lfo: preset.lfo2,
                          accentColor: SynthTheme.purple,
                          onChanged: (l) =>
                              notifier.update((p) => p.copyWith(lfo2: l)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: SynthTheme.card,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: SynthTheme.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'MASTER',
                                style: TextStyle(
                                  color: SynthTheme.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SynthKnob(
                                label: 'VOLUME',
                                value: preset.masterVolume,
                                min: 0,
                                max: 1,
                                size: 80,
                                formatValue: (v) => '${(v * 100).round()}',
                                onChanged: (v) =>
                                    notifier.update((p) => p.copyWith(masterVolume: v)),
                                activeColor: SynthTheme.orange,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // DSP status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: SynthTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: SynthTheme.purple.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SynthTheme.orange.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'DSP Engine: Awaiting C++ FFI Integration',
                          style: TextStyle(
                            color: SynthTheme.textSecondary,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Fixed keyboard at bottom ──
          const KeyboardWidget(),
        ],
      ),
    );
  }
}
