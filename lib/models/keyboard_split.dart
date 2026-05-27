import 'preset_category.dart';
import 'synth_preset.dart';

/// Mode for the keyboard split/layer system.
enum SplitMode {
  /// Normal single-zone mode.
  normal,

  /// Split keyboard into two zones at splitPoint.
  split,

  /// Layer both presets across the full keyboard range.
  layer,
}

/// Configuration for splitting or layering the keyboard.
class KeyboardSplit {
  /// The MIDI note where the split occurs (zone A = notes < splitPoint, zone B >= splitPoint).
  final int splitPoint;

  /// Volume for zone A (0.0 - 1.0).
  final double volumeA;

  /// Volume for zone B (0.0 - 1.0).
  final double volumeB;

  /// Octave shift for zone A (-2 to +2).
  final int octaveShiftA;

  /// Octave shift for zone B (-2 to +2).
  final int octaveShiftB;

  /// Crossfade width in semitones around the split point (0 = hard split).
  final int crossfadeWidth;

  /// Current mode: normal, split, or layer.
  final SplitMode mode;

  /// The preset assigned to zone A (left side / layer A).
  final SynthPreset presetA;

  /// The preset assigned to zone B (right side / layer B).
  final SynthPreset presetB;

  KeyboardSplit({
    this.splitPoint = 60, // C4
    this.volumeA = 1.0,
    this.volumeB = 1.0,
    this.octaveShiftA = 0,
    this.octaveShiftB = 0,
    this.crossfadeWidth = 0,
    this.mode = SplitMode.normal,
    SynthPreset? presetA,
    SynthPreset? presetB,
  }) : presetA = presetA ?? _defaultPresetA,
       presetB = presetB ?? _defaultPresetB;

  static final _defaultPresetA = SynthPreset(
    name: 'Zone A',
    category: PresetCategory.custom,
    author: 'split',
  );

  static final _defaultPresetB = SynthPreset(
    name: 'Zone B',
    category: PresetCategory.custom,
    author: 'split',
  );

  bool get enabled => mode != SplitMode.normal;

  KeyboardSplit copyWith({
    int? splitPoint,
    double? volumeA,
    double? volumeB,
    int? octaveShiftA,
    int? octaveShiftB,
    int? crossfadeWidth,
    SplitMode? mode,
    SynthPreset? presetA,
    SynthPreset? presetB,
  }) {
    return KeyboardSplit(
      splitPoint: splitPoint ?? this.splitPoint,
      volumeA: volumeA ?? this.volumeA,
      volumeB: volumeB ?? this.volumeB,
      octaveShiftA: octaveShiftA ?? this.octaveShiftA,
      octaveShiftB: octaveShiftB ?? this.octaveShiftB,
      crossfadeWidth: crossfadeWidth ?? this.crossfadeWidth,
      mode: mode ?? this.mode,
      presetA: presetA ?? this.presetA,
      presetB: presetB ?? this.presetB,
    );
  }

  /// Returns the primary zone for a MIDI note (0 = A, 1 = B, -1 = none).
  /// Used for simple routing when only one zone should receive the note.
  int zoneForNote(int midiNote) {
    switch (mode) {
      case SplitMode.normal:
        return 0;
      case SplitMode.split:
        return midiNote < splitPoint ? 0 : 1;
      case SplitMode.layer:
        return 0; // Layer mode notes go to zone A primary; use zonesForNote for both
    }
  }

  /// Which zones a MIDI note should trigger.
  /// Returns a list of zone indices (0 for A, 1 for B).
  List<int> zonesForNote(int midiNote) {
    switch (mode) {
      case SplitMode.normal:
        return [0];
      case SplitMode.split:
        if (crossfadeWidth <= 0) {
          return midiNote < splitPoint ? [0] : [1];
        }
        // Crossfade zone: both zones play in the crossfade region
        final lowerBound = splitPoint - crossfadeWidth;
        final upperBound = splitPoint + crossfadeWidth;
        if (midiNote < lowerBound) return [0];
        if (midiNote >= upperBound) return [1];
        // In crossfade region, both zones play
        return [0, 1];
      case SplitMode.layer:
        return [0, 1];
    }
  }

  /// Compute the volume multiplier for a note in a given zone.
  /// Handles crossfade attenuation in the overlap region.
  double volumeForNoteInZone(int midiNote, int zone) {
    final baseVol = zone == 0 ? volumeA : volumeB;
    if (mode != SplitMode.split || crossfadeWidth <= 0) return baseVol;

    final lowerBound = splitPoint - crossfadeWidth;
    final upperBound = splitPoint + crossfadeWidth;

    if (midiNote < lowerBound) return zone == 0 ? baseVol : 0.0;
    if (midiNote >= upperBound) return zone == 1 ? baseVol : 0.0;

    // Linear crossfade in overlap region
    final t = (midiNote - lowerBound) / (crossfadeWidth * 2);
    if (zone == 0) return baseVol * (1.0 - t);
    return baseVol * t;
  }

  /// Returns the octave-shifted MIDI note for a zone.
  int shiftedNote(int midiNote, int zone) {
    final shift = zone == 0 ? octaveShiftA : octaveShiftB;
    return (midiNote + shift * 12).clamp(0, 127);
  }

  Map<String, dynamic> toJson() => {
        'splitPoint': splitPoint,
        'volumeA': volumeA,
        'volumeB': volumeB,
        'octaveShiftA': octaveShiftA,
        'octaveShiftB': octaveShiftB,
        'crossfadeWidth': crossfadeWidth,
        'mode': mode.index,
        'presetA': presetA.toJson(),
        'presetB': presetB.toJson(),
      };

  factory KeyboardSplit.fromJson(Map<String, dynamic> json) => KeyboardSplit(
        splitPoint: json['splitPoint'] as int? ?? 60,
        volumeA: (json['volumeA'] as num?)?.toDouble() ?? 1.0,
        volumeB: (json['volumeB'] as num?)?.toDouble() ?? 1.0,
        octaveShiftA: json['octaveShiftA'] as int? ?? 0,
        octaveShiftB: json['octaveShiftB'] as int? ?? 0,
        crossfadeWidth: json['crossfadeWidth'] as int? ?? 0,
        mode: SplitMode.values[json['mode'] as int? ?? 0],
        presetA: json['presetA'] != null
            ? SynthPreset.fromJson(json['presetA'] as Map<String, dynamic>)
            : _defaultPresetA,
        presetB: json['presetB'] != null
            ? SynthPreset.fromJson(json['presetB'] as Map<String, dynamic>)
            : _defaultPresetB,
      );
}
