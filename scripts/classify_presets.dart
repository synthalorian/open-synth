#!/usr/bin/env dart
// OpenSynth Preset Classification Script
// Classifies presets into keeper/merge/fix/kill based on parameter heuristics.
//
// Usage: dart scripts/classify_presets.dart
// Outputs: classification_report.json, cull_list.txt, fix_list.txt

import 'dart:convert';
import 'dart:io';
import 'dart:math';

// ── Minimal models (same as audit script) ───────────────────────────────────

enum Waveform {
  sine, saw, square, triangle, noise, wavetable,
  wtPiano, wtGuitar, wtChoir, wtBrass, wtStrings,
  wtWoodwind, wtOrgan, wtBell, wtSynthBass, wtSynthLead,
  wtPad, wtEPiano,
  pmKarplus, pmKarplusBright, pmKarplusBass,
  pmModalMallet, pmModalVibraphone, pmModalSteel,
  random,
}

enum PresetCategory {
  pads('Pads'), leads('Leads'), bass('Bass'), keys('Keys'),
  arps('Arps'), fx('FX'), synthwave('Synthwave'),
  piano('Piano'), organ('Organ'), guitar('Guitar'),
  strings('Strings'), brass('Brass'), choir('Choir'),
  percussion('Percussion'), custom('Custom'), drums('Drums'),
  acousticGuitar('Acoustic Guitar'), electricGuitar('Electric Guitar'),
  bassGuitar('Bass Guitar'), electricPiano('Electric Piano'),
  clavinet('Clavinet'), mallets('Mallets'), woodwinds('Woodwinds'), ethnic('Ethnic');

  const PresetCategory(this.displayName);
  final String displayName;
}

class Oscillator {
  final Waveform waveform; final int octave; final double detune;
  final double pulseWidth; final double volume; final bool enabled;
  final int noiseType; final int subOscMode; final double subOscVolume;
  final bool fmEnabled; final double fmAmount;
  final int unisonVoiceCount; final double unisonDetuneSpread;
  final double unisonStereoSpread; final double unisonMix;

  const Oscillator({
    this.waveform = Waveform.sine, this.octave = 0, this.detune = 0.0,
    this.pulseWidth = 0.5, this.volume = 0.8, this.enabled = true,
    this.noiseType = 0, this.subOscMode = 0, this.subOscVolume = 0.5,
    this.fmEnabled = false, this.fmAmount = 0.5,
    this.unisonVoiceCount = 1, this.unisonDetuneSpread = 10.0,
    this.unisonStereoSpread = 0.5, this.unisonMix = 1.0,
  });
}

class Envelope {
  final double attack, decay, sustain, release;
  const Envelope({this.attack = 10.0, this.decay = 100.0, this.sustain = 0.7, this.release = 300.0});
}

class FilterConfig {
  final double cutoff, resonance, envelopeAmount, keyTracking, drive;
  const FilterConfig({this.cutoff = 10000.0, this.resonance = 0.0, this.envelopeAmount = 0.0, this.keyTracking = 0.0, this.drive = 0.0});
}

class FxConfig {
  final bool enabled;
  const FxConfig({this.enabled = false});
}

class SynthPreset {
  final String id, name;
  final PresetCategory category;
  final Oscillator osc1, osc2;
  final FilterConfig filter;
  final Envelope ampEnvelope, filterEnvelope;
  final FxConfig chorus, delay, reverb, phaser, flanger, compressor, drive;
  final List<String> tags;

  SynthPreset({
    required this.id, required this.name, required this.category,
    this.osc1 = const Oscillator(), this.osc2 = const Oscillator(enabled: false),
    this.filter = const FilterConfig(),
    this.ampEnvelope = const Envelope(), this.filterEnvelope = const Envelope(),
    this.chorus = const FxConfig(), this.delay = const FxConfig(),
    this.reverb = const FxConfig(), this.phaser = const FxConfig(),
    this.flanger = const FxConfig(), this.compressor = const FxConfig(),
    this.drive = const FxConfig(), this.tags = const [],
  });
}

// ── Parser (simplified) ─────────────────────────────────────────────────────

