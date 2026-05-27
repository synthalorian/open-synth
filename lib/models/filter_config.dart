import 'mod_target.dart';

class FilterConfig {
  final FilterType type;
  final double cutoff; // 20 - 20000 Hz
  final double resonance; // 0.0 - 1.0
  final double envelopeAmount; // -1.0 to 1.0
  final double keyTracking; // 0.0 - 1.0
  final double drive; // 0.0 - 1.0

  const FilterConfig({
    this.type = FilterType.lowpass,
    this.cutoff = 10000.0,
    this.resonance = 0.0,
    this.envelopeAmount = 0.0,
    this.keyTracking = 0.0,
    this.drive = 0.0,
  });

  FilterConfig copyWith({
    FilterType? type,
    double? cutoff,
    double? resonance,
    double? envelopeAmount,
    double? keyTracking,
    double? drive,
  }) {
    return FilterConfig(
      type: type ?? this.type,
      cutoff: cutoff ?? this.cutoff,
      resonance: resonance ?? this.resonance,
      envelopeAmount: envelopeAmount ?? this.envelopeAmount,
      keyTracking: keyTracking ?? this.keyTracking,
      drive: drive ?? this.drive,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'cutoff': cutoff,
        'resonance': resonance,
        'envelopeAmount': envelopeAmount,
        'keyTracking': keyTracking,
        'drive': drive,
      };

  factory FilterConfig.fromJson(Map<String, dynamic> json) => FilterConfig(
        type: FilterType.values[json['type'] as int],
        cutoff: (json['cutoff'] as num).toDouble(),
        resonance: (json['resonance'] as num).toDouble(),
        envelopeAmount: (json['envelopeAmount'] as num).toDouble(),
        keyTracking: (json['keyTracking'] as num?)?.toDouble() ?? 0.0,
        drive: (json['drive'] as num?)?.toDouble() ?? 0.0,
      );
}
