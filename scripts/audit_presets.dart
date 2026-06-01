#!/usr/bin/env dart
// OpenSynth Preset Audit Script
// Analyzes factory_presets.dart for duplicates, stubs, broken presets, and quality issues.
//
// Usage: dart scripts/audit_presets.dart
//
// Outputs:
//   - audit_report.json   (full machine-readable report)
//   - audit_summary.txt   (human-readable summary)

import 'dart:convert';
import 'dart:io';
import 'dart:math';

// ── Minimal model copies for standalone analysis ────────────────────────────

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
  pads('Pads'),
  leads('Leads'),
  bass('Bass'),
  keys('Keys'),
  arps('Arps'),
  fx('FX'),
  synthwave('Synthwave'),
  piano('Piano'),
  organ('Organ'),
  guitar('Guitar'),
  strings('Strings'),
  brass('Brass'),
  choir('Choir'),
  percussion('Percussion'),
  custom('Custom'),
  drums('Drums'),
  acousticGuitar('Acoustic Guitar'),
  electricGuitar('Electric Guitar'),
  bassGuitar('Bass Guitar'),
  electricPiano('Electric Piano'),
  clavinet('Clavinet'),
  mallets('Mallets'),
  woodwinds('Woodwinds'),
  ethnic('Ethnic');

  const PresetCategory(this.displayName);

  final String displayName;
}

class Oscillator {
  final Waveform waveform;
  final int octave;
  final double detune;
  final double pulseWidth;
  final double volume;
  final bool enabled;
  final int noiseType;
  final int subOscMode;
  final double subOscVolume;
  final bool fmEnabled;
  final double fmAmount;
  final int unisonVoiceCount;
  final double unisonDetuneSpread;
  final double unisonStereoSpread;
  final double unisonMix;

  const Oscillator({
    this.waveform = Waveform.sine,
    this.octave = 0,
    this.detune = 0.0,
    this.pulseWidth = 0.5,
    this.volume = 0.8,
    this.enabled = true,
    this.noiseType = 0,
    this.subOscMode = 0,
    this.subOscVolume = 0.5,
    this.fmEnabled = false,
    this.fmAmount = 0.5,
    this.unisonVoiceCount = 1,
    this.unisonDetuneSpread = 10.0,
    this.unisonStereoSpread = 0.5,
    this.unisonMix = 1.0,
  });
}

class Envelope {
  final double attack;
  final double decay;
  final double sustain;
  final double release;
  final double delay;
  final double hold;
  final int attackCurve;
  final int decayCurve;
  final int releaseCurve;

  const Envelope({
    this.attack = 10.0,
    this.decay = 100.0,
    this.sustain = 0.7,
    this.release = 300.0,
    this.delay = 0.0,
    this.hold = 0.0,
    this.attackCurve = 0,
    this.decayCurve = 0,
    this.releaseCurve = 0,
  });
}

class FilterConfig {
  final int type;
  final double cutoff;
  final double resonance;
  final double envelopeAmount;
  final double keyTracking;
  final double drive;

  const FilterConfig({
    this.type = 0,
    this.cutoff = 10000.0,
    this.resonance = 0.0,
    this.envelopeAmount = 0.0,
    this.keyTracking = 0.0,
    this.drive = 0.0,
  });
}

class LfoConfig {
  final int waveform;
  final double rate;
  final double depth;
  final int target;
  final double fadeIn;
  final bool tempoSync;
  final int tempoDivision;

  const LfoConfig({
    this.waveform = 0,
    this.rate = 1.0,
    this.depth = 0.0,
    this.target = 0,
    this.fadeIn = 0.0,
    this.tempoSync = false,
    this.tempoDivision = 0,
  });
}

class FxConfig {
  final bool enabled;
  const FxConfig({this.enabled = false});
}

class SynthPreset {
  final String id;
  final String name;
  final PresetCategory category;
  final Oscillator osc1;
  final Oscillator osc2;
  final FilterConfig filter;
  final Envelope ampEnvelope;
  final Envelope filterEnvelope;
  final LfoConfig lfo1;
  final LfoConfig lfo2;
  final FxConfig chorus;
  final FxConfig delay;
  final FxConfig reverb;
  final FxConfig phaser;
  final FxConfig flanger;
  final FxConfig compressor;
  final FxConfig drive;
  final double masterVolume;
  final List<String> tags;
  final String author;
  final bool isBassPreset;