List<SynthPreset> parsePresets(String source) {
  final presets = <SynthPreset>[];
  final presetRegex = RegExp(
    r'SynthPreset\(\s*id:\s*["\x27]([^"\x27]+)["\x27]\s*,\s*name:\s*["\x27]([^"\x27]+)["\x27]\s*,\s*category:\s*PresetCategory\.([a-zA-Z]+)',
    dotAll: false,
  );

  final matches = presetRegex.allMatches(source);
  for (final m in matches) {
    final id = m.group(1)!;
    final name = m.group(2)!;
    final catName = m.group(3)!;
    final category = PresetCategory.values.firstWhere(
      (c) => c.name == catName, orElse: () => PresetCategory.custom,
    );

    final start = m.start;
    var end = start;
    var parenDepth = 0;
    for (var i = start; i < source.length; i++) {
      if (source[i] == '(') parenDepth++;
      if (source[i] == ')') { parenDepth--; if (parenDepth == 0) { end = i + 1; break; } }
    }
    final block = source.substring(start, end);
    presets.add(_parseBlock(id, name, category, block));
  }
  return presets;
}

Waveform _parseWaveform(String s) {
  final m = RegExp(r'Waveform\.([a-zA-Z]+)').firstMatch(s);
  if (m == null) return Waveform.sine;
  return Waveform.values.firstWhere((w) => w.name == m.group(1), orElse: () => Waveform.sine);
}

double _parseDouble(String s, double def) {
  final m = RegExp(r'[=:]\s*([0-9.]+)').firstMatch(s);
  return m != null ? (double.tryParse(m.group(1)!) ?? def) : def;
}

int _parseInt(String s, int def) {
  final m = RegExp(r'[=:]\s*([0-9-]+)').firstMatch(s);
  return m != null ? (int.tryParse(m.group(1)!) ?? def) : def;
}

bool _parseBool(String s, bool def) {
  if (s.contains('true')) return true;
  if (s.contains('false')) return false;
  return def;
}

SynthPreset _parseBlock(String id, String name, PresetCategory category, String block) {
  final osc1M = RegExp(r'osc1:\s*const\s+Oscillator\(([^)]+)\)').firstMatch(block);
  final osc2M = RegExp(r'osc2:\s*const\s+Oscillator\(([^)]+)\)').firstMatch(block);
  final filterM = RegExp(r'filter:\s*const\s+FilterConfig\(([^)]+)\)').firstMatch(block);
  final ampM = RegExp(r'ampEnvelope:\s*const\s+Envelope\(([^)]+)\)').firstMatch(block);
  final filtEnvM = RegExp(r'filterEnvelope:\s*const\s+Envelope\(([^)]+)\)').firstMatch(block);

  final tagsM = RegExp(r"tags:\s*\[([^\]]*)\]").firstMatch(block);
  final tags = <String>[];
  if (tagsM != null) {
    for (final t in RegExp(r'["\x27]([^"\x27]+)["\x27]').allMatches(tagsM.group(1)!)) {
      tags.add(t.group(1)!);
    }
  }

  String osc1Str = osc1M?.group(1) ?? '';
  String osc2Str = osc2M?.group(1) ?? '';

  return SynthPreset(
    id: id, name: name, category: category,
    osc1: Oscillator(
      waveform: _parseWaveform(osc1Str),
      octave: _parseInt(RegExp(r'octave:\s*([0-9-]+)').stringMatch(osc1Str) ?? '', 0),
      detune: _parseDouble(RegExp(r'detune:\s*([0-9.-]+)').stringMatch(osc1Str) ?? '', 0.0),
      volume: _parseDouble(RegExp(r'volume:\s*([0-9.]+)').stringMatch(osc1Str) ?? '', 0.8),
      enabled: _parseBool(osc1Str, true),
    ),
    osc2: Oscillator(
      waveform: _parseWaveform(osc2Str),
      octave: _parseInt(RegExp(r'octave:\s*([0-9-]+)').stringMatch(osc2Str) ?? '', 0),
      detune: _parseDouble(RegExp(r'detune:\s*([0-9.-]+)').stringMatch(osc2Str) ?? '', 0.0),
      volume: _parseDouble(RegExp(r'volume:\s*([0-9.]+)').stringMatch(osc2Str) ?? '', 0.8),
      enabled: _parseBool(osc2Str, true),
    ),
    filter: FilterConfig(
      cutoff: _parseDouble(RegExp(r'cutoff:\s*([0-9.]+)').stringMatch(filterM?.group(1) ?? '') ?? '', 10000.0),
      resonance: _parseDouble(RegExp(r'resonance:\s*([0-9.]+)').stringMatch(filterM?.group(1) ?? '') ?? '', 0.0),
    ),
    ampEnvelope: Envelope(
      attack: _parseDouble(RegExp(r'attack:\s*([0-9.]+)').stringMatch(ampM?.group(1) ?? '') ?? '', 10.0),
      decay: _parseDouble(RegExp(r'decay:\s*([0-9.]+)').stringMatch(ampM?.group(1) ?? '') ?? '', 100.0),
      sustain: _parseDouble(RegExp(r'sustain:\s*([0-9.]+)').stringMatch(ampM?.group(1) ?? '') ?? '', 0.7),
      release: _parseDouble(RegExp(r'release:\s*([0-9.]+)').stringMatch(ampM?.group(1) ?? '') ?? '', 300.0),
    ),
    tags: tags,
  );
}

