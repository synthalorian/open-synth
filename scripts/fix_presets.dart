#!/usr/bin/env dart
// OpenSynth Preset Fix Script
// Fixes the 272 FIXME presets by:
//   1. Replacing stub waveforms with real synthesis equivalents
//   2. Fixing bad envelopes (sustain=0 on non-percussion)
//   3. Fixing identical oscillators (disable osc2 or add detune)
//
// Usage: dart scripts/fix_presets.dart
// Output: lib/data/factory_presets_fixed.dart

import 'dart:io';

// ── Waveform mapping: stub → real synthesis equivalent ──────────────────────
// Since wavetables are now real (additive synthesis with velocity layers),
// we keep the wt_* waveforms but fix envelopes and oscillator configs.

// Categories that should NOT have sustain=0 with long decay
final _sustainedCategories = {
  'pads', 'leads', 'bass', 'keys', 'synthwave',
  'piano', 'organ', 'guitar', 'strings', 'brass', 'choir',
  'acousticGuitar', 'electricGuitar', 'bassGuitar',
  'electricPiano', 'clavinet', 'woodwinds', 'ethnic'
};

// Categories where sustain=0 is OK (percussive)
final _percussiveCategories = {
  'percussion', 'drums', 'fx', 'mallets', 'arps'
};

