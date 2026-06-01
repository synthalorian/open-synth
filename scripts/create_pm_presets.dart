#!/usr/bin/env dart
// OpenSynth Physical Modeling Preset Creator
// Creates new presets using pmKarplus and pmModal waveforms
// and updates existing presets to use physical modeling where appropriate.
//
// Usage: dart scripts/create_pm_presets.dart
// Output: lib/data/factory_presets_pm.dart (merged with existing)

import 'dart:io';

// New presets to add — these use physical modeling waveforms
const String _newPresets = '''
  // ── PHYSICAL MODELING: PLUCKED STRINGS ─────────────────
  SynthPreset(
    id: 'pm-guitar-01',
    name: 'Nylon Guitar PM',
    category: PresetCategory.acousticGuitar,
    osc1: const Oscillator(waveform: Waveform.pmKarplus, volume: 0.85),
    osc2: const Oscillator(waveform: Waveform.sine, octave: 1, volume: 0.2, enabled: false),
    filter: const FilterConfig(cutoff: 5500, resonance: 0.1, keyTracking: 0.6),
    ampEnvelope: const Envelope(attack: 5, decay: 800, sustain: 0.4, release: 600),
    reverb: const ReverbConfig(enabled: true, size: 0.6, damping: 0.4, mix: 0.35),
    tags: ['guitar', 'nylon', 'classical', 'plucked', 'physical model'],
    author: 'Open Synth',
  ),
  SynthPreset(
    id: 'pm-guitar-02',
    name: 'Steel String Guitar PM',
    category: PresetCategory.acousticGuitar,
    osc1: const Oscillator(waveform: Waveform.pmKarplusBright, volume: 0.8),
    osc2: const Oscillator(waveform: Waveform.sine, octave: 1, detune: 5.0, volume: 0.15),
    filter: const FilterConfig(cutoff: 7000, resonance: 0.15, keyTracking: 0.5),
    ampEnvelope: const Envelope(attack: 3, decay: 600, sustain: 0.35, release: 500),
    reverb: const ReverbConfig(enabled: true, size: 0.55, damping: 0.3, mix: 0.3),
    tags: ['guitar', 'steel', 'acoustic', 'folk', 'physical model'],
    author: 'Open Synth',
  ),
  SynthPreset(
    id: 'pm-bass-01',
    name: 'Acoustic Bass PM',
    category: PresetCategory.bassGuitar,
    osc1: const Oscillator(waveform: Waveform.pmKarplusBass, volume: 0.9),
    osc2: const Oscillator(waveform: Waveform.sine, octave: 1, volume: 0.2, enabled: false),
    filter: const FilterConfig(cutoff: 3500, resonance: 0.05, keyTracking: 0.4),
    ampEnvelope: const Envelope(attack: 8, decay: 400, sustain: 0.5, release: 350),
    reverb: const ReverbConfig(enabled: true, size: 0.4, damping: 0.5, mix: 0.2),
    tags: ['bass', 'acoustic', 'upright', 'plucked', 'physical model'],
    author: 'Open Synth',
  ),
  SynthPreset(
    id: 'pm-harp-01',
    name: 'Celtic Harp PM',
    category: PresetCategory.ethnic,
    osc1: const Oscillator(waveform: Waveform.pmKarplus, volume: 0.8),
    osc2: const Oscillator(waveform: Waveform.sine, octave: 1, detune: 7.0, volume: 0.2),
    filter: const FilterConfig(cutoff: 8000, resonance: 0.1, keyTracking: 0.7),
    ampEnvelope: const Envelope(attack: 2, decay: 1000, sustain: 0.3, release: 800),
    reverb: const ReverbConfig(enabled: true, size: 0.7, damping: 0.3, mix: 0.4),
    tags: ['harp', 'celtic', 'ethnic', 'plucked', 'physical model'],
    author: 'Open Synth',
  ),

  // ── PHYSICAL MODELING: MALLETS ─────────────────────────
  SynthPreset(
    id: 'pm-marimba-01',
    name: 'Marimba PM',
    category: PresetCategory.mallets,
    osc1: const Oscillator(waveform: Waveform.pmModalMallet, volume: 0.85),
    osc2: const Oscillator(waveform: Waveform.sine, octave: 1, volume: 0.15, enabled: false),
    filter: const FilterConfig(cutoff: 6000, resonance: 0.05, keyTracking: 0.5),
    ampEnvelope: const Envelope(attack: 2, decay: 500, sustain: 0.1, release: 300),
    reverb: const ReverbConfig(enabled: true, size: 0.5, damping: 0.4, mix: 0.3),
    tags: ['marimba', 'mallet', 'wood', 'percussion', 'physical model'],
    author: 'Open Synth',
  ),
  SynthPreset(
    id: 'pm-vibes-01',
    name: 'Vibraphone PM',
    category: PresetCategory.mallets,
    osc1: const Oscillator(waveform: Waveform.pmModalVibraphone, volume: 0.8),
    osc2: const Oscillator(waveform: Waveform.sine, octave: 1, detune: 3.0, volume: 0.2),
    filter: const FilterConfig(cutoff: 7000, resonance: 0.08, keyTracking: 0.6),
    ampEnvelope: const Envelope(attack: 3, decay: 800, sustain: 0.2, release: 500),
    lfo1: const LfoConfig(waveform: Waveform.sine, rate: 5.5, depth: 0.06, target: LfoTarget.pitch),
    reverb: const ReverbConfig(enabled: true, size: 0.6, damping: 0.3, mix: 0.35),
    tags: ['vibraphone', 'vibes', 'jazz', 'mallet', 'physical model'],
    author: 'Open Synth',
  ),
  SynthPreset(
    id: 'pm-steel-01',
    name: 'Steel Drum PM',
    category: PresetCategory.mallets,
    osc1: const Oscillator(waveform: Waveform.pmModalSteel, volume: 0.85),
    osc2: const Oscillator(waveform: Waveform.sine, octave: 1, volume: 0.15, enabled: false),
    filter: const FilterConfig(cutoff: 6500, resonance: 0.1, keyTracking: 0.5),
    ampEnvelope: const Envelope(attack: 1, decay: 600, sustain: 0.15, release: 400),
    reverb: const ReverbConfig(enabled: true, size: 0.55, damping: 0.35, mix: 0.3),
    tags: ['steel drum', 'pan', 'caribbean', 'mallet', 'physical model'],
    author: 'Open Synth',
  ),
  SynthPreset(
    id: 'pm-xylo-01',
    name: 'Xylophone PM',
    category: PresetCategory.mallets,
    osc1: const Oscillator(waveform: Waveform.pmModalMallet, volume: 0.8),
    osc2: const Oscillator(waveform: Waveform.sine, octave: 1, detune: 5.0, volume: 0.2),
    filter: const FilterConfig(cutoff: 8000, resonance: 0.02, keyTracking: 0.7),
    ampEnvelope: const Envelope(attack: 1, decay: 300, sustain: 0.05, release: 200),
    reverb: const ReverbConfig(enabled: true, size: 0.4, damping: 0.5, mix: 0.25),
    tags: ['xylophone', 'mallet', 'bright', 'percussion', 'physical model'],
    author: 'Open Synth',
  ),

  // ── PHYSICAL MODELING: KEYS ────────────────────────────
  SynthPreset(
    id: 'pm-clav-01',
    name: 'Clavinet PM',
    category: PresetCategory.keys,
    osc1: const Oscillator(waveform: Waveform.pmKarplusBright, volume: 0.85),
    osc2: const Oscillator(waveform: Waveform.sine, octave: 1, detune: 4.0, volume: 0.15),
    filter: const FilterConfig(cutoff: 6000, resonance: 0.2, keyTracking: 0.5),
    ampEnvelope: const Envelope(attack: 2, decay: 400, sustain: 0.3, release: 250),
    reverb: const ReverbConfig(enabled: true, size: 0.4, damping: 0.4, mix: 0.2),
    tags: ['clavinet', 'funk', 'keys', 'plucked', 'physical model'],
    author: 'Open Synth',
  ),
  SynthPreset(
    id: 'pm-harpsichord-01',
    name: 'Harpsichord PM',
    category: PresetCategory.keys,
    osc1: const Oscillator(waveform: Waveform.pmKarplusBright, volume: 0.8),
    osc2: const Oscillator(waveform: Waveform.sine, octave: 1, volume: 0.2, enabled: false),
    filter: const FilterConfig(cutoff: 7500, resonance: 0.1, keyTracking: 0.6),
    ampEnvelope: const Envelope(attack: 1, decay: 350, sustain: 0.25, release: 200),
    reverb: const ReverbConfig(enabled: true, size: 0.5, damping: 0.3, mix: 0.25),
    tags: ['harpsichord', 'baroque', 'keys', 'plucked', 'physical model'],
    author: 'Open Synth',
  ),

  // ── PHYSICAL MODELING: ETHNIC ──────────────────────────
  SynthPreset(
    id: 'pm-sitar-01',
    name: 'Sitar PM',
    category: PresetCategory.ethnic,
    osc1: const Oscillator(waveform: Waveform.pmKarplus, volume: 0.8),
    osc2: const Oscillator(waveform: Waveform.sine, octave: 1, detune: 12.0, volume: 0.2),
    filter: const FilterConfig(cutoff: 5000, resonance: 0.3, keyTracking: 0.4),
    ampEnvelope: const Envelope(attack: 5, decay: 700, sustain: 0.35, release: 500),
    reverb: const ReverbConfig(enabled: true, size: 0.6, damping: 0.4, mix: 0.35),
    tags: ['sitar', 'indian', 'ethnic', 'plucked', 'physical model'],
    author: 'Open Synth',
  ),
  SynthPreset(
    id: 'pm-koto-01',
    name: 'Koto PM',
    category: PresetCategory.ethnic,
    osc1: const Oscillator(waveform: Waveform.pmKarplusBright, volume: 0.8),
    osc2: const Oscillator(waveform: Waveform.sine, octave: 1, volume: 0.15, enabled: false),
    filter: const FilterConfig(cutoff: 6000, resonance: 0.15, keyTracking: 0.5),
    ampEnvelope: const Envelope(attack: 3, decay: 500, sustain: 0.3, release: 400),
    reverb: const ReverbConfig(enabled: true, size: 0.55, damping: 0.35, mix: 0.3),
    tags: ['koto', 'japanese', 'ethnic', 'plucked', 'physical model'],
    author: 'Open Synth',
  ),
''';

