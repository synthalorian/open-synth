import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ffi/openamp_synth.dart';
import '../models/synth_preset.dart';
import '../models/waveform.dart';
import '../providers/arpeggiator_provider.dart';
import '../providers/keyboard_split_provider.dart';
import '../providers/midi_recorder_provider.dart';
import '../providers/morph_provider.dart';
import '../providers/sample_engine_provider.dart';
import '../providers/synth_providers.dart';
import '../theme/retro_theme.dart';
import '../widgets/computer_keyboard_listener.dart';
import '../widgets/retro_button.dart';
import '../widgets/retro_keyboard.dart';
import '../widgets/retro_knob.dart';
import '../widgets/retro_lcd.dart';
import '../widgets/retro_rack_module.dart';

/// The main retro synth screen — single-page layout with rack modules.
///
/// Inspired by the Juno-106: LCD display at top, rack modules for each
/// section, and a full-width keyboard at the bottom.
class RetroSynthScreen extends ConsumerWidget {
  const RetroSynthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preset = ref.watch(currentPresetProvider);
    final morphed = ref.watch(morphedPresetProvider);
    final morphConfig = ref.watch(morphConfigProvider);
    final effectivePreset =
        (morphConfig.isPlaying || morphConfig.position > 0.0) ? morphed : preset;
    final notifier = ref.read(currentPresetProvider.notifier);
    final activeNotes = ref.watch(playbackStateProvider);
    final octave = ref.watch(keyboardOctaveProvider);

    // Keep engine sync alive
    ref.watch(livePresetSyncProvider);
    ref.watch(unifiedAudioStreamProvider);
    ref.watch(zoneAPresetSyncProvider);
    ref.watch(zoneBPresetSyncProvider);
    ref.watch(zoneBMixSyncProvider);
    ref.watch(sampleVolumeSyncProvider);

    return Scaffold(
      backgroundColor: RetroTheme.chassis,
      body: ComputerKeyboardListener(
        active: true,
        child: Column(
          children: [
            // ── Top Bar: LCD + Master Controls ───────────────────────
            _buildTopBar(context, ref, effectivePreset, notifier, octave),

            // ── Scrollable Rack Modules ──────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    // Oscillator module
                    RetroRackModule(
                      title: 'OSCILLATORS',
                      child: _OscillatorRack(
                        preset: effectivePreset,
                        onChanged: (p) => notifier.load(p),
                      ),
                    ),

                    // Filter module
                    RetroRackModule(
                      title: 'FILTER',
                      child: _FilterRack(
                        preset: effectivePreset,
                        onChanged: (p) => notifier.load(p),
                      ),
                    ),

                    // Envelope module
                    RetroRackModule(
                      title: 'ENVELOPES',
                      child: _EnvelopeRack(
                        preset: effectivePreset,
                        onChanged: (p) => notifier.load(p),
                      ),
                    ),

                    // LFO module
                    RetroRackModule(
                      title: 'LFO',
                      child: _LfoRack(
                        preset: effectivePreset,
                        onChanged: (p) => notifier.load(p),
                      ),
                    ),

                    // FX module
                    RetroRackModule(
                      title: 'EFFECTS',
                      child: _FxRack(
                        preset: effectivePreset,
                        onChanged: (p) => notifier.load(p),
                      ),
                    ),

                    // Sample instruments module
                    RetroRackModule(
                      title: 'SAMPLE INSTRUMENTS',
                      initiallyExpanded: false,
                      child: _SampleRack(ref: ref),
                    ),
                  ],
                ),
              ),
            ),

            // ── Keyboard ─────────────────────────────────────────────
            SizedBox(
              height: 140,
              child: RetroKeyboard(
                activeNotes: activeNotes,
                baseOctave: octave,
                onNoteOn: (note) => ref.read(noteRouterProvider).noteOn(note),
                onNoteOff: (note) => ref.read(noteRouterProvider).noteOff(note),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    SynthPreset preset,
    CurrentPresetNotifier notifier,
    int octave,
  ) {
    final presetList = ref.watch(presetListProvider);
    final split = ref.watch(keyboardSplitProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: RetroTheme.chassisGradient,
        border: Border(
          bottom: BorderSide(color: RetroTheme.highlight.withOpacity(0.2), width: 1),
        ),
      ),
      child: Row(
        children: [
          // LCD Display
          RetroLcd(
            text: preset.name,
            width: 180,
            height: 28,
          ),

          const SizedBox(width: 12),

          // Preset navigation
          RetroButton(
            label: 'PREV',
            width: 48,
            height: 28,
            onPressed: () {
              final idx = presetList.indexWhere((p) => p.id == preset.id);
              final prev = (idx - 1 + presetList.length) % presetList.length;
              notifier.load(presetList[prev]);
            },
          ),

          const SizedBox(width: 4),

          RetroButton(
            label: 'NEXT',
            width: 48,
            height: 28,
            onPressed: () {
              final idx = presetList.indexWhere((p) => p.id == preset.id);
              final next = (idx + 1) % presetList.length;
              notifier.load(presetList[next]);
            },
          ),

          const Spacer(),

          // Octave display
          Text(
            'OCT $octave',
            style: RetroTheme.valueText.copyWith(fontSize: 10),
          ),

          const SizedBox(width: 8),

          // Split indicator
          if (split.enabled)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: RetroTheme.magenta.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: RetroTheme.magenta.withOpacity(0.4)),
              ),
              child: Text(
                'SPLIT',
                style: RetroTheme.labelText.copyWith(
                  color: RetroTheme.magenta,
                  fontSize: 8,
                ),
              ),
            ),

          const SizedBox(width: 8),

          // Panic
          RetroButton(
            label: 'PANIC',
            width: 48,
            height: 28,
            onPressed: () => ref.read(noteRouterProvider).allNotesOff(),
          ),
        ],
      ),
    );
  }
}