// ── Classification ──────────────────────────────────────────────────────────

class Classification {
  final List<SynthPreset> keep;
  final List<SynthPreset> merge;
  final List<SynthPreset> fix;
  final List<SynthPreset> kill;

  Classification({required this.keep, required this.merge, required this.fix, required this.kill});
}

Classification classifyPresets(List<SynthPreset> presets) {
  final keep = <SynthPreset>[];
  final merge = <SynthPreset>[];
  final fix = <SynthPreset>[];
  final kill = <SynthPreset>[];

  final stubWaveforms = {
    Waveform.wtPiano, Waveform.wtGuitar, Waveform.wtChoir,
    Waveform.wtBrass, Waveform.wtStrings, Waveform.wtWoodwind,
    Waveform.wtOrgan, Waveform.wtBell, Waveform.wtSynthBass,
    Waveform.wtSynthLead, Waveform.wtPad, Waveform.wtEPiano,
    Waveform.pmKarplus, Waveform.pmKarplusBright, Waveform.pmKarplusBass,
    Waveform.pmModalMallet, Waveform.pmModalVibraphone, Waveform.pmModalSteel,
  };

  // Group by name for duplicate detection
  final byName = <String, List<SynthPreset>>{};
  for (final p in presets) {
    byName.putIfAbsent(p.name, () => []).add(p);
  }

  // Track which IDs we've processed
  final processed = <String>{};

  for (final p in presets) {
    if (processed.contains(p.id)) continue;

    bool isStub = stubWaveforms.contains(p.osc1.waveform) || stubWaveforms.contains(p.osc2.waveform);
    bool isDuplicate = byName[p.name]!.length > 1;
    bool identicalOscs = p.osc1.enabled && p.osc2.enabled &&
        p.osc1.waveform == p.osc2.waveform &&
        p.osc1.octave == p.osc2.octave &&
        p.osc1.detune == p.osc2.detune;
    bool badEnvelope = false;

    // Bad envelope: sustain=0 with long decay on non-percussion
    if (p.ampEnvelope.sustain < 0.01 && p.ampEnvelope.decay > 500 &&
        p.category != PresetCategory.percussion && p.category != PresetCategory.drums &&
        p.category != PresetCategory.fx && p.category != PresetCategory.mallets) {
      badEnvelope = true;
    }

    // Generic preset detection: default-ish params with no character
    bool isGeneric = p.osc1.waveform == Waveform.sine &&
        p.osc2.waveform == Waveform.sine &&
        p.filter.cutoff > 9000 &&
        p.ampEnvelope.attack < 15 && p.ampEnvelope.decay < 150 &&
        p.ampEnvelope.sustain > 0.6 && p.ampEnvelope.release < 400;

    // KILL: stub + generic, or duplicate with no meaningful variation
    if (isStub && isGeneric) {
      kill.add(p);
      processed.add(p.id);
      continue;
    }

    // MERGE: duplicate names — mark all but the first as merge
    if (isDuplicate) {
      final dups = byName[p.name]!;
      // Keep the first one, merge the rest
      keep.add(dups.first);
      processed.add(dups.first.id);
      for (var i = 1; i < dups.length; i++) {
        merge.add(dups[i]);
        processed.add(dups[i].id);
      }
      continue;
    }

    // FIX: stub but has character, or bad envelope, or identical oscs
    if (isStub || badEnvelope || identicalOscs) {
      fix.add(p);
      processed.add(p.id);
      continue;
    }

    // KEEP: everything else
    keep.add(p);
    processed.add(p.id);
  }

  return Classification(keep: keep, merge: merge, fix: fix, kill: kill);
}

// ── Main ────────────────────────────────────────────────────────────────────

