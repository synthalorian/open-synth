import 'waveform.dart';

class Oscillator {
  final Waveform waveform;
  final int octave; // -2 to +2
  final double detune; // -100 to +100 cents
  final double pulseWidth; // 0.0 to 1.0
  final double volume; // 0.0 to 1.0
  final bool enabled;
  final double wavetablePosition; // 0.0 to 1.0 — morph between wavetable frames

  // ── Unison ───────────────────────────────────────────────
  final int unisonVoiceCount; // 1 to 8, 1 = off
  final double unisonDetuneSpread; // 0 to 50 cents
  final double unisonStereoSpread; // 0.0 to 1.0 (pan spread)
  final double unisonMix; // 0.0 to 1.0 (wet/dry)

  const Oscillator({
    this.waveform = Waveform.sine,
    this.octave = 0,
    this.detune = 0.0,
    this.pulseWidth = 0.5,
    this.volume = 0.8,
    this.enabled = true,
    this.wavetablePosition = 0.0,
    this.unisonVoiceCount = 1,
    this.unisonDetuneSpread = 10.0,
    this.unisonStereoSpread = 0.5,
    this.unisonMix = 1.0,
  });

  Oscillator copyWith({
    Waveform? waveform,
    int? octave,
    double? detune,
    double? pulseWidth,
    double? volume,
    bool? enabled,
    double? wavetablePosition,
    int? unisonVoiceCount,
    double? unisonDetuneSpread,
    double? unisonStereoSpread,
    double? unisonMix,
  }) {
    return Oscillator(
      waveform: waveform ?? this.waveform,
      octave: octave ?? this.octave,
      detune: detune ?? this.detune,
      pulseWidth: pulseWidth ?? this.pulseWidth,
      volume: volume ?? this.volume,
      enabled: enabled ?? this.enabled,
      wavetablePosition: wavetablePosition ?? this.wavetablePosition,
      unisonVoiceCount: unisonVoiceCount ?? this.unisonVoiceCount,
      unisonDetuneSpread: unisonDetuneSpread ?? this.unisonDetuneSpread,
      unisonStereoSpread: unisonStereoSpread ?? this.unisonStereoSpread,
      unisonMix: unisonMix ?? this.unisonMix,
    );
  }

  Map<String, dynamic> toJson() => {
        'waveform': waveform.index,
        'octave': octave,
        'detune': detune,
        'pulseWidth': pulseWidth,
        'volume': volume,
        'enabled': enabled,
        'wavetablePosition': wavetablePosition,
        'unisonVoiceCount': unisonVoiceCount,
        'unisonDetuneSpread': unisonDetuneSpread,
        'unisonStereoSpread': unisonStereoSpread,
        'unisonMix': unisonMix,
      };

  factory Oscillator.fromJson(Map<String, dynamic> json) => Oscillator(
        waveform: Waveform.values[json['waveform'] as int],
        octave: json['octave'] as int,
        detune: (json['detune'] as num).toDouble(),
        pulseWidth: (json['pulseWidth'] as num? ?? 0.5).toDouble(),
        volume: (json['volume'] as num).toDouble(),
        enabled: json['enabled'] as bool,
        wavetablePosition: (json['wavetablePosition'] as num?)?.toDouble() ?? 0.0,
        unisonVoiceCount: (json['unisonVoiceCount'] as int?) ?? 1,
        unisonDetuneSpread: (json['unisonDetuneSpread'] as num?)?.toDouble() ?? 10.0,
        unisonStereoSpread: (json['unisonStereoSpread'] as num?)?.toDouble() ?? 0.5,
        unisonMix: (json['unisonMix'] as num?)?.toDouble() ?? 1.0,
      );
}
