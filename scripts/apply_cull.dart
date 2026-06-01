#!/usr/bin/env dart
// OpenSynth Preset Cull Application Script
// Reads classification_report.json and generates a cleaned factory_presets.dart
//
// Strategy:
//   - KEEP: preserve as-is
//   - MERGE: remove (keep only the first occurrence of each duplicate name)
//   - FIX: preserve but mark with // FIX comment for manual review
//   - KILL: remove entirely
//
// Usage: dart scripts/apply_cull.dart
// Output: lib/data/factory_presets_clean.dart

import 'dart:convert';
import 'dart:io';

void main() {
  print('OpenSynth Preset Cull Application');
  print('=' * 60);

  // Load classification report
  final reportFile = File('classification_report.json');
  if (!reportFile.existsSync()) {
    print('ERROR: classification_report.json not found. Run classify_presets.dart first.');
    exit(1);
  }

  final report = jsonDecode(reportFile.readAsStringSync()) as Map<String, dynamic>;

  // Build sets of IDs to remove
  final mergeIds = <String>{};
  final killIds = <String>{};
  final fixIds = <String>{};

  for (final p in report['mergePresets'] as List) {
    mergeIds.add(p['id'] as String);
  }
  for (final p in report['killPresets'] as List) {
    killIds.add(p['id'] as String);
  }
  for (final p in report['fixPresets'] as List) {
    fixIds.add(p['id'] as String);
  }

  print('Presets to remove:');
  print('  MERGE (duplicates): ${mergeIds.length}');
  print('  KILL (garbage):     ${killIds.length}');
  print('  FIX (preserve+mark): ${fixIds.length}');

  // Read original factory_presets.dart
  final sourceFile = File('lib/data/factory_presets.dart');
  if (!sourceFile.existsSync()) {
    print('ERROR: lib/data/factory_presets.dart not found.');
    exit(1);
  }

  final source = sourceFile.readAsStringSync();

  // Find all SynthPreset blocks with their IDs
  final presetRegex = RegExp(
    r'SynthPreset\(\s*id:\s*["\x27]([^"\x27]+)["\x27]',
    dotAll: false,
  );

  // Build a map of id -> block text (including trailing comma + whitespace)
  final blocks = <String, String>{};
  final matchList = presetRegex.allMatches(source).toList();

  for (int idx = 0; idx < matchList.length; idx++) {
    final m = matchList[idx];
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
    // Include trailing comma and whitespace up to next preset or list end
    while (end < source.length) {
      if (source[end] == ',') {
        end++;
        // consume whitespace/newlines after comma
        while (end < source.length && (source[end] == ' ' || source[end] == '\n' || source[end] == '\t')) {
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

  print('Found ${blocks.length} preset blocks in source');

  // Build the cleaned file
  final output = StringBuffer();

  // Write header (everything before first SynthPreset)
  final firstPresetIdx = source.indexOf('SynthPreset(');
  if (firstPresetIdx > 0) {
    output.write(source.substring(0, firstPresetIdx));
  }

  // Track which names we've kept (for duplicate elimination)
  final keptNames = <String>{};
  int kept = 0;
  int removed = 0;
  int markedFix = 0;

  // Process in original order
  for (final m in matchList) {
    final id = m.group(1)!;
    final block = blocks[id]!;

    // Extract name for duplicate tracking
    final nameMatch = RegExp(r'name:\s*["\x27]([^"\x27]+)["\x27]').firstMatch(block);
    final name = nameMatch?.group(1) ?? 'Unknown';

    if (killIds.contains(id)) {
      removed++;
      continue; // Skip entirely
    }

    if (mergeIds.contains(id)) {
      if (keptNames.contains(name)) {
        removed++;
        continue; // Skip duplicate
      }
      // First occurrence — keep it
      keptNames.add(name);
    }

    if (fixIds.contains(id)) {
      output.writeln('  // FIXME: This preset needs parameter tweaks');
      markedFix++;
    }

    output.write(block);
    kept++;
  }

  // Write footer (everything after last preset block's end)
  if (matchList.isNotEmpty) {
    final lastId = matchList.last.group(1)!;
    final lastBlockEnd = blocks[lastId]!.length + matchList.last.start;
    if (lastBlockEnd < source.length) {
      output.write(source.substring(lastBlockEnd));
    }
  }

  // Write output
  final outFile = File('lib/data/factory_presets_clean.dart');
  outFile.writeAsStringSync(output.toString());

  print('\nResults:');
  print('  Kept:    $kept');
  print('  Removed: $removed');
  print('  Marked FIX: $markedFix');
  print('  ───────────────');
  print('  Total:   ${kept + removed}');
  print('\nWrote lib/data/factory_presets_clean.dart');

  // Count lines
  final lineCount = outFile.readAsLinesSync().length;
  final origLines = sourceFile.readAsLinesSync().length;
  print('  Original: $origLines lines');
  print('  Cleaned:  $lineCount lines');
  if (lineCount < origLines) {
    print('  Reduced by: ${origLines - lineCount} lines (${((origLines - lineCount) / origLines * 100).toStringAsFixed(1)}%)');
  } else {
    print('  Note: Cleaned file is larger due to FIXME comments');
  }

  print('\nNext steps:');
  print('  1. Review lib/data/factory_presets_clean.dart');
  print('  2. Run flutter analyze to verify syntax');
  print('  3. Replace original: mv lib/data/factory_presets_clean.dart lib/data/factory_presets.dart');
  print('  4. Bump factoryPresetVersion in the file');
  print('  5. Build and test');
}
