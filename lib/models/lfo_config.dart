import 'mod_target.dart';
import 'waveform.dart';

class LfoConfig {
  final Waveform waveform;
  final double rate; // 0.1 - 20.0 Hz
  final double depth; // 0.0 - 1.0
  final LfoTarget target;
  final double fadeIn; // seconds (0 - 10)
  final bool tempoSync;
  final int tempoDivision; // 1=whole, 2=half, 4=quarter, 8=eighth, etc.

  const LfoConfig({
    this.waveform = Waveform.sine,
    this.rate = 1.0,
    this.depth = 0.0,
    this.target = LfoTarget.pitch,
    this.fadeIn = 0.0,
    this.tempoSync = false,
    this.tempoDivision = 4,
  });

  LfoConfig copyWith({
    Waveform? waveform,
    double? rate,
    double? depth,
    LfoTarget? target,
    double? fadeIn,
    bool? tempoSync,
    int? tempoDivision,
  }) {
    return LfoConfig(
      waveform: waveform ?? this.waveform,
      rate: rate ?? this.rate,
      depth: depth ?? this.depth,
      target: target ?? this.target,
      fadeIn: fadeIn ?? this.fadeIn,
      tempoSync: tempoSync ?? this.tempoSync,
      tempoDivision: tempoDivision ?? this.tempoDivision,
    );
  }

  Map<String, dynamic> toJson() => {
        'waveform': waveform.index,
        'rate': rate,
        'depth': depth,
        'target': target.index,
        'fadeIn': fadeIn,
        'tempoSync': tempoSync,
        'tempoDivision': tempoDivision,
      };

  factory LfoConfig.fromJson(Map<String, dynamic> json) => LfoConfig(
        waveform: Waveform.values[json['waveform'] as int],
        rate: (json['rate'] as num).toDouble(),
        depth: (json['depth'] as num).toDouble(),
        target: LfoTarget.values[json['target'] as int],
        fadeIn: (json['fadeIn'] as num?)?.toDouble() ?? 0.0,
        tempoSync: (json['tempoSync'] as bool?) ?? false,
        tempoDivision: (json['tempoDivision'] as int?) ?? 4,
      );
}