// ── Oscillator Rack ──────────────────────────────────────────────────────────

class _OscillatorRack extends StatelessWidget {
  final SynthPreset preset;
  final ValueChanged<SynthPreset> onChanged;

  const _OscillatorRack({required this.preset, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OscColumn(
            title: 'OSC 1',
            osc: preset.osc1,
            onChanged: (osc) => onChanged(preset.copyWith(osc1: osc)),
          ),
        ),
        Container(width: 1, color: RetroTheme.shadow.withOpacity(0.3)),
        Expanded(
          child: _OscColumn(
            title: 'OSC 2',
            osc: preset.osc2,
            onChanged: (osc) => onChanged(preset.copyWith(osc2: osc)),
          ),
        ),
      ],
    );
  }
}

class _OscColumn extends StatelessWidget {
  final String title;
  final dynamic osc;
  final ValueChanged<dynamic> onChanged;

  const _OscColumn({required this.title, required this.osc, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(title, style: RetroTheme.labelText),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              RetroKnob(
                label: 'Wave',
                value: Waveform.values.indexOf(osc.waveform) / Waveform.values.length,
                onChanged: (v) {
                  final idx = (v * Waveform.values.length).floor().clamp(0, Waveform.values.length - 1);
                  onChanged(osc.copyWith(waveform: Waveform.values[idx]));
                },
              ),
              RetroKnob(
                label: 'Octave',
                value: (osc.octave + 2) / 4,
                valueLabel: '${osc.octave}',
                onChanged: (v) {
                  final oct = (v * 4 - 2).round().clamp(-2, 2);
                  onChanged(osc.copyWith(octave: oct));
                },
              ),
              RetroKnob(
                label: 'Detune',
                value: (osc.detune + 50) / 100,
                valueLabel: '${osc.detune.toStringAsFixed(0)}¢',
                onChanged: (v) {
                  final detune = (v * 100 - 50).clamp(-50.0, 50.0);
                  onChanged(osc.copyWith(detune: detune));
                },
              ),
              RetroKnob(
                label: 'Volume',
                value: osc.volume,
                valueLabel: '${(osc.volume * 100).round()}%',
                onChanged: (v) => onChanged(osc.copyWith(volume: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Filter Rack ──────────────────────────────────────────────────────────────

class _FilterRack extends StatelessWidget {
  final SynthPreset preset;
  final ValueChanged<SynthPreset> onChanged;

  const _FilterRack({required this.preset, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final f = preset.filter;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        RetroKnob(
          label: 'Cutoff',
          value: (f.cutoff - 20) / 19980,
          valueLabel: '${f.cutoff.toStringAsFixed(0)}Hz',
          onChanged: (v) => onChanged(preset.copyWith(
            filter: f.copyWith(cutoff: 20 + v * 19980),
          )),
        ),
        RetroKnob(
          label: 'Resonance',
          value: f.resonance,
          valueLabel: '${(f.resonance * 100).round()}%',
          onChanged: (v) => onChanged(preset.copyWith(
            filter: f.copyWith(resonance: v),
          )),
        ),
        RetroKnob(
          label: 'Env Amt',
          value: f.envelopeAmount,
          valueLabel: '${(f.envelopeAmount * 100).round()}%',
          onChanged: (v) => onChanged(preset.copyWith(
            filter: f.copyWith(envelopeAmount: v),
          )),
        ),
        RetroKnob(
          label: 'Drive',
          value: f.drive,
          valueLabel: '${(f.drive * 100).round()}%',
          onChanged: (v) => onChanged(preset.copyWith(
            filter: f.copyWith(drive: v),
          )),
        ),
      ],
    );
  }
}

// ── Envelope Rack ────────────────────────────────────────────────────────────

class _EnvelopeRack extends StatelessWidget {
  final SynthPreset preset;
  final ValueChanged<SynthPreset> onChanged;

  const _EnvelopeRack({required this.preset, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final amp = preset.ampEnvelope;
    final filter = preset.filterEnvelope;
    return Row(
      children: [
        Expanded(
          child: _EnvColumn(
            title: 'AMP ENV',
            env: amp,
            onChanged: (e) => onChanged(preset.copyWith(ampEnvelope: e)),
          ),
        ),
        Container(width: 1, color: RetroTheme.shadow.withOpacity(0.3)),
        Expanded(
          child: _EnvColumn(
            title: 'FILTER ENV',
            env: filter,
            onChanged: (e) => onChanged(preset.copyWith(filterEnvelope: e)),
          ),
        ),
      ],
    );
  }
}

class _EnvColumn extends StatelessWidget {
  final String title;
  final dynamic env;
  final ValueChanged<dynamic> onChanged;

  const _EnvColumn({required this.title, required this.env, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          Text(title, style: RetroTheme.labelText),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              RetroKnob(
                label: 'Attack',
                value: env.attack / 5000,
                valueLabel: '${env.attack.toStringAsFixed(0)}ms',
                onChanged: (v) => onChanged(env.copyWith(attack: v * 5000)),
              ),
              RetroKnob(
                label: 'Decay',
                value: env.decay / 5000,
                valueLabel: '${env.decay.toStringAsFixed(0)}ms',
                onChanged: (v) => onChanged(env.copyWith(decay: v * 5000)),
              ),
              RetroKnob(
                label: 'Sustain',
                value: env.sustain,
                valueLabel: '${(env.sustain * 100).round()}%',
                onChanged: (v) => onChanged(env.copyWith(sustain: v)),
              ),
              RetroKnob(
                label: 'Release',
                value: env.release / 5000,
                valueLabel: '${env.release.toStringAsFixed(0)}ms',
                onChanged: (v) => onChanged(env.copyWith(release: v * 5000)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── LFO Rack ─────────────────────────────────────────────────────────────────

class _LfoRack extends StatelessWidget {
  final SynthPreset preset;
  final ValueChanged<SynthPreset> onChanged;

  const _LfoRack({required this.preset, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final lfo1 = preset.lfo1;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        RetroKnob(
          label: 'Rate',
          value: lfo1.rate / 20,
          valueLabel: '${lfo1.rate.toStringAsFixed(1)}Hz',
          onChanged: (v) => onChanged(preset.copyWith(
            lfo1: lfo1.copyWith(rate: v * 20),
          )),
        ),
        RetroKnob(
          label: 'Depth',
          value: lfo1.depth,
          valueLabel: '${(lfo1.depth * 100).round()}%',
          onChanged: (v) => onChanged(preset.copyWith(
            lfo1: lfo1.copyWith(depth: v),
          )),
        ),
        RetroKnob(
          label: 'Wave',
          value: lfo1.waveform.index / 4,
          onChanged: (v) {
            final idx = (v * 4).floor().clamp(0, 3);
            onChanged(preset.copyWith(
              lfo1: lfo1.copyWith(waveform: Waveform.values[idx]),
            ));
          },
        ),
      ],
    );
  }
}

// ── FX Rack ──────────────────────────────────────────────────────────────────

class _FxRack extends StatelessWidget {
  final SynthPreset preset;
  final ValueChanged<SynthPreset> onChanged;

  const _FxRack({required this.preset, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final chorus = preset.chorus; final delay = preset.delay; final reverb = preset.reverb; final phaser = preset.phaser;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        RetroButton(
          label: 'Chorus',
          isToggle: true,
          isActive: chorus.enabled,
          onPressed: () => onChanged(preset.copyWith(
            chorus: chorus.copyWith(enabled: !chorus.enabled),
          )),
        ),
        RetroButton(
          label: 'Delay',
          isToggle: true,
          isActive: delay.enabled,
          onPressed: () => onChanged(preset.copyWith(
            delay: delay.copyWith(enabled: !delay.enabled),
          )),
        ),
        RetroButton(
          label: 'Reverb',
          isToggle: true,
          isActive: reverb.enabled,
          onPressed: () => onChanged(preset.copyWith(
            reverb: reverb.copyWith(enabled: !reverb.enabled),
          )),
        ),
        RetroButton(
          label: 'Phaser',
          isToggle: true,
          isActive: phaser.enabled,
          onPressed: () => onChanged(preset.copyWith(
            phaser: phaser.copyWith(enabled: !phaser.enabled),
          )),
        ),
      ],
    );
  }
}

// ── Sample Rack ──────────────────────────────────────────────────────────────

class _SampleRack extends StatelessWidget {
  final WidgetRef ref;

  const _SampleRack({required this.ref});

  @override
  Widget build(BuildContext context) {
    final presets = ref.watch(filteredSamplePresetsProvider);
    final selected = ref.watch(samplePresetProvider);

    if (presets.isEmpty) {
      return Center(
        child: Text(
          'NO SAMPLE LIBRARIES FOUND',
          style: RetroTheme.labelText,
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: presets.map((preset) {
        final isSelected = selected?.id == preset.id;
        return RetroButton(
          label: preset.name,
          width: 100,
          height: 40,
          isToggle: true,
          isActive: isSelected,
          onPressed: () {
            if (isSelected) {
              ref.read(samplePresetProvider.notifier).state = null;
            } else {
              ref.read(samplePresetProvider.notifier).state = preset;
            }
          },
        );
      }).toList(),
    );
  }
}
