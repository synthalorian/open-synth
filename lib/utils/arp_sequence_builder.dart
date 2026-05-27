import 'dart:math';

import '../models/arpeggiator_config.dart';

/// Builds the MIDI note sequence for an arpeggiator pattern.
///
/// Pure function — no side effects, no timers. Easy to unit-test.
List<int> buildArpSequence({
  required Set<int> heldNotes,
  required ArpPattern pattern,
  required int octaveRange,
  Random? random,
  double probSkip = 0.0,
  bool octaveJump = false,
}) {
  final sorted = heldNotes.toList()..sort();
  if (sorted.isEmpty) return [];

  final sequence = <int>[];
  final rng = random ?? Random();

  for (int oct = 0; oct < octaveRange; oct++) {
    final octaveShift = oct * 12;
    switch (pattern) {
      case ArpPattern.off:
        return sorted;
      case ArpPattern.up:
        sequence.addAll(sorted.map((n) => n + octaveShift));
        break;
      case ArpPattern.down:
        sequence.addAll(sorted.reversed.map((n) => n + octaveShift));
        break;
      case ArpPattern.upDown:
        sequence.addAll(sorted.map((n) => n + octaveShift));
        if (sorted.length > 1) {
          sequence.addAll(
            sorted.reversed.skip(1).take(sorted.length - 1).map((n) => n + octaveShift),
          );
        }
        break;
      case ArpPattern.random:
        final octaveNotes = sorted.map((n) => n + octaveShift).toList();
        sequence.addAll(octaveNotes);
        break;
      case ArpPattern.chord:
        sequence.addAll(sorted.map((n) => n + octaveShift));
        break;
    }
  }

  if (pattern == ArpPattern.random) {
    sequence.shuffle(rng);
  }

  // Apply octave jumps within the sequence
  if (octaveJump && sequence.length > 1) {
    final jumped = <int>[];
    for (final note in sequence) {
      if (rng.nextBool() && octaveRange > 1) {
        final jump = rng.nextBool() ? 12 : -12;
        jumped.add((note + jump).clamp(0, 127));
      } else {
        jumped.add(note);
      }
    }
    return jumped;
  }

  // Apply probabilistic note skipping
  if (probSkip > 0.0) {
    return sequence.where((_) => rng.nextDouble() >= probSkip).toList();
  }

  return sequence;
}