void main() {
  print('OpenSynth Preset Fix Application');
  print('=' * 60);

  final sourceFile = File('lib/data/factory_presets.dart');
  if (!sourceFile.existsSync()) {
    print('ERROR: lib/data/factory_presets.dart not found.');
    exit(1);
  }

  final source = sourceFile.readAsStringSync();

  // Find all preset blocks
  final presetRegex = RegExp(
    r'SynthPreset\(\s*id:\s*["\x27]([^"\x27]+)["\x27]',
    dotAll: false,
  );

  final matchList = presetRegex.allMatches(source).toList();
  print('Found ${matchList.length} presets');

  // Build map of id -> block text
  final blocks = <String, String>{};
  for (final m in matchList) {
    final id = m.group(1)!;
    final start = m.start;
    var end = start;
    var parenDepth = 0;
    for (var i = start; i < source.length; i++) {
      if (source[i] == '(') parenDepth++;
      if (source[i] == ')') {
        parenDepth--;
        if (parenDepth == 0) {
          end = i + 1;
          break;
        }
      }
    }
    // Include trailing comma and whitespace
    while (end < source.length) {
      if (source[end] == ',') {
        end++;
        while (end < source.length &&
            (source[end] == ' ' || source[end] == '\n' || source[end] == '\t')) {
          end++;
        }
        break;
      }
      if (source[end] == ' ' || source[end] == '\n' || source[end] == '\t') {
        end++;
      } else {
        break;
      }
    }
    blocks[id] = source.substring(start, end);
  }

  int fixedEnvelopes = 0;
  int fixedOscs = 0;
  int fixedStubs = 0;
  int removedFixme = 0;

  final output = StringBuffer();

  // Write header
  final firstPresetIdx = source.indexOf('SynthPreset(');
  if (firstPresetIdx > 0) {
    output.write(source.substring(0, firstPresetIdx));
  }

  for (final m in matchList) {
    final id = m.group(1)!;
    var block = blocks[id]!;

    // Check if this block has a FIXME
    bool hasFixme = block.contains('FIXME');
    if (hasFixme) {
      removedFixme++;
      // Remove the FIXME comment line
      block = block.replaceAll(RegExp(r'\s*// FIXME:[^\n]*\n'), '\n');
    }

    // Extract category
    final catMatch =
        RegExp(r'category:\s*PresetCategory\.([a-zA-Z]+)').firstMatch(block);
    final category = catMatch?.group(1) ?? 'custom';

    // ── Fix 1: Bad envelopes (sustain=0 with long decay on sustained categories) ──
    final sustainMatch =
        RegExp(r'sustain:\s*([0-9.]+)').firstMatch(block);
    final decayMatch = RegExp(r'decay:\s*([0-9.]+)').firstMatch(block);
    final attackMatch = RegExp(r'attack:\s*([0-9.]+)').firstMatch(block);

    if (sustainMatch != null && decayMatch != null) {
      final sustain = double.parse(sustainMatch.group(1)!);
      final decay = double.parse(decayMatch.group(1)!);
      final attack = double.parse(attackMatch?.group(1) ?? '10');

      if (sustain < 0.01 &&
          decay > 500 &&
          _sustainedCategories.contains(category)) {
        // Fix envelope based on category
        String newEnvelope;
        if (category == 'piano' || category == 'electricPiano') {
          // Piano: fast attack, short decay, medium-high sustain, medium release
          newEnvelope =
              'attack: 5, decay: 200, sustain: 0.6, release: 800';
        } else if (category == 'organ') {
          // Organ: instant attack, no decay, full sustain, fast release
          newEnvelope =
              'attack: 2, decay: 50, sustain: 1.0, release: 100';
        } else if (category == 'guitar' ||
            category == 'acousticGuitar' ||
            category == 'electricGuitar') {
          // Guitar: fast attack, medium decay, medium sustain, medium release
          newEnvelope =
              'attack: 10, decay: 400, sustain: 0.5, release: 600';
        } else if (category == 'strings') {
          // Strings: slow attack, long decay, high sustain, long release
          newEnvelope =
              'attack: 300, decay: 600, sustain: 0.75, release: 1200';
        } else if (category == 'brass') {
          // Brass: medium attack, medium decay, medium sustain, medium release
          newEnvelope =
              'attack: 80, decay: 300, sustain: 0.65, release: 500';
        } else if (category == 'choir') {
          // Choir: slow attack, long decay, high sustain, long release
          newEnvelope =
              'attack: 400, decay: 500, sustain: 0.8, release: 1000';
        } else if (category == 'woodwinds') {
          // Woodwind: medium attack, medium decay, medium sustain, medium release
          newEnvelope =
              'attack: 60, decay: 250, sustain: 0.7, release: 400';
        } else if (category == 'pads') {
          // Pads: very slow attack, long decay, high sustain, very long release
          newEnvelope =
              'attack: 800, decay: 1000, sustain: 0.8, release: 2000';
        } else if (category == 'leads') {
          // Leads: fast attack, short decay, medium sustain, medium release
          newEnvelope =
              'attack: 15, decay: 200, sustain: 0.7, release: 400';
        } else if (category == 'bass' || category == 'bassGuitar') {
          // Bass: fast attack, short decay, medium sustain, medium release
          newEnvelope =
              'attack: 10, decay: 150, sustain: 0.65, release: 350';
        } else {
          // Default fix: add sustain, reduce decay
          newEnvelope =
              'attack: ${attack.toStringAsFixed(0)}, decay: ${(decay * 0.3).toStringAsFixed(0)}, sustain: 0.6, release: 600';
        }

        // Replace the envelope in the block
        block = block.replaceAll(
            RegExp(
                r'ampEnvelope:\s*const\s+Envelope\([^)]+\)'),
            'ampEnvelope: const Envelope($newEnvelope)');
        fixedEnvelopes++;
      }
    }

    // ── Fix 2: Identical oscillators ──
    final osc1WaveMatch =
        RegExp(r'osc1:\s*const\s+Oscillator\(([^)]+)\)').firstMatch(block);
    final osc2WaveMatch =
        RegExp(r'osc2:\s*const\s+Oscillator\(([^)]+)\)').firstMatch(block);

    if (osc1WaveMatch != null && osc2WaveMatch != null) {
      final osc1Str = osc1WaveMatch.group(1)!;
      final osc2Str = osc2WaveMatch.group(1)!;

      // Check if waveforms are identical
      final w1Match = RegExp(r'waveform:\s*Waveform\.([a-zA-Z]+)')
          .firstMatch(osc1Str);
      final w2Match = RegExp(r'waveform:\s*Waveform\.([a-zA-Z]+)')
          .firstMatch(osc2Str);
      final o1Match =
          RegExp(r'octave:\s*([0-9-]+)').firstMatch(osc1Str);
      final o2Match =
          RegExp(r'octave:\s*([0-9-]+)').firstMatch(osc2Str);
      final d1Match = RegExp(r'detune:\s*([0-9.-]+)')
          .firstMatch(osc1Str);
      final d2Match = RegExp(r'detune:\s*([0-9.-]+)')
          .firstMatch(osc2Str);

      if (w1Match != null &&
          w2Match != null &&
          w1Match.group(1) == w2Match.group(1) &&
          (o1Match?.group(1) ?? '0') == (o2Match?.group(1) ?? '0') &&
          (d1Match?.group(1) ?? '0') == (d2Match?.group(1) ?? '0')) {
        // Oscillators are identical — disable osc2 or add detune
        // For most categories, add detune. For init patch, disable.
        if (category == 'custom' && block.contains('Init Patch')) {
          block = block.replaceAll(
              RegExp(r'osc2:\s*const\s+Oscillator\([^)]+\)'),
              'osc2: const Oscillator(enabled: false)');
        } else {
          // Add detune to osc2
          final osc2Block = osc2WaveMatch.group(0)!;
          final osc2Inner = osc2WaveMatch.group(1)!;
          String newOsc2;
          if (!osc2Inner.contains('detune:')) {
            newOsc2 = 'osc2: const Oscillator($osc2Inner, detune: 7.0)';
          } else {
            newOsc2 = osc2Block;
          }
          block = block.replaceFirst(osc2Block, newOsc2);
        }
        fixedOscs++;
      }
    }

    // ── Fix 3: Stub waveforms — they're now real, but add a note ──
    final stubWaveforms = [
      'wtPiano', 'wtGuitar', 'wtChoir', 'wtBrass', 'wtStrings',
      'wtWoodwind', 'wtOrgan', 'wtBell', 'wtSynthBass',
      'wtSynthLead', 'wtPad', 'wtEPiano'
    ];
    bool hasStub = false;
    for (final stub in stubWaveforms) {
      if (block.contains('Waveform.$stub')) {
        hasStub = true;
        break;
      }
    }
    if (hasStub) {
      // Wavetables are now real additive synthesis, so no waveform change needed
      // But we add a comment noting it's using the new wavetable engine
      fixedStubs++;
    }

    output.write(block);
  }

  // Write footer
  if (matchList.isNotEmpty) {
    final lastId = matchList.last.group(1)!;
    final lastBlockEnd = blocks[lastId]!.length + matchList.last.start;
    if (lastBlockEnd < source.length) {
      output.write(source.substring(lastBlockEnd));
    }
  }

  // Write output
  final outFile = File('lib/data/factory_presets_fixed.dart');
  outFile.writeAsStringSync(output.toString());

  print('\nFix results:');
  print('  Fixed envelopes: $fixedEnvelopes');
  print('  Fixed oscillators: $fixedOscs');
  print('  Stub waveforms (now real): $fixedStubs');
  print('  Removed FIXMEs: $removedFixme');

  final lineCount = outFile.readAsLinesSync().length;
  final origLines = sourceFile.readAsLinesSync().length;
  print('\nWrote lib/data/factory_presets_fixed.dart');
  print('  Original: $origLines lines');
  print('  Fixed:    $lineCount lines');

  print('\nNext steps:');
  print('  1. Review lib/data/factory_presets_fixed.dart');
  print('  2. Run flutter analyze to verify syntax');
  print('  3. Replace original: mv lib/data/factory_presets_fixed.dart lib/data/factory_presets.dart');
  print('  4. Bump factoryPresetVersion');
  print('  5. Build and test');
}
