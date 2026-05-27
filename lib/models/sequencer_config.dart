/// Musical scales for note quantization.
enum MusicalScale {
  chromatic('Chromatic', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]),
  major('Major', [0, 2, 4, 5, 7, 9, 11]),
  minor('Minor', [0, 2, 3, 5, 7, 8, 10]),
  harmonicMinor('Harmonic Minor', [0, 2, 3, 5, 7, 8, 11]),
  melodicMinor('Melodic Minor', [0, 2, 3, 5, 7, 9, 11]),
  pentatonicMajor('Pent. Major', [0, 2, 4, 7, 9]),
  pentatonicMinor('Pent. Minor', [0, 3, 5, 7, 10]),
  blues('Blues', [0, 3, 5, 6, 7, 10]),
  dorian('Dorian', [0, 2, 3, 5, 7, 9, 10]),
  phrygian('Phrygian', [0, 1, 3, 5, 7, 8, 10]),
  lydian('Lydian', [0, 2, 4, 6, 7, 9, 11]),
  mixolydian('Mixolydian', [0, 2, 4, 5, 7, 9, 10]),
  locrian('Locrian', [0, 1, 3, 5, 6, 8, 10]),
  wholeTone('Whole Tone', [0, 2, 4, 6, 8, 10]),
  diminished('Diminished', [0, 2, 3, 5, 6, 8, 9, 11]),
  augmented('Augmented', [0, 3, 4, 7, 8, 11]);

  const MusicalScale(this.displayName, this.intervals);
  final String displayName;
  final List<int> intervals;

  /// Snap a MIDI note to the nearest valid note in this scale.
  int quantize(int midiNote, {int root = 0}) {
    if (midiNote < 0) return midiNote;
    final octave = (midiNote ~/ 12) * 12;
    final noteInOctave = midiNote % 12;
    final relativeNote = (noteInOctave - root + 12) % 12;

    var bestInterval = intervals[0];
    var bestDist = 12;
    for (final interval in intervals) {
      final dist = (relativeNote - interval).abs();
      if (dist < bestDist) {
        bestDist = dist;
        bestInterval = interval;
      }
    }

    return octave + ((root + bestInterval) % 12);
  }
}

/// Configuration for scale quantization on a sequencer track.
class ScaleConfig {
  final MusicalScale scale;
  final int rootNote; // 0-11 (C=0, C#=1, etc.)
  final bool enabled;

  const ScaleConfig({
    this.scale = MusicalScale.chromatic,
    this.rootNote = 0,
    this.enabled = false,
  });

