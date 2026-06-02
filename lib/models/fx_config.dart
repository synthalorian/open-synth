enum DriveType {
  overdrive,
  fuzz,
  tube,
  hardClip,
  bitCrusher,
}

class ChorusConfig {
  final bool enabled;
  final double rate;
  final double depth;
  final double mix;

  const ChorusConfig({
    this.enabled = false,
    this.rate = 1.5,
    this.depth = 0.5,
    this.mix = 0.5,
  });

  ChorusConfig copyWith({
    bool? enabled,
    double? rate,
    double? depth,
    double? mix,
  }) {
    return ChorusConfig(
      enabled: enabled ?? this.enabled,
      rate: rate ?? this.rate,
      depth: depth ?? this.depth,
      mix: mix ?? this.mix,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'rate': rate,
        'depth': depth,
        'mix': mix,
      };

  factory ChorusConfig.fromJson(Map<String, dynamic> json) => ChorusConfig(
        enabled: json['enabled'] as bool? ?? false,
        rate: (json['rate'] as num? ?? 1.5).toDouble(),
        depth: (json['depth'] as num? ?? 0.5).toDouble(),
        mix: (json['mix'] as num? ?? 0.5).toDouble(),
      );
}

class DelayConfig {
  final bool enabled;
  final double timeMs;
  final double feedback;
  final double mix;

  const DelayConfig({
    this.enabled = false,
    this.timeMs = 350.0,
    this.feedback = 0.35,
    this.mix = 0.25,
  });

  DelayConfig copyWith({
    bool? enabled,
    double? timeMs,
    double? feedback,
    double? mix,
  }) {
    return DelayConfig(
      enabled: enabled ?? this.enabled,
      timeMs: timeMs ?? this.timeMs,
      feedback: feedback ?? this.feedback,
      mix: mix ?? this.mix,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'timeMs': timeMs,
        'feedback': feedback,
        'mix': mix,
      };

  factory DelayConfig.fromJson(Map<String, dynamic> json) => DelayConfig(
        enabled: json['enabled'] as bool? ?? false,
        timeMs: (json['timeMs'] as num? ?? 350.0).toDouble(),
        feedback: (json['feedback'] as num? ?? 0.35).toDouble(),
        mix: (json['mix'] as num? ?? 0.25).toDouble(),
      );
}

class ReverbConfig {
  final bool enabled;
  final double size;
  final double damping;
  final double mix;

  const ReverbConfig({
    this.enabled = false,
    this.size = 0.7,
    this.damping = 0.5,
    this.mix = 0.3,
  });

  ReverbConfig copyWith({
    bool? enabled,
    double? size,
    double? damping,
    double? mix,
  }) {
    return ReverbConfig(
      enabled: enabled ?? this.enabled,
      size: size ?? this.size,
      damping: damping ?? this.damping,
      mix: mix ?? this.mix,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'size': size,
        'damping': damping,
        'mix': mix,
      };

  factory ReverbConfig.fromJson(Map<String, dynamic> json) => ReverbConfig(
        enabled: json['enabled'] as bool? ?? false,
        size: (json['size'] as num? ?? 0.7).toDouble(),
        damping: (json['damping'] as num? ?? 0.5).toDouble(),
        mix: (json['mix'] as num? ?? 0.3).toDouble(),
      );
}

class PhaserConfig {
  final bool enabled;
  final double rate;
  final double depth;
  final double feedback;
  final double mix;

  const PhaserConfig({
    this.enabled = false,
    this.rate = 0.5,
    this.depth = 0.5,
    this.feedback = 0.7,
    this.mix = 0.5,
  });

  PhaserConfig copyWith({
    bool? enabled,
    double? rate,
    double? depth,
    double? feedback,
    double? mix,
  }) {
    return PhaserConfig(
      enabled: enabled ?? this.enabled,
      rate: rate ?? this.rate,
      depth: depth ?? this.depth,
      feedback: feedback ?? this.feedback,
      mix: mix ?? this.mix,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'rate': rate,
        'depth': depth,
        'feedback': feedback,
        'mix': mix,
      };

  factory PhaserConfig.fromJson(Map<String, dynamic> json) => PhaserConfig(
        enabled: json['enabled'] as bool? ?? false,
        rate: (json['rate'] as num? ?? 0.5).toDouble(),
        depth: (json['depth'] as num? ?? 0.5).toDouble(),
        feedback: (json['feedback'] as num? ?? 0.7).toDouble(),
        mix: (json['mix'] as num? ?? 0.5).toDouble(),
      );
}

class FlangerConfig {
  final bool enabled;
  final double rate;
  final double depth;
  final double feedback;
  final double mix;

