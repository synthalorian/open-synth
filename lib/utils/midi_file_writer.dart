import 'dart:io';
import 'dart:typed_data';

import '../models/midi_event.dart';

/// Writes a Standard MIDI File (Format 0) from a list of [MidiEventRecord]s.
///
/// Format 0 has one track chunk containing all events.
/// Timing is in ticks per quarter note (480 PPQN).
class MidiFileWriter {
  static const int _ppqn = 480;

  /// Convert recorded events to a SMF file and write to [path].
  static void write(String path, List<MidiEventRecord> events, {double bpm = 120.0}) {
    final microsecondsPerQuarter = (60000000.0 / bpm).round();

    // Sort events by absolute time
    final sorted = List<MidiEventRecord>.from(events)
      ..sort((a, b) => a.timestampMs.compareTo(b.timestampMs));

    // Convert to delta times
    final trackData = BytesBuilder();
    int lastTimeMs = 0;

    // Track name meta event
    _writeMetaEvent(trackData, 0x03, 'Open Synth Session');
    // Tempo meta event
    _writeTempoEvent(trackData, microsecondsPerQuarter);
    // Time signature (4/4)
    _writeTimeSignature(trackData);

    for (final event in sorted) {
      final deltaMs = event.timestampMs - lastTimeMs;
      final deltaTicks = (deltaMs * _ppqn * bpm / 60000.0).round();
      lastTimeMs = event.timestampMs;

      switch (event.type) {
        case MidiEventType.noteOn:
          _writeNoteOn(trackData, deltaTicks, event.channel, event.note, event.velocity);
          break;
        case MidiEventType.noteOff:
          _writeNoteOff(trackData, deltaTicks, event.channel, event.note, 0);
          break;
        case MidiEventType.cc:
          _writeCC(trackData, deltaTicks, event.channel, event.ccNumber, event.ccValue);
          break;
        case MidiEventType.programChange:
          _writeProgramChange(trackData, deltaTicks, event.channel, event.program);
          break;
      }
    }

    // End of track meta event
    _writeMetaEvent(trackData, 0x2F, '');

    final trackChunk = _buildChunk('MTrk', trackData.toBytes());
    final headerChunk = _buildHeaderChunk(0, 1, _ppqn);

    final file = File(path);
    file.writeAsBytesSync(headerChunk + trackChunk);
  }

  static Uint8List _buildChunk(String type, Uint8List data) {
    final result = BytesBuilder();
    result.add(type.codeUnits);
    result.add(_int32Bytes(data.length));
    result.add(data);
    return result.toBytes();
  }

  static Uint8List _buildHeaderChunk(int format, int numTracks, int division) {
    final data = BytesBuilder();
    data.add(_int16Bytes(format));
    data.add(_int16Bytes(numTracks));
    data.add(_int16Bytes(division));
    return _buildChunk('MThd', data.toBytes());
  }

  static void _writeVarLen(BytesBuilder builder, int value) {
    if (value == 0) {
      builder.addByte(0);
      return;
    }
    final buffer = <int>[];
    var v = value;
    while (v > 0) {
      buffer.insert(0, v & 0x7F);
      v >>= 7;
    }
    for (int i = 0; i < buffer.length - 1; i++) {
      buffer[i] |= 0x80;
    }
    builder.add(buffer);
  }

  static void _writeNoteOn(BytesBuilder builder, int delta, int channel, int note, int velocity) {
    _writeVarLen(builder, delta);
    builder.addByte(0x90 | (channel & 0x0F));
    builder.addByte(note & 0x7F);
    builder.addByte(velocity.clamp(0, 127));
  }

  static void _writeNoteOff(BytesBuilder builder, int delta, int channel, int note, int velocity) {
    _writeVarLen(builder, delta);
    builder.addByte(0x80 | (channel & 0x0F));
    builder.addByte(note & 0x7F);
    builder.addByte(velocity & 0x7F);
  }

  static void _writeCC(BytesBuilder builder, int delta, int channel, int cc, int value) {
    _writeVarLen(builder, delta);
    builder.addByte(0xB0 | (channel & 0x0F));
    builder.addByte(cc & 0x7F);
    builder.addByte(value.clamp(0, 127));
  }

  static void _writeProgramChange(BytesBuilder builder, int delta, int channel, int program) {
    _writeVarLen(builder, delta);
    builder.addByte(0xC0 | (channel & 0x0F));
    builder.addByte(program & 0x7F);
  }

  static void _writeTempoEvent(BytesBuilder builder, int microsecondsPerQuarter) {
    _writeVarLen(builder, 0);
    builder.addByte(0xFF);
    builder.addByte(0x51);
    builder.addByte(0x03);
    builder.addByte((microsecondsPerQuarter >> 16) & 0xFF);
    builder.addByte((microsecondsPerQuarter >> 8) & 0xFF);
    builder.addByte(microsecondsPerQuarter & 0xFF);
  }

  static void _writeTimeSignature(BytesBuilder builder) {
    _writeVarLen(builder, 0);
    builder.addByte(0xFF);
    builder.addByte(0x58);
    builder.addByte(0x04);
    builder.addByte(0x04); // numerator
    builder.addByte(0x02); // denominator (2^2 = 4)
    builder.addByte(0x18); // clocks per metronome click
    builder.addByte(0x08); // 32nd notes per quarter
  }

  static void _writeMetaEvent(BytesBuilder builder, int type, String text) {
    final bytes = text.codeUnits;
    _writeVarLen(builder, 0);
    builder.addByte(0xFF);
    builder.addByte(type);
    _writeVarLen(builder, bytes.length);
    builder.add(bytes);
  }

  static Uint8List _int16Bytes(int value) {
    return Uint8List(2)
      ..[0] = (value >> 8) & 0xFF
      ..[1] = value & 0xFF;
  }

  static Uint8List _int32Bytes(int value) {
    return Uint8List(4)
      ..[0] = (value >> 24) & 0xFF
      ..[1] = (value >> 16) & 0xFF
      ..[2] = (value >> 8) & 0xFF
      ..[3] = value & 0xFF;
  }
}
