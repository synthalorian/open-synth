enum MidiEventType {
  noteOn,
  noteOff,
  cc,
  programChange,
}

/// One recorded MIDI event with absolute timestamp.
class MidiEventRecord {
  final MidiEventType type;
  final int timestampMs; // absolute ms from start of recording
  final int channel;
  final int note;
  final int velocity;
  final int ccNumber;
  final int ccValue;
  final int program;

  const MidiEventRecord({
    required this.type,
    required this.timestampMs,
    this.channel = 0,
    this.note = 0,
    this.velocity = 0,
    this.ccNumber = 0,
    this.ccValue = 0,
    this.program = 0,
  });

  MidiEventRecord.noteOn({
    required this.timestampMs,
    required this.note,
    this.velocity = 100,
    this.channel = 0,
  })  : type = MidiEventType.noteOn,
        ccNumber = 0,
        ccValue = 0,
        program = 0;

  MidiEventRecord.noteOff({
    required this.timestampMs,
    required this.note,
    this.channel = 0,
  })  : type = MidiEventType.noteOff,
        velocity = 0,
        ccNumber = 0,
        ccValue = 0,
        program = 0;

  MidiEventRecord.cc({
    required this.timestampMs,
    required this.ccNumber,
    required this.ccValue,
    this.channel = 0,
  })  : type = MidiEventType.cc,
        note = 0,
        velocity = 0,
        program = 0;

  Map<String, dynamic> toJson() => {
        'type': type.index,
        'timestampMs': timestampMs,
        'channel': channel,
        'note': note,
        'velocity': velocity,
        'ccNumber': ccNumber,
        'ccValue': ccValue,
        'program': program,
      };

  factory MidiEventRecord.fromJson(Map<String, dynamic> json) => MidiEventRecord(
        type: MidiEventType.values[json['type'] as int],
        timestampMs: json['timestampMs'] as int,
        channel: json['channel'] as int? ?? 0,
        note: json['note'] as int? ?? 0,
        velocity: json['velocity'] as int? ?? 0,
        ccNumber: json['ccNumber'] as int? ?? 0,
        ccValue: json['ccValue'] as int? ?? 0,
        program: json['program'] as int? ?? 0,
      );
}