void main() {
  print('OpenSynth Preset Classification');
  print('=' * 60);

  final source = File('lib/data/factory_presets.dart').readAsStringSync();
  final presets = parsePresets(source);
  print('Parsed ${presets.length} presets');

  final cls = classifyPresets(presets);

  print('\nClassification results:');
  print('  KEEP:  ${cls.keep.length}');
  print('  MERGE: ${cls.merge.length} (duplicates to consolidate)');
  print('  FIX:   ${cls.fix.length} (needs parameter tweaks)');
  print('  KILL:  ${cls.kill.length} (remove)');
  print('  ─────────────────────────');
  print('  Total: ${cls.keep.length + cls.merge.length + cls.fix.length + cls.kill.length}');

  // Write cull list
  final cull = StringBuffer();
  cull.writeln('# OpenSynth Preset Cull List');
  cull.writeln('# Generated by classify_presets.dart');
  cull.writeln('#');
  cull.writeln('# KILL: ${cls.kill.length} presets to remove');
  cull.writeln('# MERGE: ${cls.merge.length} duplicates to consolidate');
  cull.writeln('#');
  cull.writeln('## KILL (remove entirely)');
  for (final p in cls.kill) {
    cull.writeln('- ${p.name} (${p.category.displayName}) [${p.id}]');
  }
  cull.writeln('\n## MERGE (duplicate names — keep best, kill rest)');
  final mergeByName = <String, List<SynthPreset>>{};
  for (final p in cls.merge) {
    mergeByName.putIfAbsent(p.name, () => []).add(p);
  }
  for (final entry in mergeByName.entries) {
    cull.writeln('- ${entry.key}: ${entry.value.length} duplicates');
    for (final p in entry.value) {
      cull.writeln('  * ${p.id} (${p.category.displayName})');
    }
  }
  File('cull_list.txt').writeAsStringSync(cull.toString());
  print('Wrote cull_list.txt');

  // Write fix list
  final fixBuf = StringBuffer();
  fixBuf.writeln('# OpenSynth Preset Fix List');
  fixBuf.writeln('# ${cls.fix.length} presets need parameter tweaks');
  fixBuf.writeln('#');
  for (final p in cls.fix) {
    String reason = '';
    final stubWaveforms = {
      Waveform.wtPiano, Waveform.wtGuitar, Waveform.wtChoir,
      Waveform.wtBrass, Waveform.wtStrings, Waveform.wtWoodwind,
      Waveform.wtOrgan, Waveform.wtBell, Waveform.wtSynthBass,
      Waveform.wtSynthLead, Waveform.wtPad, Waveform.wtEPiano,
      Waveform.pmKarplus, Waveform.pmKarplusBright, Waveform.pmKarplusBass,
      Waveform.pmModalMallet, Waveform.pmModalVibraphone, Waveform.pmModalSteel,
    };
    bool isStub = stubWaveforms.contains(p.osc1.waveform) || stubWaveforms.contains(p.osc2.waveform);
    bool identicalOscs = p.osc1.enabled && p.osc2.enabled &&
        p.osc1.waveform == p.osc2.waveform &&
        p.osc1.octave == p.osc2.octave &&
        p.osc1.detune == p.osc2.detune;
    bool badEnvelope = p.ampEnvelope.sustain < 0.01 && p.ampEnvelope.decay > 500 &&
        p.category != PresetCategory.percussion && p.category != PresetCategory.drums;

    if (isStub) reason += 'stub waveform; ';
    if (identicalOscs) reason += 'identical oscs; ';
    if (badEnvelope) reason += 'bad envelope (sustain=0, decay=${p.ampEnvelope.decay}ms); ';

    fixBuf.writeln('- ${p.name} (${p.category.displayName}) [${p.id}]');
    fixBuf.writeln('  Reason: $reason');
    fixBuf.writeln('  Fix: ${isStub ? "Replace waveform with real synthesis" : ""}${identicalOscs ? "Disable osc2 or add detune" : ""}${badEnvelope ? "Fix envelope sustain/decay" : ""}');
    fixBuf.writeln();
  }
  File('fix_list.txt').writeAsStringSync(fixBuf.toString());
  print('Wrote fix_list.txt');

  // Write JSON report
  final report = {
    'total': presets.length,
    'keep': cls.keep.length,
    'merge': cls.merge.length,
    'fix': cls.fix.length,
    'kill': cls.kill.length,
    'keepPresets': cls.keep.map((p) => {'id': p.id, 'name': p.name, 'category': p.category.name}).toList(),
    'mergePresets': cls.merge.map((p) => {'id': p.id, 'name': p.name, 'category': p.category.name}).toList(),
    'fixPresets': cls.fix.map((p) => {'id': p.id, 'name': p.name, 'category': p.category.name}).toList(),
    'killPresets': cls.kill.map((p) => {'id': p.id, 'name': p.name, 'category': p.category.name}).toList(),
  };
  File('classification_report.json').writeAsStringSync(JsonEncoder.withIndent('  ').convert(report));
  print('Wrote classification_report.json');

  print('\n' + '=' * 60);
  print('Classification complete.');
  print('Next steps:');
  print('  1. Review cull_list.txt — these presets will be removed');
  print('  2. Review fix_list.txt — these presets need parameter tweaks');
  print('  3. Run cull script to generate cleaned factory_presets.dart');
}
