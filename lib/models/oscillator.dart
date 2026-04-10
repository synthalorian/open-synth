import 'waveform.dart';

class Oscillator {
  final Waveform waveform;
  final int octave; // -2 to +2
  final double detune; // -100 to +100 cents
  final double volume; // 0.0 to 1.0
  final bool enabled;

  const Oscillator({
    this.waveform = Waveform.sine,
    this.octave = 0,
    this.detune = 0.0,
    this.volume = 0.8,
    this.enabled = true,
  });

  Oscillator copyWith({
    Waveform? waveform,
    int? octave,
    double? detune,
    double? volume,
    bool? enabled,
  }) {
    return Oscillator(
      waveform: waveform ?? this.waveform,
      octave: octave ?? this.octave,
      detune: detune ?? this.detune,
      volume: volume ?? this.volume,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'waveform': waveform.index,
        'octave': octave,
        'detune': detune,
        'volume': volume,
        'enabled': enabled,
      };

  factory Oscillator.fromJson(Map<String, dynamic> json) => Oscillator(
        waveform: Waveform.values[json['waveform'] as int],
        octave: json['octave'] as int,
        detune: (json['detune'] as num).toDouble(),
        volume: (json['volume'] as num).toDouble(),
        enabled: json['enabled'] as bool,
      );
}
