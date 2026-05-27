import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_synth/models/arpeggiator_config.dart';
import 'package:open_synth/utils/arp_sequence_builder.dart';

void main() {
  group('buildArpSequence - basic patterns', () {
    const heldNotes = {60, 64, 67}; // C major triad

    test('off pattern returns held notes unsorted', () {
      final seq = buildArpSequence(
        heldNotes: heldNotes,
        pattern: ArpPattern.off,
        octaveRange: 1,
      );
      expect(seq, [60, 64, 67]);
    });

    test('up pattern sorts ascending', () {
      final seq = buildArpSequence(
        heldNotes: {67, 60, 64},
        pattern: ArpPattern.up,
        octaveRange: 1,
      );
      expect(seq, [60, 64, 67]);
    });

    test('down pattern sorts descending', () {
      final seq = buildArpSequence(
        heldNotes: heldNotes,
        pattern: ArpPattern.down,
        octaveRange: 1,
      );
      expect(seq, [67, 64, 60]);
    });

    test('upDown pattern traverses up then down', () {
      final seq = buildArpSequence(
        heldNotes: heldNotes,
        pattern: ArpPattern.upDown,
        octaveRange: 1,
      );
      // up: [60, 64, 67], then down skipping first endpoint: [64, 60]
      expect(seq, [60, 64, 67, 64, 60]);
    });

    test('upDown with single note does not skip', () {
      final seq = buildArpSequence(
        heldNotes: {60},
        pattern: ArpPattern.upDown,
        octaveRange: 1,
      );
      expect(seq, [60]);
    });

    test('chord pattern returns all notes each octave', () {
      final seq = buildArpSequence(
        heldNotes: heldNotes,
        pattern: ArpPattern.chord,
        octaveRange: 2,
      );
      expect(seq, [60, 64, 67, 72, 76, 79]);
    });

    test('up pattern spans octaves correctly', () {
      final seq = buildArpSequence(
        heldNotes: heldNotes,
        pattern: ArpPattern.up,
        octaveRange: 2,
      );
      expect(seq, [60, 64, 67, 72, 76, 79]);
    });
  });

  group('buildArpSequence - randomization', () {
    const heldNotes = {60, 64, 67};

    test('random pattern with seed is reproducible', () {
      final rng1 = Random(42);
      final seq1 = buildArpSequence(
        heldNotes: heldNotes,
        pattern: ArpPattern.random,
        octaveRange: 1,
        random: rng1,
      );

      final rng2 = Random(42);
      final seq2 = buildArpSequence(
        heldNotes: heldNotes,
        pattern: ArpPattern.random,
        octaveRange: 1,
        random: rng2,
      );

      expect(seq1, seq2);
      // Should still contain all three notes
      expect(seq1.toSet(), heldNotes);
    });

    test('probSkip=0.0 keeps all notes', () {
      final seq = buildArpSequence(
        heldNotes: heldNotes,
        pattern: ArpPattern.up,
        octaveRange: 2,
        probSkip: 0.0,
      );
      expect(seq.length, 6);
    });

    test('probSkip=1.0 removes all notes', () {
      final seq = buildArpSequence(
        heldNotes: heldNotes,
        pattern: ArpPattern.up,
        octaveRange: 1,
        probSkip: 1.0,
        random: Random(1),
      );
      expect(seq, isEmpty);
    });

    test('probSkip filters probabilistically with seeded RNG', () {
      final rng = Random(123);
      final seq = buildArpSequence(
        heldNotes: heldNotes,
        pattern: ArpPattern.up,
        octaveRange: 3,
        probSkip: 0.3,
        random: rng,
      );
      // With 9 notes and 30% skip probability, expect some filtering
      expect(seq.length, lessThanOrEqualTo(9));
      expect(seq.length, greaterThanOrEqualTo(0));
      // All remaining notes must be from the original set (modulo octave)
      for (final note in seq) {
        expect([60, 64, 67, 72, 76, 79, 84, 88, 91].contains(note), isTrue);
      }
    });

    test('octaveJump shifts notes by ±12 when enabled', () {
      final rng = Random(7);
      final seq = buildArpSequence(
        heldNotes: heldNotes,
        pattern: ArpPattern.up,
        octaveRange: 2,
        octaveJump: true,
        random: rng,
      );

      // At least some notes should be different from the base sequence
      final base = buildArpSequence(
        heldNotes: heldNotes,
        pattern: ArpPattern.up,
        octaveRange: 2,
      );
      expect(seq, isNot(equals(base)));

      // All notes must stay in valid MIDI range
      for (final note in seq) {
        expect(note, greaterThanOrEqualTo(0));
        expect(note, lessThanOrEqualTo(127));
      }
    });

    test('octaveJump respects MIDI bounds', () {
      final rng = Random(99);
      final seq = buildArpSequence(
        heldNotes: {120, 124, 127},
        pattern: ArpPattern.up,
        octaveRange: 1,
        octaveJump: true,
        random: rng,
      );
      for (final note in seq) {
        expect(note, greaterThanOrEqualTo(0));
        expect(note, lessThanOrEqualTo(127));
      }
    });

    test('octaveJump with single note is a no-op', () {
      final seq = buildArpSequence(
        heldNotes: {60},
        pattern: ArpPattern.up,
        octaveRange: 1,
        octaveJump: true,
        random: Random(1),
      );
      expect(seq, [60]);
    });
  });

  group('buildArpSequence - edge cases', () {
    test('empty heldNotes returns empty list', () {
      final seq = buildArpSequence(
        heldNotes: {},
        pattern: ArpPattern.up,
        octaveRange: 2,
      );
      expect(seq, isEmpty);
    });

    test('off pattern with empty notes returns empty', () {
      final seq = buildArpSequence(
        heldNotes: {},
        pattern: ArpPattern.off,
        octaveRange: 1,
      );
      expect(seq, isEmpty);
    });
  });
}