  ScaleConfig copyWith({
    MusicalScale? scale,
    int? rootNote,
    bool? enabled,
  }) {
    return ScaleConfig(
      scale: scale ?? this.scale,
      rootNote: rootNote ?? this.rootNote,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toJson() => {
        'scale': scale.index,
        'rootNote': rootNote,
        'enabled': enabled,
      };

  factory ScaleConfig.fromJson(Map<String, dynamic> json) => ScaleConfig(
        scale: MusicalScale.values[json['scale'] as int? ?? 0],
        rootNote: json['rootNote'] as int? ?? 0,
        enabled: json['enabled'] as bool? ?? false,
      );

  /// Quantize a MIDI note according to this scale config.
  int quantize(int midiNote) {
    if (!enabled || scale == MusicalScale.chromatic) return midiNote;
    return scale.quantize(midiNote, root: rootNote);
  }
}

/// One step in the sequencer grid.
class SequencerStep {
  final int note; // MIDI note (0-127), -1 = rest
  final double velocity; // 0.0 - 1.0
  final bool enabled;
  final double gate; // 0.0 - 1.0 (how much of the step duration the note holds)

  const SequencerStep({
    this.note = -1,
    this.velocity = 0.85,
    this.enabled = false,
    this.gate = 0.85,
  });

  SequencerStep copyWith({
    int? note,
    double? velocity,
    bool? enabled,
    double? gate,
  }) {
    return SequencerStep(
      note: note ?? this.note,
      velocity: velocity ?? this.velocity,
      enabled: enabled ?? this.enabled,
      gate: gate ?? this.gate,
    );
  }

  Map<String, dynamic> toJson() => {
        'note': note,
        'velocity': velocity,
        'enabled': enabled,
        'gate': gate,
      };

  factory SequencerStep.fromJson(Map<String, dynamic> json) => SequencerStep(
        note: json['note'] as int? ?? -1,
        velocity: (json['velocity'] as num? ?? 0.85).toDouble(),
        enabled: json['enabled'] as bool? ?? false,
        gate: (json['gate'] as num? ?? 0.85).toDouble(),
      );
}

/// One track (monophonic line) in the sequencer.
class SequencerTrack {
  final String name;
  final List<SequencerStep> steps; // typically 16 steps
  final int midiChannel;

  SequencerTrack({
    required this.name,
    required this.steps,
    this.midiChannel = 1,
  });

  SequencerTrack.empty({this.name = 'Track 1', this.midiChannel = 1})
      : steps = List.generate(16, (_) => const SequencerStep());

  SequencerTrack copyWith({
    String? name,
    List<SequencerStep>? steps,
    int? midiChannel,
  }) {
    return SequencerTrack(
      name: name ?? this.name,
      steps: steps ?? List.from(this.steps),
      midiChannel: midiChannel ?? this.midiChannel,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'steps': steps.map((s) => s.toJson()).toList(),
        'midiChannel': midiChannel,
      };

  factory SequencerTrack.fromJson(Map<String, dynamic> json) => SequencerTrack(
        name: json['name'] as String,
        steps: (json['steps'] as List)
            .map((e) => SequencerStep.fromJson(e as Map<String, dynamic>))
            .toList(),
        midiChannel: json['midiChannel'] as int? ?? 1,
      );
}

/// Full sequencer pattern with BPM and multiple tracks.
class SequencerPattern {
  final String id;
  final String name;
  final double bpm;
  final int stepsPerBar; // typically 16
  final List<SequencerTrack> tracks;
  final ScaleConfig scaleConfig;

  SequencerPattern({
    required this.id,
    required this.name,
    this.bpm = 120.0,
    this.stepsPerBar = 16,
    required this.tracks,
    this.scaleConfig = const ScaleConfig(),
  });

  SequencerPattern.empty({
    String? id,
    String? name,
    double? bpm,
    int? stepsPerBar,
    int trackCount = 1,
  })  : id = id ?? 'pattern_${DateTime.now().millisecondsSinceEpoch}',
        name = name ?? 'Untitled Pattern',
        bpm = bpm ?? 120.0,
        stepsPerBar = stepsPerBar ?? 16,
        scaleConfig = const ScaleConfig(),
        tracks = List.generate(
          trackCount,
          (i) => SequencerTrack.empty(name: 'Track ${i + 1}'),
        );

  SequencerPattern copyWith({
    String? id,
    String? name,
    double? bpm,
    int? stepsPerBar,
    List<SequencerTrack>? tracks,
    ScaleConfig? scaleConfig,
  }) {
    return SequencerPattern(
      id: id ?? this.id,
      name: name ?? this.name,
      bpm: bpm ?? this.bpm,
      stepsPerBar: stepsPerBar ?? this.stepsPerBar,
      tracks: tracks ?? List.from(this.tracks),
      scaleConfig: scaleConfig ?? this.scaleConfig,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bpm': bpm,
        'stepsPerBar': stepsPerBar,
        'tracks': tracks.map((t) => t.toJson()).toList(),
        'scaleConfig': scaleConfig.toJson(),
      };

  factory SequencerPattern.fromJson(Map<String, dynamic> json) =>
      SequencerPattern(
        id: json['id'] as String,
        name: json['name'] as String,
        bpm: (json['bpm'] as num).toDouble(),
        stepsPerBar: json['stepsPerBar'] as int? ?? 16,
        tracks: (json['tracks'] as List)
            .map((e) => SequencerTrack.fromJson(e as Map<String, dynamic>))
            .toList(),
        scaleConfig: json.containsKey('scaleConfig')
            ? ScaleConfig.fromJson(
                json['scaleConfig'] as Map<String, dynamic>)
            : const ScaleConfig(),
      );
}
