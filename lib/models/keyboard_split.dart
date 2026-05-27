import 'preset_category.dart';
import 'synth_preset.dart';

/// Configuration for splitting the keyboard into two zones.
class KeyboardSplit {
  /// The MIDI note where the split occurs (zone A = notes < splitPoint, zone B >= splitPoint).
  final int splitPoint;

  /// Volume for zone A (0.0 - 1.0).
  final double volumeA;

  /// Volume for zone B (0.0 - 1.0).
  final double volumeB;

  /// Whether split mode is active.
  final bool enabled;

  /// The preset assigned to zone A (left side).
  final SynthPreset presetA;

  /// The preset assigned to zone B (right side).
  final SynthPreset presetB;

  KeyboardSplit({
    this.splitPoint = 60, // C4
    this.volumeA = 1.0,
    this.volumeB = 1.0,
    this.enabled = false,
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

  KeyboardSplit copyWith({
    int? splitPoint,
    double? volumeA,
    double? volumeB,
    bool? enabled,
    SynthPreset? presetA,
    SynthPreset? presetB,
  }) {
    return KeyboardSplit(
      splitPoint: splitPoint ?? this.splitPoint,
      volumeA: volumeA ?? this.volumeA,
      volumeB: volumeB ?? this.volumeB,
      enabled: enabled ?? this.enabled,
      presetA: presetA ?? this.presetA,
      presetB: presetB ?? this.presetB,
    );
  }

  /// Which zone a MIDI note falls into. Returns 0 for zone A, 1 for zone B.
  /// Returns -1 if split is disabled.
  int zoneForNote(int midiNote) {
    if (!enabled) return -1;
    return midiNote < splitPoint ? 0 : 1;
  }

  Map<String, dynamic> toJson() => {
        'splitPoint': splitPoint,
        'volumeA': volumeA,
        'volumeB': volumeB,
        'enabled': enabled,
        'presetA': presetA.toJson(),
        'presetB': presetB.toJson(),
      };

  factory KeyboardSplit.fromJson(Map<String, dynamic> json) => KeyboardSplit(
        splitPoint: json['splitPoint'] as int? ?? 60,
        volumeA: (json['volumeA'] as num?)?.toDouble() ?? 1.0,
        volumeB: (json['volumeB'] as num?)?.toDouble() ?? 1.0,
        enabled: json['enabled'] as bool? ?? false,
        presetA: json['presetA'] != null
            ? SynthPreset.fromJson(json['presetA'] as Map<String, dynamic>)
            : _defaultPresetA,
        presetB: json['presetB'] != null
            ? SynthPreset.fromJson(json['presetB'] as Map<String, dynamic>)
            : _defaultPresetB,
      );
}
