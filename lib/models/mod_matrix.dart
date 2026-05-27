/// Sources that can drive modulation.
enum ModSource {
  lfo1('LFO 1'),
  lfo2('LFO 2'),
  filterEnv('Filter Env'),
  ampEnv('Amp Env'),
  velocity('Velocity'),
  modWheel('Mod Wheel'),
  aftertouch('Aftertouch'),
  keyTrack('Key Track'),
  macro1('Macro 1'),
  macro2('Macro 2'),
  macro3('Macro 3'),
  macro4('Macro 4');

  const ModSource(this.displayName);
  final String displayName;
}

/// Destinations that can receive modulation.
enum ModDestination {
  pitch('Pitch', -24.0, 24.0), // semitones
  filterCutoff('Filter Cutoff', -8000.0, 8000.0), // Hz offset
  filterResonance('Filter Resonance', -0.5, 0.5),
  amplitude('Amplitude', -1.0, 1.0),
  pan('Pan', -1.0, 1.0),
  osc2Detune('OSC2 Detune', -50.0, 50.0), // cents
  lfo1Rate('LFO 1 Rate', -5.0, 5.0),
  lfo2Rate('LFO 2 Rate', -5.0, 5.0),
  masterVolume('Master Volume', -0.5, 0.5);

  const ModDestination(this.displayName, this.minAmount, this.maxAmount);
  final String displayName;
  final double minAmount;
  final double maxAmount;
}

/// One routing slot in the modulation matrix.
class ModMatrixSlot {
  final ModSource source;
  final ModDestination destination;
  final double amount; // -1.0 to 1.0 (scaled to destination range)
  final bool enabled;
  final bool bipolar; // if true, amount is ±; if false, only +

  const ModMatrixSlot({
    required this.source,
    required this.destination,
    this.amount = 0.0,
    this.enabled = true,
    this.bipolar = true,
  });

  ModMatrixSlot copyWith({
    ModSource? source,
    ModDestination? destination,
    double? amount,
    bool? enabled,
    bool? bipolar,
  }) {
    return ModMatrixSlot(
      source: source ?? this.source,
      destination: destination ?? this.destination,
      amount: amount ?? this.amount,
      enabled: enabled ?? this.enabled,
      bipolar: bipolar ?? this.bipolar,
    );
  }

  /// Returns the actual modulation value scaled to destination range.
  double computeValue(double sourceValue) {
    if (!enabled) return 0.0;
    final scaled = amount * sourceValue;
    final range = destination.maxAmount - destination.minAmount;
    final offset = destination.minAmount + range * 0.5;
    return scaled * range * 0.5 + offset;
  }

  Map<String, dynamic> toJson() => {
        'source': source.index,
        'destination': destination.index,
        'amount': amount,
        'enabled': enabled,
        'bipolar': bipolar,
      };

  factory ModMatrixSlot.fromJson(Map<String, dynamic> json) => ModMatrixSlot(
        source: ModSource.values[json['source'] as int],
        destination: ModDestination.values[json['destination'] as int],
        amount: (json['amount'] as num).toDouble(),
        enabled: json['enabled'] as bool? ?? true,
        bipolar: json['bipolar'] as bool? ?? true,
      );
}

/// Full modulation matrix with 8 assignable slots.
class ModMatrix {
  final List<ModMatrixSlot> slots;

  ModMatrix({List<ModMatrixSlot>? slots})
      : slots = slots ?? List.generate(8, (_) => const ModMatrixSlot(
            source: ModSource.lfo1,
            destination: ModDestination.pitch,
            amount: 0.0,
            enabled: false,
          ));

  ModMatrix copyWith({List<ModMatrixSlot>? slots}) {
    return ModMatrix(slots: slots ?? List.from(this.slots));
  }

  Map<String, dynamic> toJson() => {
        'slots': slots.map((s) => s.toJson()).toList(),
      };

  factory ModMatrix.fromJson(Map<String, dynamic> json) => ModMatrix(
        slots: (json['slots'] as List)
            .map((e) => ModMatrixSlot.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
