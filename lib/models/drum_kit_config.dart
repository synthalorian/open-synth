/// Drum kit configuration model.
///
/// 10 built-in kits: Standard, Room, Power, TR-808, TR-909,
/// Electronic, Jazz, Brush, Orchestra, SFX.
class DrumKitConfig {
  final int kitIndex;
  final double level;

  const DrumKitConfig({
    this.kitIndex = 0,
    this.level = 0.8,
  });

  static const kitNames = [
    'Standard',
    'Room',
    'Power',
    'TR-808',
    'TR-909',
    'Electronic',
    'Jazz',
    'Brush',
    'Orchestra',
    'SFX',
  ];

  DrumKitConfig copyWith({int? kitIndex, double? level}) {
    return DrumKitConfig(
      kitIndex: kitIndex ?? this.kitIndex,
      level: level ?? this.level,
    );
  }
}