void main() {
  print('OpenSynth Physical Modeling Preset Creator');
  print('=' * 60);

  final sourceFile = File('lib/data/factory_presets.dart');
  if (!sourceFile.existsSync()) {
    print('ERROR: lib/data/factory_presets.dart not found.');
    exit(1);
  }

  final source = sourceFile.readAsStringSync();

  // Find the insertion point — after the first category comment block
  // We'll insert right after the opening `final List<SynthPreset> factoryPresets = [`
  final listStart = source.indexOf('final List<SynthPreset> factoryPresets = [');
  if (listStart < 0) {
    print('ERROR: Could not find factoryPresets list start.');
    exit(1);
  }

  // Find the position right after the opening bracket and newline
  final insertPos = source.indexOf('[', listStart) + 1;

  // Build output: header + new presets + original content
  final output = StringBuffer();
  output.write(source.substring(0, insertPos));
  output.writeln();
  output.writeln(_newPresets.trimRight());
  output.write(source.substring(insertPos));

  // Write output
  final outFile = File('lib/data/factory_presets_pm.dart');
  outFile.writeAsStringSync(output.toString());

  final origLines = sourceFile.readAsLinesSync().length;
  final newLines = outFile.readAsLinesSync().length;
  print('Wrote lib/data/factory_presets_pm.dart');
  print('  Original: $origLines lines');
  print('  With PM presets: $newLines lines');
  print('  Added: ${newLines - origLines} lines (12 new presets)');

  print('\nNext steps:');
  print('  1. Review lib/data/factory_presets_pm.dart');
  print('  2. Run flutter analyze to verify syntax');
  print('  3. Replace original: mv lib/data/factory_presets_pm.dart lib/data/factory_presets.dart');
  print('  4. Bump factoryPresetVersion');
  print('  5. Build and test');
}