  SynthPreset({
    required this.id,
    required this.name,
    required this.category,
    this.osc1 = const Oscillator(),
    this.osc2 = const Oscillator(enabled: false),
    this.filter = const FilterConfig(),
    this.ampEnvelope = const Envelope(),
    this.filterEnvelope = const Envelope(),
    this.lfo1 = const LfoConfig(),
    this.lfo2 = const LfoConfig(),
    this.chorus = const FxConfig(),
    this.delay = const FxConfig(),
    this.reverb = const FxConfig(),
    this.phaser = const FxConfig(),
    this.flanger = const FxConfig(),
    this.compressor = const FxConfig(),
    this.drive = const FxConfig(),
    this.masterVolume = 0.8,
    this.tags = const [],
    this.author = 'Open Synth',
    this.isBassPreset = false,
  });
}

// ── Preset Parser ───────────────────────────────────────────────────────────

List<SynthPreset> parsePresets(String source) {
  final presets = <SynthPreset>[];

  // Find all SynthPreset( ... ) blocks
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
      (c) => c.name == catName,
      orElse: () => PresetCategory.custom,
    );

    // Extract the full block for parameter parsing
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
    final block = source.substring(start, end);

    presets.add(_parsePresetBlock(id, name, category, block));
  }

  return presets;
}