  const FlangerConfig({
    this.enabled = false,
    this.rate = 0.3,
    this.depth = 0.6,
    this.feedback = 0.4,
    this.mix = 0.5,
  });

  FlangerConfig copyWith({
    bool? enabled,
    double? rate,
    double? depth,
    double? feedback,
    double? mix,
  }) {
    return FlangerConfig(
      enabled: enabled ?? this.enabled,
      rate: rate ?? this.rate,
      depth: depth ?? this.depth,
      feedback: feedback ?? this.feedback,
      mix: mix ?? this.mix,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'rate': rate,
        'depth': depth,
        'feedback': feedback,
        'mix': mix,
      };

  factory FlangerConfig.fromJson(Map<String, dynamic> json) => FlangerConfig(
        enabled: json['enabled'] as bool? ?? false,
        rate: (json['rate'] as num? ?? 0.3).toDouble(),
        depth: (json['depth'] as num? ?? 0.6).toDouble(),
        feedback: (json['feedback'] as num? ?? 0.4).toDouble(),
        mix: (json['mix'] as num? ?? 0.5).toDouble(),
      );
}

class CompressorConfig {
  final bool enabled;
  final double threshold;
  final double ratio;
  final double attack;
  final double release;
  final double makeupGain;

  const CompressorConfig({
    this.enabled = false,
    this.threshold = 0.5,
    this.ratio = 4.0,
    this.attack = 10.0,
    this.release = 100.0,
    this.makeupGain = 0.0,
  });

  CompressorConfig copyWith({
    bool? enabled,
    double? threshold,
    double? ratio,
    double? attack,
    double? release,
    double? makeupGain,
  }) {
    return CompressorConfig(
      enabled: enabled ?? this.enabled,
      threshold: threshold ?? this.threshold,
      ratio: ratio ?? this.ratio,
      attack: attack ?? this.attack,
      release: release ?? this.release,
      makeupGain: makeupGain ?? this.makeupGain,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'threshold': threshold,
        'ratio': ratio,
        'attack': attack,
        'release': release,
        'makeupGain': makeupGain,
      };

  factory CompressorConfig.fromJson(Map<String, dynamic> json) => CompressorConfig(
        enabled: json['enabled'] as bool? ?? false,
        threshold: (json['threshold'] as num? ?? 0.5).toDouble(),
        ratio: (json['ratio'] as num? ?? 4.0).toDouble(),
        attack: (json['attack'] as num? ?? 10.0).toDouble(),
        release: (json['release'] as num? ?? 100.0).toDouble(),
        makeupGain: (json['makeupGain'] as num? ?? 0.0).toDouble(),
      );
}

// ── New FX Types for Multi-Slot Architecture ──────────────────────────────

/// FX processor type IDs matching FxType enum in fx_engine.h
class FxTypeId {
  static const int none = 0;
  static const int chorus = 1;
  static const int delay = 2;
  static const int reverb = 3;
  static const int phaser = 4;
  static const int flanger = 5;
  static const int compressor = 6;
  static const int drive = 7;
  static const int equalizer = 8;
  static const int limiter = 9;
  static const int rotary = 10;
  static const int tremolo = 11;
  // Phase 5: MFX Expansion
  static const int autoWah = 12;
  static const int bitcrusher = 13;
  static const int ringMod = 14;
  static const int pitchShift = 15;
  static const int multitapDelay = 16;
  static const int pingPongDelay = 17;
  static const int springReverb = 18;
  static const int gatedReverb = 19;
  static const int ampSimulator = 20;
  static const int stereoWidener = 21;

  static const Map<int, String> names = {
    none: 'None',
    chorus: 'Chorus',
    delay: 'Delay',
    reverb: 'Reverb',
    phaser: 'Phaser',
    flanger: 'Flanger',
    compressor: 'Compressor',
    drive: 'Drive',
    equalizer: 'EQ',
    limiter: 'Limiter',
    rotary: 'Rotary',
    tremolo: 'Tremolo',
    // Phase 5
    autoWah: 'Auto-Wah',
    bitcrusher: 'Bitcrusher',
    ringMod: 'Ring Mod',
    pitchShift: 'Pitch Shift',
    multitapDelay: 'Multi-tap Delay',
    pingPongDelay: 'Ping-Pong Delay',
    springReverb: 'Spring Reverb',
    gatedReverb: 'Gated Reverb',
    ampSimulator: 'Amp Simulator',
    stereoWidener: 'Stereo Widener',
  };

