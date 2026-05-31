/// A rhythm pattern preset with metadata.
class RhythmPattern {
  final int index;
  final String name;
  final String style;
  final String category;
  final int steps;
  final int beatsPerBar;
  final int subdivisions;
  final double defaultTempo;
  final double swing;

  const RhythmPattern({
    required this.index,
    required this.name,
    required this.style,
    required this.category,
    required this.steps,
    required this.beatsPerBar,
    required this.subdivisions,
    required this.defaultTempo,
    required this.swing,
  });
}

/// Pattern variation types for song sections.
enum PatternVariation {
  intro,
  mainA,
  mainB,
  fillA,
  fillB,
  ending,
}

extension PatternVariationName on PatternVariation {
  String get displayName {
    switch (this) {
      case PatternVariation.intro:
        return 'Intro';
      case PatternVariation.mainA:
        return 'Main A';
      case PatternVariation.mainB:
        return 'Main B';
      case PatternVariation.fillA:
        return 'Fill A';
      case PatternVariation.fillB:
        return 'Fill B';
      case PatternVariation.ending:
        return 'Ending';
    }
  }
}

/// Built-in pattern library (mirrors C++ definitions).
const List<RhythmPattern> kRhythmPatterns = [
  RhythmPattern(index: 0,  name: 'Basic Rock',     style: 'rock',      category: 'Rock',       steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 120.0, swing: 0.0),
  RhythmPattern(index: 1,  name: 'Rock Ballad',    style: 'rock',      category: 'Rock',       steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 72.0,  swing: 0.0),
  RhythmPattern(index: 2,  name: 'Driving Rock',   style: 'rock',      category: 'Rock',       steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 140.0, swing: 0.0),
  RhythmPattern(index: 3,  name: 'Shuffle Rock',   style: 'rock',      category: 'Rock',       steps: 12, beatsPerBar: 4, subdivisions: 3, defaultTempo: 110.0, swing: 0.33),
  RhythmPattern(index: 4,  name: 'Half Time',      style: 'rock',      category: 'Rock',       steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 85.0,  swing: 0.0),
  RhythmPattern(index: 5,  name: 'Pop Basic',      style: 'pop',       category: 'Pop',        steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 118.0, swing: 0.0),
  RhythmPattern(index: 6,  name: 'Dance Pop',      style: 'pop',       category: 'Pop',        steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 128.0, swing: 0.0),
  RhythmPattern(index: 7,  name: 'Synth Pop',      style: 'pop',       category: 'Pop',        steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 125.0, swing: 0.0),
  RhythmPattern(index: 8,  name: 'Funk 16th',      style: 'funk',      category: 'Funk',       steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 108.0, swing: 0.15),
  RhythmPattern(index: 9,  name: 'James Brown',    style: 'funk',      category: 'Funk',       steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 115.0, swing: 0.2),
  RhythmPattern(index: 10, name: 'Jazz Swing',     style: 'jazz',      category: 'Jazz',       steps: 12, beatsPerBar: 4, subdivisions: 3, defaultTempo: 140.0, swing: 0.33),
  RhythmPattern(index: 11, name: 'Jazz Waltz',     style: 'jazz',      category: 'Jazz',       steps: 12, beatsPerBar: 3, subdivisions: 4, defaultTempo: 160.0, swing: 0.0),
  RhythmPattern(index: 12, name: 'Brush Sweep',    style: 'jazz',      category: 'Jazz',       steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 120.0, swing: 0.15),
  RhythmPattern(index: 13, name: 'Bossa Nova',     style: 'latin',     category: 'Latin',      steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 120.0, swing: 0.0),
  RhythmPattern(index: 14, name: 'Samba',          style: 'latin',     category: 'Latin',      steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 130.0, swing: 0.0),
  RhythmPattern(index: 15, name: 'Reggaeton',      style: 'latin',     category: 'Latin',      steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 95.0,  swing: 0.0),
  RhythmPattern(index: 16, name: 'Four on Floor',  style: 'electronic',category: 'Electronic', steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 128.0, swing: 0.0),
  RhythmPattern(index: 17, name: 'House',          style: 'electronic',category: 'Electronic', steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 124.0, swing: 0.0),
  RhythmPattern(index: 18, name: 'Techno',         style: 'electronic',category: 'Electronic', steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 135.0, swing: 0.0),
  RhythmPattern(index: 19, name: 'Drum \u0026 Bass',  style: 'electronic',category: 'Electronic', steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 174.0, swing: 0.0),
  RhythmPattern(index: 20, name: 'Trap',           style: 'electronic',category: 'Electronic', steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 140.0, swing: 0.0),
  RhythmPattern(index: 21, name: 'UK Garage',      style: 'electronic',category: 'Electronic', steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 130.0, swing: 0.2),
  RhythmPattern(index: 22, name: 'Afrobeat',       style: 'world',     category: 'World',      steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 110.0, swing: 0.1),
  RhythmPattern(index: 23, name: 'Reggae',         style: 'world',     category: 'World',      steps: 16, beatsPerBar: 4, subdivisions: 4, defaultTempo: 80.0,  swing: 0.0),
];

/// Get unique category names in order.
List<String> get rhythmCategories {
  final cats = <String>[];
  for (final p in kRhythmPatterns) {
    if (!cats.contains(p.category)) {
      cats.add(p.category);
    }
  }
  return cats;
}

/// Patterns filtered by category.
List<RhythmPattern> patternsInCategory(String category) {
  return kRhythmPatterns.where((p) => p.category == category).toList();
}
