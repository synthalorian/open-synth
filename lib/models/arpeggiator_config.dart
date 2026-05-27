enum ArpPattern {
  off('Off'),
  up('Up'),
  down('Down'),
  upDown('Up / Down'),
  random('Random'),
  chord('Chord');

  const ArpPattern(this.displayName);
  final String displayName;
}

enum ArpRate {
  one4th('1/4', 0.25),
  one8th('1/8', 0.125),
  one8thT('1/8T', 0.125 / 3 * 2),
  one16th('1/16', 0.0625),
  one16thT('1/16T', 0.0625 / 3 * 2),
  one32nd('1/32', 0.03125);

  const ArpRate(this.displayName, this.noteDuration);
  final String displayName;
  final double noteDuration;
}

class ArpeggiatorConfig {
  final ArpPattern pattern;
  final ArpRate rate;
  final int octaveRange; // 1 to 4
  final bool enabled;
  final double gateVariation; // 0.0 = strict, 1.0 = wild gate swings
  final double probSkip; // 0.0 = no skips, 1.0 = every note can skip
  final bool octaveJump; // true = allow octave jumps within the sequence
  final int seed; // random seed for deterministic variations

  const ArpeggiatorConfig({
    this.pattern = ArpPattern.off,
    this.rate = ArpRate.one16th,
    this.octaveRange = 1,
    this.enabled = false,
    this.gateVariation = 0.0,
    this.probSkip = 0.0,
    this.octaveJump = false,
    this.seed = 0,
  });

  ArpeggiatorConfig copyWith({
    ArpPattern? pattern,
    ArpRate? rate,
    int? octaveRange,
    bool? enabled,
    double? gateVariation,
    double? probSkip,
    bool? octaveJump,
    int? seed,
  }) {
    return ArpeggiatorConfig(
      pattern: pattern ?? this.pattern,
      rate: rate ?? this.rate,
      octaveRange: octaveRange ?? this.octaveRange,
      enabled: enabled ?? this.enabled,
      gateVariation: gateVariation ?? this.gateVariation,
      probSkip: probSkip ?? this.probSkip,
      octaveJump: octaveJump ?? this.octaveJump,
      seed: seed ?? this.seed,
    );
  }

  Map<String, dynamic> toJson() => {
        'pattern': pattern.index,
        'rate': rate.index,
        'octaveRange': octaveRange,
        'enabled': enabled,
        'gateVariation': gateVariation,
        'probSkip': probSkip,
        'octaveJump': octaveJump,
        'seed': seed,
      };

  factory ArpeggiatorConfig.fromJson(Map<String, dynamic> json) =>
      ArpeggiatorConfig(
        pattern: ArpPattern.values[json['pattern'] as int? ?? 0],
        rate: ArpRate.values[json['rate'] as int? ?? 3],
        octaveRange: json['octaveRange'] as int? ?? 1,
        enabled: json['enabled'] as bool? ?? false,
        gateVariation: (json['gateVariation'] as num?)?.toDouble() ?? 0.0,
        probSkip: (json['probSkip'] as num?)?.toDouble() ?? 0.0,
        octaveJump: json['octaveJump'] as bool? ?? false,
        seed: json['seed'] as int? ?? 0,
      );
}