  static String name(int id) => names[id] ?? 'Unknown';
}

/// Configuration for a multi-FX slot. Each slot holds an FX type
/// and its parameters. Slots are processed in series.
class FxSlotConfig {
  final int type; // FxTypeId value
  final bool enabled;
  final List<double> params;

  const FxSlotConfig({
    this.type = FxTypeId.none,
    this.enabled = false,
    this.params = const [],
  });

  FxSlotConfig copyWith({
    int? type,
    bool? enabled,
    List<double>? params,
  }) {
    return FxSlotConfig(
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      params: params ?? this.params,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'enabled': enabled,
        'params': params,
      };

  factory FxSlotConfig.fromJson(Map<String, dynamic> json) => FxSlotConfig(
        type: json['type'] as int? ?? FxTypeId.none,
        enabled: json['enabled'] as bool? ?? false,
        params: (json['params'] as List? ?? [])
            .map((e) => (e as num).toDouble())
            .toList(),
      );

  /// Get a param by index, or defaultValue if out of range.
  double param(int index, double defaultValue) =>
      index < params.length ? params[index] : defaultValue;
}

/// 3-band parametric EQ config.
class EqConfig {
  final bool enabled;
  final double lowGain; // -12 to +12 dB
  final double lowFreq; // 20-500 Hz
  final double midGain; // -12 to +12 dB
  final double midFreq; // 200-5000 Hz
  final double midQ; // 0.1-10
  final double highGain; // -12 to +12 dB
  final double highFreq; // 1000-20000 Hz

  const EqConfig({
    this.enabled = false,
    this.lowGain = 0.0,
    this.lowFreq = 200.0,
    this.midGain = 0.0,
    this.midFreq = 1000.0,
    this.midQ = 1.0,
    this.highGain = 0.0,
    this.highFreq = 8000.0,
  });

  EqConfig copyWith({
    bool? enabled,
    double? lowGain,
    double? lowFreq,
    double? midGain,
    double? midFreq,
    double? midQ,
    double? highGain,
    double? highFreq,
  }) {
    return EqConfig(
      enabled: enabled ?? this.enabled,
      lowGain: lowGain ?? this.lowGain,
      lowFreq: lowFreq ?? this.lowFreq,
      midGain: midGain ?? this.midGain,
      midFreq: midFreq ?? this.midFreq,
      midQ: midQ ?? this.midQ,
      highGain: highGain ?? this.highGain,
      highFreq: highFreq ?? this.highFreq,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'lowGain': lowGain,
        'lowFreq': lowFreq,
        'midGain': midGain,
        'midFreq': midFreq,
        'midQ': midQ,
        'highGain': highGain,
        'highFreq': highFreq,
      };

  factory EqConfig.fromJson(Map<String, dynamic> json) => EqConfig(
        enabled: json['enabled'] as bool? ?? false,
        lowGain: (json['lowGain'] as num? ?? 0.0).toDouble(),
        lowFreq: (json['lowFreq'] as num? ?? 200.0).toDouble(),
        midGain: (json['midGain'] as num? ?? 0.0).toDouble(),
        midFreq: (json['midFreq'] as num? ?? 1000.0).toDouble(),
        midQ: (json['midQ'] as num? ?? 1.0).toDouble(),
        highGain: (json['highGain'] as num? ?? 0.0).toDouble(),
        highFreq: (json['highFreq'] as num? ?? 8000.0).toDouble(),
      );
}

/// Limiter config with lookahead, attack/release, threshold, and makeup gain.
class LimiterConfig {
  final bool enabled;
  final double threshold; // -60 to 0 dB
  final double attack; // 0.01 to 10 ms
  final double release; // 10 to 500 ms
  final double makeupGain; // 0 to 24 dB
  final double lookahead; // 0 to 5 ms

  const LimiterConfig({
    this.enabled = false,
    this.threshold = -6.0,
    this.attack = 1.0,
    this.release = 50.0,
    this.makeupGain = 0.0,
    this.lookahead = 1.0,
  });