SynthPreset _parsePresetBlock(String id, String name, PresetCategory category, String block) {
  Waveform parseWaveform(String s) {
    final m = RegExp(r'Waveform\.([a-zA-Z]+)').firstMatch(s);
    if (m == null) return Waveform.sine;
    return Waveform.values.firstWhere(
      (w) => w.name == m.group(1),
      orElse: () => Waveform.sine,
    );
  }

  double parseDouble(String s, double def) {
    final m = RegExp(r'[=:]\s*([0-9.]+)').firstMatch(s);
    if (m == null) return def;
    return double.tryParse(m.group(1)!) ?? def;
  }

  int parseInt(String s, int def) {
    final m = RegExp(r'[=:]\s*([0-9-]+)').firstMatch(s);
    if (m == null) return def;
    return int.tryParse(m.group(1)!) ?? def;
  }

  bool parseBool(String s, bool def) {
    if (s.contains('true')) return true;
    if (s.contains('false')) return false;
    return def;
  }

  // Extract osc1 block
  final osc1Match = RegExp(r'osc1:\s*const\s+Oscillator\(([^)]+)\)').firstMatch(block);
  final osc1Str = osc1Match?.group(1) ?? '';

  // Extract osc2 block
  final osc2Match = RegExp(r'osc2:\s*const\s+Oscillator\(([^)]+)\)').firstMatch(block);
  final osc2Str = osc2Match?.group(1) ?? '';

  // Extract filter block
  final filterMatch = RegExp(r'filter:\s*const\s+FilterConfig\(([^)]+)\)').firstMatch(block);
  final filterStr = filterMatch?.group(1) ?? '';

  // Extract envelopes
  final ampEnvMatch = RegExp(r'ampEnvelope:\s*const\s+Envelope\(([^)]+)\)').firstMatch(block);
  final ampEnvStr = ampEnvMatch?.group(1) ?? '';

  final filterEnvMatch = RegExp(r'filterEnvelope:\s*const\s+Envelope\(([^)]+)\)').firstMatch(block);
  final filterEnvStr = filterEnvMatch?.group(1) ?? '';

  // Extract tags
  final tagsMatch = RegExp(r"tags:\s*\[([^\]]*)\]").firstMatch(block);
  final tags = <String>[];
  if (tagsMatch != null) {
    final tagStr = tagsMatch.group(1)!;
    final tagMatches = RegExp(r'["\x27]([^"\x27]+)["\x27]').allMatches(tagStr);
    for (final t in tagMatches) {
      tags.add(t.group(1)!);
    }
  }

  // Extract author
  final authorMatch = RegExp(r'author:\s*["\x27]([^"\x27]+)["\x27]').firstMatch(block);
  final author = authorMatch?.group(1) ?? 'Open Synth';

  // Extract isBassPreset
  final bassMatch = RegExp(r'isBassPreset:\s*(true|false)').firstMatch(block);
  final isBass = bassMatch != null && bassMatch.group(1) == 'true';

  return SynthPreset(
    id: id,
    name: name,
    category: category,
    osc1: Oscillator(
      waveform: parseWaveform(osc1Str),
      octave: parseInt(RegExp(r'octave:\s*([0-9-]+)').stringMatch(osc1Str) ?? '', 0),
      detune: parseDouble(RegExp(r'detune:\s*([0-9.-]+)').stringMatch(osc1Str) ?? '', 0.0),
      volume: parseDouble(RegExp(r'volume:\s*([0-9.]+)').stringMatch(osc1Str) ?? '', 0.8),
      enabled: parseBool(osc1Str, true),
      noiseType: parseInt(RegExp(r'noiseType:\s*([0-9]+)').stringMatch(osc1Str) ?? '', 0),
      subOscMode: parseInt(RegExp(r'subOscMode:\s*([0-9]+)').stringMatch(osc1Str) ?? '', 0),
      subOscVolume: parseDouble(RegExp(r'subOscVolume:\s*([0-9.]+)').stringMatch(osc1Str) ?? '', 0.5),
      fmEnabled: parseBool(RegExp(r'fmEnabled:\s*(true|false)').stringMatch(osc1Str) ?? '', false),
      fmAmount: parseDouble(RegExp(r'fmAmount:\s*([0-9.]+)').stringMatch(osc1Str) ?? '', 0.5),
      unisonVoiceCount: parseInt(RegExp(r'unisonVoiceCount:\s*([0-9]+)').stringMatch(osc1Str) ?? '', 1),
      unisonDetuneSpread: parseDouble(RegExp(r'unisonDetuneSpread:\s*([0-9.]+)').stringMatch(osc1Str) ?? '', 10.0),
      unisonStereoSpread: parseDouble(RegExp(r'unisonStereoSpread:\s*([0-9.]+)').stringMatch(osc1Str) ?? '', 0.5),
      unisonMix: parseDouble(RegExp(r'unisonMix:\s*([0-9.]+)').stringMatch(osc1Str) ?? '', 1.0),
    ),
    osc2: Oscillator(
      waveform: parseWaveform(osc2Str),
      octave: parseInt(RegExp(r'octave:\s*([0-9-]+)').stringMatch(osc2Str) ?? '', 0),
      detune: parseDouble(RegExp(r'detune:\s*([0-9.-]+)').stringMatch(osc2Str) ?? '', 0.0),
      volume: parseDouble(RegExp(r'volume:\s*([0-9.]+)').stringMatch(osc2Str) ?? '', 0.8),
      enabled: parseBool(osc2Str, true),
      noiseType: parseInt(RegExp(r'noiseType:\s*([0-9]+)').stringMatch(osc2Str) ?? '', 0),
      subOscMode: parseInt(RegExp(r'subOscMode:\s*([0-9]+)').stringMatch(osc2Str) ?? '', 0),
      subOscVolume: parseDouble(RegExp(r'subOscVolume:\s*([0-9.]+)').stringMatch(osc2Str) ?? '', 0.5),
      fmEnabled: parseBool(RegExp(r'fmEnabled:\s*(true|false)').stringMatch(osc2Str) ?? '', false),
      fmAmount: parseDouble(RegExp(r'fmAmount:\s*([0-9.]+)').stringMatch(osc2Str) ?? '', 0.5),
      unisonVoiceCount: parseInt(RegExp(r'unisonVoiceCount:\s*([0-9]+)').stringMatch(osc2Str) ?? '', 1),
      unisonDetuneSpread: parseDouble(RegExp(r'unisonDetuneSpread:\s*([0-9.]+)').stringMatch(osc2Str) ?? '', 10.0),
      unisonStereoSpread: parseDouble(RegExp(r'unisonStereoSpread:\s*([0-9.]+)').stringMatch(osc2Str) ?? '', 0.5),
      unisonMix: parseDouble(RegExp(r'unisonMix:\s*([0-9.]+)').stringMatch(osc2Str) ?? '', 1.0),
    ),
    filter: FilterConfig(
      cutoff: parseDouble(RegExp(r'cutoff:\s*([0-9.]+)').stringMatch(filterStr) ?? '', 10000.0),
      resonance: parseDouble(RegExp(r'resonance:\s*([0-9.]+)').stringMatch(filterStr) ?? '', 0.0),
      envelopeAmount: parseDouble(RegExp(r'envelopeAmount:\s*([0-9.-]+)').stringMatch(filterStr) ?? '', 0.0),
      keyTracking: parseDouble(RegExp(r'keyTracking:\s*([0-9.]+)').stringMatch(filterStr) ?? '', 0.0),
      drive: parseDouble(RegExp(r'drive:\s*([0-9.]+)').stringMatch(filterStr) ?? '', 0.0),
    ),
    ampEnvelope: Envelope(
      attack: parseDouble(RegExp(r'attack:\s*([0-9.]+)').stringMatch(ampEnvStr) ?? '', 10.0),
      decay: parseDouble(RegExp(r'decay:\s*([0-9.]+)').stringMatch(ampEnvStr) ?? '', 100.0),
      sustain: parseDouble(RegExp(r'sustain:\s*([0-9.]+)').stringMatch(ampEnvStr) ?? '', 0.7),
      release: parseDouble(RegExp(r'release:\s*([0-9.]+)').stringMatch(ampEnvStr) ?? '', 300.0),
    ),
    filterEnvelope: Envelope(
      attack: parseDouble(RegExp(r'attack:\s*([0-9.]+)').stringMatch(filterEnvStr) ?? '', 10.0),
      decay: parseDouble(RegExp(r'decay:\s*([0-9.]+)').stringMatch(filterEnvStr) ?? '', 100.0),
      sustain: parseDouble(RegExp(r'sustain:\s*([0-9.]+)').stringMatch(filterEnvStr) ?? '', 0.7),
      release: parseDouble(RegExp(r'release:\s*([0-9.]+)').stringMatch(filterEnvStr) ?? '', 300.0),
    ),
    tags: tags,
    author: author,
    isBassPreset: isBass,
  );
}

