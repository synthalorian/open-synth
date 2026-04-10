import 'mod_target.dart';
import 'waveform.dart';

class LfoConfig {
  final Waveform waveform;
  final double rate; // 0.1 - 20.0 Hz
  final double depth; // 0.0 - 1.0
  final LfoTarget target;

  const LfoConfig({
    this.waveform = Waveform.sine,
    this.rate = 1.0,
    this.depth = 0.0,
    this.target = LfoTarget.pitch,
  });

  LfoConfig copyWith({
    Waveform? waveform,
    double? rate,
    double? depth,
    LfoTarget? target,
  }) {
    return LfoConfig(
      waveform: waveform ?? this.waveform,
      rate: rate ?? this.rate,
      depth: depth ?? this.depth,
      target: target ?? this.target,
    );
  }

  Map<String, dynamic> toJson() => {
        'waveform': waveform.index,
        'rate': rate,
        'depth': depth,
        'target': target.index,
      };

  factory LfoConfig.fromJson(Map<String, dynamic> json) => LfoConfig(
        waveform: Waveform.values[json['waveform'] as int],
        rate: (json['rate'] as num).toDouble(),
        depth: (json['depth'] as num).toDouble(),
        target: LfoTarget.values[json['target'] as int],
      );
}
