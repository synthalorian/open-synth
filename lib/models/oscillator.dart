import 'waveform.dart';

class Oscillator {
  final Waveform waveform;
  final int octave; // -2 to +2
  final double detune; // -100 to +100 cents
  final double pulseWidth; // 0.0 to 1.0
  final double volume; // 0.0 to 1.0
  final bool enabled;
  final double wavetablePosition; // 0.0 to 1.0 — morph between wavetable frames

  // ── Noise / Sub-osc / FM ───────────────────────────────
  final int noiseType; // 0=white, 1=pink, 2=brown
  final int subOscMode; // 0=off, 1=square-1oct, 2=square-2oct, 3=sine-1oct
  final double subOscVolume; // 0.0 to 1.0
  final bool fmEnabled;
  final double fmAmount; // 0.0 to 1.0

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
    this.noiseType = 0,
    this.subOscMode = 0,
    this.subOscVolume = 0.5,
    this.fmEnabled = false,
    this.fmAmount = 0.5,
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
    int? noiseType,
    int? subOscMode,
    double? subOscVolume,
    bool? fmEnabled,
    double? fmAmount,
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
      noiseType: noiseType ?? this.noiseType,
      subOscMode: subOscMode ?? this.subOscMode,
      subOscVolume: subOscVolume ?? this.subOscVolume,
      fmEnabled: fmEnabled ?? this.fmEnabled,
      fmAmount: fmAmount ?? this.fmAmount,
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
        'noiseType': noiseType,
        'subOscMode': subOscMode,
        'subOscVolume': subOscVolume,
        'fmEnabled': fmEnabled,
        'fmAmount': fmAmount,
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
        noiseType: (json['noiseType'] as int?) ?? 0,
        subOscMode: (json['subOscMode'] as int?) ?? 0,
        subOscVolume: (json['subOscVolume'] as num?)?.toDouble() ?? 0.5,
        fmEnabled: (json['fmEnabled'] as bool?) ?? false,
        fmAmount: (json['fmAmount'] as num?)?.toDouble() ?? 0.5,
        unisonVoiceCount: (json['unisonVoiceCount'] as int?) ?? 1,
        unisonDetuneSpread: (json['unisonDetuneSpread'] as num?)?.toDouble() ?? 10.0,
        unisonStereoSpread: (json['unisonStereoSpread'] as num?)?.toDouble() ?? 0.5,
        unisonMix: (json['unisonMix'] as num?)?.toDouble() ?? 1.0,
      );
}