// ── Analysis ────────────────────────────────────────────────────────────────

class AuditReport {
  final int totalPresets;
  final Map<PresetCategory, int> categoryCounts;
  final List<String> duplicateNames;
  final List<String> stubWaveformPresets;
  final List<String> identicalOscPresets;
  final List<String> suspiciousEnvelopes;
  final List<String> missingTags;
  final List<String> allEnabledFx;
  final Map<String, int> tagFrequency;
  final List<String> recommendations;

  AuditReport({
    required this.totalPresets,
    required this.categoryCounts,
    required this.duplicateNames,
    required this.stubWaveformPresets,
    required this.identicalOscPresets,
    required this.suspiciousEnvelopes,
    required this.missingTags,
    required this.allEnabledFx,
    required this.tagFrequency,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() => {
    'totalPresets': totalPresets,
    'categoryCounts': categoryCounts.map((k, v) => MapEntry(k.name, v)),
    'duplicateNames': duplicateNames,
    'stubWaveformPresets': stubWaveformPresets,
    'identicalOscPresets': identicalOscPresets,
    'suspiciousEnvelopes': suspiciousEnvelopes,
    'missingTags': missingTags,
    'allEnabledFx': allEnabledFx,
    'tagFrequency': tagFrequency,
    'recommendations': recommendations,
  };
}

AuditReport analyzePresets(List<SynthPreset> presets) {
  // Category counts
  final categoryCounts = <PresetCategory, int>{};
  for (final p in presets) {
    categoryCounts[p.category] = (categoryCounts[p.category] ?? 0) + 1;
  }

  // Duplicate names
  final nameCounts = <String, int>{};
  for (final p in presets) {
    nameCounts[p.name] = (nameCounts[p.name] ?? 0) + 1;
  }
  final duplicateNames = nameCounts.entries
    .where((e) => e.value > 1)
    .map((e) => '${e.key} (${e.value}x)')
    .toList();

  // Stub waveforms (wt_* and pm_* that may not be fully implemented)
  final stubWaveforms = {
    Waveform.wtPiano, Waveform.wtGuitar, Waveform.wtChoir,
    Waveform.wtBrass, Waveform.wtStrings, Waveform.wtWoodwind,
    Waveform.wtOrgan, Waveform.wtBell, Waveform.wtSynthBass,
    Waveform.wtSynthLead, Waveform.wtPad, Waveform.wtEPiano,
    Waveform.pmKarplus, Waveform.pmKarplusBright, Waveform.pmKarplusBass,
    Waveform.pmModalMallet, Waveform.pmModalVibraphone, Waveform.pmModalSteel,
  };
  final stubWaveformPresets = <String>[];
  for (final p in presets) {
    if (stubWaveforms.contains(p.osc1.waveform) || stubWaveforms.contains(p.osc2.waveform)) {
      stubWaveformPresets.add('${p.name} (${p.category.name}): ${p.osc1.waveform.name}/${p.osc2.waveform.name}');
    }
  }

  // Identical osc1+osc2 (wasted voices)
  final identicalOscPresets = <String>[];
  for (final p in presets) {
    if (p.osc1.enabled && p.osc2.enabled &&
        p.osc1.waveform == p.osc2.waveform &&
        p.osc1.octave == p.osc2.octave &&
        p.osc1.detune == p.osc2.detune &&
        p.osc1.pulseWidth == p.osc2.pulseWidth) {
      identicalOscPresets.add('${p.name} (${p.category.name}): both = ${p.osc1.waveform.name}');
    }
  }

  // Suspicious envelopes
  final suspiciousEnvelopes = <String>[];
  for (final p in presets) {
    // Attack > 5s on non-pad = suspicious
    if (p.ampEnvelope.attack > 5000 && p.category != PresetCategory.pads) {
      suspiciousEnvelopes.add('${p.name} (${p.category.name}): attack=${p.ampEnvelope.attack}ms');
    }
    // Release = 0 on anything = suspicious
    if (p.ampEnvelope.release < 10) {
      suspiciousEnvelopes.add('${p.name} (${p.category.name}): release=${p.ampEnvelope.release}ms (too short)');
    }
    // Sustain = 0 with long decay on non-percussion = suspicious
    if (p.ampEnvelope.sustain < 0.01 && p.ampEnvelope.decay > 500 &&
        p.category != PresetCategory.percussion && p.category != PresetCategory.drums) {
      suspiciousEnvelopes.add('${p.name} (${p.category.name}): sustain=0, decay=${p.ampEnvelope.decay}ms');
    }
  }

  // Missing tags
  final missingTags = presets
    .where((p) => p.tags.isEmpty)
    .map((p) => '${p.name} (${p.category.name})')
    .toList();

  // All-enabled FX (everything-on presets = CPU hogs)
  final allEnabledFx = <String>[];
  for (final p in presets) {
    int enabledCount = 0;
    if (p.chorus.enabled) enabledCount++;
    if (p.delay.enabled) enabledCount++;
    if (p.reverb.enabled) enabledCount++;
    if (p.phaser.enabled) enabledCount++;
    if (p.flanger.enabled) enabledCount++;
    if (p.compressor.enabled) enabledCount++;
    if (p.drive.enabled) enabledCount++;
    if (enabledCount >= 5) {
      allEnabledFx.add('${p.name} (${p.category.name}): $enabledCount FX enabled');
    }
  }

  // Tag frequency
  final tagFrequency = <String, int>{};
  for (final p in presets) {
    for (final t in p.tags) {
      tagFrequency[t] = (tagFrequency[t] ?? 0) + 1;
    }
  }

  // Recommendations
  final recommendations = <String>[];

  if (duplicateNames.isNotEmpty) {
    recommendations.add('Found ${duplicateNames.length} duplicate names. Merge or rename.');
  }
  if (stubWaveformPresets.isNotEmpty) {
    recommendations.add('Found ${stubWaveformPresets.length} presets using stub waveforms. Implement or replace.');
  }
  if (identicalOscPresets.isNotEmpty) {
    recommendations.add('Found ${identicalOscPresets.length} presets with identical osc1+osc2. Disable osc2 or add detune.');
  }
  if (suspiciousEnvelopes.isNotEmpty) {
    recommendations.add('Found ${suspiciousEnvelopes.length} presets with suspicious envelopes. Review attack/release times.');
  }
  if (missingTags.isNotEmpty) {
    recommendations.add('Found ${missingTags.length} presets with no tags. Add descriptive tags for searchability.');
  }
  if (allEnabledFx.isNotEmpty) {
    recommendations.add('Found ${allEnabledFx.length} presets with 5+ FX enabled. Consider reducing for CPU efficiency.');
  }

  // Category balance check
  final avgCount = presets.length / categoryCounts.length;
  final underrepresented = categoryCounts.entries
    .where((e) => e.value < avgCount * 0.5)
    .map((e) => e.key.name)
    .toList();
  if (underrepresented.isNotEmpty) {
    recommendations.add('Underrepresented categories: ${underrepresented.join(", ")}. Consider adding more presets.');
  }

  return AuditReport(
    totalPresets: presets.length,
    categoryCounts: categoryCounts,
    duplicateNames: duplicateNames,
    stubWaveformPresets: stubWaveformPresets,
    identicalOscPresets: identicalOscPresets,
    suspiciousEnvelopes: suspiciousEnvelopes,
    missingTags: missingTags,
    allEnabledFx: allEnabledFx,
    tagFrequency: tagFrequency,
    recommendations: recommendations,
  );
}

// ── Main ────────────────────────────────────────────────────────────────────

void main() {
  final factoryPresetsPath = 'lib/data/factory_presets.dart';

  print('OpenSynth Preset Audit');
  print('=' * 60);

  if (!File(factoryPresetsPath).existsSync()) {
    print('ERROR: $factoryPresetsPath not found. Run from project root.');
    exit(1);
  }

  print('Loading presets from $factoryPresetsPath...');
  final source = File(factoryPresetsPath).readAsStringSync();

  print('Parsing ${source.length} characters...');
  final presets = parsePresets(source);
  print('Found ${presets.length} presets.\n');

  print('Analyzing...');
  final report = analyzePresets(presets);

  // Write JSON report
  final jsonReport = JsonEncoder.withIndent('  ').convert(report.toJson());
  File('audit_report.json').writeAsStringSync(jsonReport);
  print('Wrote audit_report.json');

  // Write human-readable summary
  final summary = StringBuffer();
  summary.writeln('OpenSynth Preset Audit Summary');
  summary.writeln('=' * 60);
  summary.writeln('Total presets: ${report.totalPresets}');
  summary.writeln();
  summary.writeln('Category breakdown:');
  final sortedCats = report.categoryCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final e in sortedCats) {
    summary.writeln('  ${e.key.displayName.padRight(20)} ${e.value.toString().padLeft(4)}');
  }
  summary.writeln();

  summary.writeln('Issues found:');
  summary.writeln('  Duplicate names:        ${report.duplicateNames.length}');
  summary.writeln('  Stub waveforms:         ${report.stubWaveformPresets.length}');
  summary.writeln('  Identical oscillators:  ${report.identicalOscPresets.length}');
  summary.writeln('  Suspicious envelopes:   ${report.suspiciousEnvelopes.length}');
  summary.writeln('  Missing tags:           ${report.missingTags.length}');
  summary.writeln('  CPU-heavy (5+ FX):      ${report.allEnabledFx.length}');
  summary.writeln();

  if (report.duplicateNames.isNotEmpty) {
    summary.writeln('Duplicate names:');
    for (final d in report.duplicateNames.take(20)) {
      summary.writeln('  - $d');
    }
    if (report.duplicateNames.length > 20) {
      summary.writeln('  ... and ${report.duplicateNames.length - 20} more');
    }
    summary.writeln();
  }

  if (report.stubWaveformPresets.isNotEmpty) {
    summary.writeln('Stub waveform presets (first 20):');
    for (final s in report.stubWaveformPresets.take(20)) {
      summary.writeln('  - $s');
    }
    if (report.stubWaveformPresets.length > 20) {
      summary.writeln('  ... and ${report.stubWaveformPresets.length - 20} more');
    }
    summary.writeln();
  }

  if (report.identicalOscPresets.isNotEmpty) {
    summary.writeln('Identical oscillator presets (first 20):');
    for (final s in report.identicalOscPresets.take(20)) {
      summary.writeln('  - $s');
    }
    if (report.identicalOscPresets.length > 20) {
      summary.writeln('  ... and ${report.identicalOscPresets.length - 20} more');
    }
    summary.writeln();
  }

  if (report.suspiciousEnvelopes.isNotEmpty) {
    summary.writeln('Suspicious envelopes (first 20):');
    for (final s in report.suspiciousEnvelopes.take(20)) {
      summary.writeln('  - $s');
    }
    if (report.suspiciousEnvelopes.length > 20) {
      summary.writeln('  ... and ${report.suspiciousEnvelopes.length - 20} more');
    }
    summary.writeln();
  }

  if (report.allEnabledFx.isNotEmpty) {
    summary.writeln('CPU-heavy presets (first 20):');
    for (final s in report.allEnabledFx.take(20)) {
      summary.writeln('  - $s');
    }
    if (report.allEnabledFx.length > 20) {
      summary.writeln('  ... and ${report.allEnabledFx.length - 20} more');
    }
    summary.writeln();
  }

  summary.writeln('Top 20 tags:');
  final sortedTags = report.tagFrequency.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  for (final e in sortedTags.take(20)) {
    summary.writeln('  ${e.key.padRight(20)} ${e.value.toString().padLeft(4)}');
  }
  summary.writeln();

  summary.writeln('Recommendations:');
  for (final r in report.recommendations) {
    summary.writeln('  • $r');
  }

  File('audit_summary.txt').writeAsStringSync(summary.toString());
  print('Wrote audit_summary.txt');

  print('\n' + '=' * 60);
  print('Audit complete. See audit_summary.txt for details.');
  print('JSON data available in audit_report.json');
}
