/// Configuration for preset morphing / crossfade.
class MorphConfig {
  final String sourcePresetId;
  final String targetPresetId;
  final double position; // 0.0 = source, 1.0 = target
  final bool isPlaying; // auto-advance
  final double speed; // position units per second (0.01 - 2.0)

  const MorphConfig({
    this.sourcePresetId = '',
    this.targetPresetId = '',
    this.position = 0.0,
    this.isPlaying = false,
    this.speed = 0.2,
  });

  MorphConfig copyWith({
    String? sourcePresetId,
    String? targetPresetId,
    double? position,
    bool? isPlaying,
    double? speed,
  }) {
    return MorphConfig(
      sourcePresetId: sourcePresetId ?? this.sourcePresetId,
      targetPresetId: targetPresetId ?? this.targetPresetId,
      position: position ?? this.position,
      isPlaying: isPlaying ?? this.isPlaying,
      speed: speed ?? this.speed,
    );
  }
}