  LimiterConfig copyWith({
    bool? enabled,
    double? threshold,
    double? attack,
    double? release,
    double? makeupGain,
    double? lookahead,
  }) {
    return LimiterConfig(
      enabled: enabled ?? this.enabled,
      threshold: threshold ?? this.threshold,
      attack: attack ?? this.attack,
      release: release ?? this.release,
      makeupGain: makeupGain ?? this.makeupGain,
      lookahead: lookahead ?? this.lookahead,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'threshold': threshold,
        'attack': attack,
        'release': release,
        'makeupGain': makeupGain,
        'lookahead': lookahead,
      };

  factory LimiterConfig.fromJson(Map<String, dynamic> json) => LimiterConfig(
        enabled: json['enabled'] as bool? ?? false,
        threshold: (json['threshold'] as num? ?? -6.0).toDouble(),
        attack: (json['attack'] as num? ?? 1.0).toDouble(),
        release: (json['release'] as num? ?? 50.0).toDouble(),
        makeupGain: (json['makeupGain'] as num? ?? 0.0).toDouble(),
        lookahead: (json['lookahead'] as num? ?? 1.0).toDouble(),
      );
}

/// Rotary speaker (Leslie) config.
class RotaryConfig {
  final bool enabled;
  final double rate; // 0.1 to 20 Hz
  final double depth; // 0 to 1
  final double drive; // 0 to 1
  final double mix; // 0 to 1
  final int mode; // 0=slow, 1=fast, 2=brake

  const RotaryConfig({
    this.enabled = false,
    this.rate = 6.0,
    this.depth = 0.7,
    this.drive = 0.3,
    this.mix = 0.5,
    this.mode = 0,
  });

  RotaryConfig copyWith({
    bool? enabled,
    double? rate,
    double? depth,
    double? drive,
    double? mix,
    int? mode,
  }) {
    return RotaryConfig(
      enabled: enabled ?? this.enabled,
      rate: rate ?? this.rate,
      depth: depth ?? this.depth,
      drive: drive ?? this.drive,
      mix: mix ?? this.mix,
      mode: mode ?? this.mode,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'rate': rate,
        'depth': depth,
        'drive': drive,
        'mix': mix,
        'mode': mode,
      };

  factory RotaryConfig.fromJson(Map<String, dynamic> json) => RotaryConfig(
        enabled: json['enabled'] as bool? ?? false,
        rate: (json['rate'] as num? ?? 6.0).toDouble(),
        depth: (json['depth'] as num? ?? 0.7).toDouble(),
        drive: (json['drive'] as num? ?? 0.3).toDouble(),
        mix: (json['mix'] as num? ?? 0.5).toDouble(),
        mode: json['mode'] as int? ?? 0,
      );
}

/// Tremolo config.
class TremoloConfig {
  final bool enabled;
  final double rate; // 0.1 to 20 Hz
  final double depth; // 0 to 1
  final double shape; // 0=sin, 0.5=triangle, 1=saw
  final double mix; // 0 to 1
  final bool stereo; // stereo offset

  const TremoloConfig({
    this.enabled = false,
    this.rate = 5.0,
    this.depth = 0.5,
    this.shape = 0.0,
    this.mix = 1.0,
    this.stereo = false,
  });

  TremoloConfig copyWith({
    bool? enabled,
    double? rate,
    double? depth,
    double? shape,
    double? mix,
    bool? stereo,
  }) {
    return TremoloConfig(
      enabled: enabled ?? this.enabled,
      rate: rate ?? this.rate,
      depth: depth ?? this.depth,
      shape: shape ?? this.shape,
      mix: mix ?? this.mix,
      stereo: stereo ?? this.stereo,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'rate': rate,
        'depth': depth,
        'shape': shape,
        'mix': mix,
        'stereo': stereo,
      };

  factory TremoloConfig.fromJson(Map<String, dynamic> json) => TremoloConfig(
        enabled: json['enabled'] as bool? ?? false,
        rate: (json['rate'] as num? ?? 5.0).toDouble(),
        depth: (json['depth'] as num? ?? 0.5).toDouble(),
        shape: (json['shape'] as num? ?? 0.0).toDouble(),
        mix: (json['mix'] as num? ?? 1.0).toDouble(),
        stereo: json['stereo'] as bool? ?? false,
      );
}

class DriveConfig {
  final bool enabled;
  final double amount;
  final DriveType type;

  const DriveConfig({
    this.enabled = false,
    this.amount = 0.5,
    this.type = DriveType.overdrive,
  });

  DriveConfig copyWith({
    bool? enabled,
    double? amount,
    DriveType? type,
  }) {
    return DriveConfig(
      enabled: enabled ?? this.enabled,
      amount: amount ?? this.amount,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'amount': amount,
        'type': type.index,
      };

  factory DriveConfig.fromJson(Map<String, dynamic> json) => DriveConfig(
        enabled: json['enabled'] as bool? ?? false,
        amount: (json['amount'] as num? ?? 0.5).toDouble(),
        type: DriveType.values[json['type'] as int? ?? 0],
      );
}
