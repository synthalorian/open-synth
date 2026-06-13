/// Represents a sample-based instrument preset (SFZ).
///
/// Unlike synthesis presets, these reference recorded audio samples
/// for realistic instrument sounds (piano, strings, brass, etc.).
class SamplePreset {
  final String id;
  final String name;
  final String category;
  final String? description;

  /// Path to the SFZ file. Can be:
  /// - Absolute path (for user-loaded instruments)
  /// - Relative path within assets (for bundled instruments)
  final String sfzPath;

  /// Optional: path to a preview image or icon.
  final String? iconPath;

  /// Whether this preset is bundled with the app.
  final bool isBundled;

  /// Whether this preset requires disk streaming (large samples).
  final bool usesDiskStreaming;

  const SamplePreset({
    required this.id,
    required this.name,
    required this.category,
    required this.sfzPath,
    this.description,
    this.iconPath,
    this.isBundled = false,
    this.usesDiskStreaming = true,
  });

  @override
  String toString() => 'SamplePreset($name, $category)';
}

/// Categories matching Roland Juno-Di instrument groups.
class SampleCategories {
  static const String piano = 'Piano';
  static const String ePiano = 'E.Piano';
  static const String organ = 'Organ';
  static const String strings = 'Strings';
  static const String brass = 'Brass';
  static const String woodwind = 'Woodwind';
  static const String guitar = 'Guitar';
  static const String bass = 'Bass';
  static const String synthLead = 'Synth Lead';
  static const String synthPad = 'Synth Pad';
  static const String choir = 'Choir / Vox';
  static const String percussion = 'Percussion';
  static const String drums = 'Drums';
  static const String sfx = 'SFX / Other';

  static const List<String> all = [
    piano, ePiano, organ, strings, brass, woodwind,
    guitar, bass, synthLead, synthPad, choir,
    percussion, drums, sfx,
  ];
}
