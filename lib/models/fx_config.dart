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
