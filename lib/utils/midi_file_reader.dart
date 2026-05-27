import 'dart:io';
import 'dart:typed_data';

import '../models/midi_event.dart';
import '../models/sequencer_config.dart';

/// Simple SMF (Standard MIDI File) reader supporting Format 0 and Format 1.
class MidiFileReader {
  /// Parse a SMF file at [path] and return all events as [MidiEventRecord]s.
  static List<MidiEventRecord> readEvents(String path) {
    final file = File(path);
    final bytes = file.readAsBytesSync();
    return _parse(bytes);
  }

  /// Read a SMF file and convert note events on [targetChannel] into a
  /// [SequencerPattern]. Only the first 16 unique note-on events per track
  /// become steps. Use [defaultBpm] when no tempo meta event is present.
  static SequencerPattern toSequencerPattern(
    String path, {
    int targetChannel = 0,
    double defaultBpm = 120.0,
  }) {
    final events = readEvents(path);
    final noteEvents = events.where((e) =>
        e.channel == targetChannel &&
        (e.type == MidiEventType.noteOn || e.type == MidiEventType.noteOff));

    // Build a timeline of active notes
    final steps = <SequencerStep>[];
    final activeNotes = <int, int>{}; // note -> velocity
    int lastStepTime = 0;

    for (final event in noteEvents) {
      if (event.type == MidiEventType.noteOn && event.velocity > 0) {
        activeNotes[event.note] = event.velocity;
      } else if (event.type == MidiEventType.noteOff ||
          (event.type == MidiEventType.noteOn && event.velocity == 0)) {
        activeNotes.remove(event.note);
      }

      // Create a step every ~ quarter-note interval or when note state changes
      if ((event.timestampMs - lastStepTime) > 100 && steps.length < 16) {
        if (activeNotes.isNotEmpty) {
          final note = activeNotes.keys.first;
          final velocity = activeNotes[note]!;
          steps.add(SequencerStep(
            enabled: true,
            note: note,
            velocity: velocity / 127.0,
            gate: 0.8,
          ));
        } else {
          steps.add(const SequencerStep());
        }
        lastStepTime = event.timestampMs;
      }
    }

    // Pad to 16 steps
    while (steps.length < 16) {
      steps.add(const SequencerStep());
    }

    return SequencerPattern(
      id: 'imported_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Imported',
      bpm: _extractBpm(events) ?? defaultBpm,
      tracks: [
        SequencerTrack(
          name: 'Import',
          midiChannel: targetChannel,
          steps: steps,
        ),
      ],
    );
  }

  static double? _extractBpm(List<MidiEventRecord> events) {
    for (final e in events) {
      if (e.type == MidiEventType.cc && e.ccNumber == -1) {
        // Tempo meta events are encoded as synthetic CC with ccNumber=-1
        // value = microseconds per quarter note
        final uspq = e.ccValue;
        return 60000000.0 / uspq;
      }
    }
    return null;
  }

  static List<MidiEventRecord> _parse(Uint8List bytes) {
    final events = <MidiEventRecord>[];
    int pos = 0;

    // Read header
    if (bytes.length < 14) throw FormatException('File too short for MIDI header');
    final headerType = _readString(bytes, pos, 4);
    pos += 4;
    if (headerType != 'MThd') throw FormatException('Not a MIDI file');
    final headerLen = _readUint32(bytes, pos);
    pos += 4;
    if (headerLen != 6) throw FormatException('Invalid header length');
    pos += 2; // format (unused)
    final ntrks = _readUint16(bytes, pos);
    pos += 2;
    final division = _readUint16(bytes, pos);
    pos += 2;

    final ticksPerQuarter = division & 0x7FFF;
    final isSmpte = (division & 0x8000) != 0;
    if (isSmpte) throw UnsupportedError('SMPTE division not supported');

    // Read tracks
    for (int track = 0; track < ntrks; track++) {
      if (pos + 8 > bytes.length) throw FormatException('Truncated track header');
      final trackType = _readString(bytes, pos, 4);
      pos += 4;
      if (trackType != 'MTrk') throw FormatException('Expected MTrk');
      final trackLen = _readUint32(bytes, pos);
      pos += 4;
      if (pos + trackLen > bytes.length) throw FormatException('Track length exceeds file size');
      final trackEnd = pos + trackLen;

      int runningStatus = 0;
      int absTick = 0;
      int tempo = 500000; // default 120 BPM

    while (pos < trackEnd) {
      if (pos >= bytes.length) throw FormatException('Unexpected end of track data');
      final delta = _readVarLen(bytes, pos);
      pos += delta.bytesRead;
      if (pos >= bytes.length) throw FormatException('Unexpected end after delta');
      absTick += delta.value;
      final absMs = _ticksToMs(absTick, ticksPerQuarter, tempo);

      final eventByte = bytes[pos];
      pos++;

        if (eventByte == 0xFF) {
          // Meta event
          final metaType = bytes[pos];
          pos++;
          final len = _readVarLen(bytes, pos);
          pos += len.bytesRead;
          final data = bytes.sublist(pos, pos + len.value);
          pos += len.value;

          if (metaType == 0x51 && len.value == 3) {
            tempo = (data[0] << 16) | (data[1] << 8) | data[2];
            events.add(MidiEventRecord(
              type: MidiEventType.cc,
              timestampMs: absMs,
              channel: 0,
              ccNumber: -1, // synthetic marker for tempo
              ccValue: tempo,
            ));
          }
          if (metaType == 0x2F) break; // End of track
        } else if (eventByte == 0xF0 || eventByte == 0xF7) {
          // SysEx
          final len = _readVarLen(bytes, pos);
          if (pos + len.bytesRead + len.value > bytes.length) {
            throw FormatException('SysEx length exceeds track bounds');
          }
          pos += len.bytesRead + len.value;
        } else {
          int status;
          if (eventByte & 0x80 != 0) {
            status = eventByte;
            runningStatus = status;
          } else {
            status = runningStatus;
            pos--;
          }

          final type = status & 0xF0;
          final channel = status & 0x0F;

          if (type == 0x80) {
            // Note Off
            if (pos + 2 > bytes.length) throw FormatException('Truncated Note Off');
            final note = bytes[pos];
            final velocity = bytes[pos + 1];
            pos += 2;
            events.add(MidiEventRecord(
              type: MidiEventType.noteOff,
              timestampMs: absMs,
              channel: channel,
              note: note,
              velocity: velocity,
            ));
          } else if (type == 0x90) {
            // Note On
            if (pos + 2 > bytes.length) throw FormatException('Truncated Note On');
            final note = bytes[pos];
            final velocity = bytes[pos + 1];
            pos += 2;
            events.add(MidiEventRecord(
              type: MidiEventType.noteOn,
              timestampMs: absMs,
              channel: channel,
              note: note,
              velocity: velocity,
            ));
          } else if (type == 0xB0) {
            // CC
            if (pos + 2 > bytes.length) throw FormatException('Truncated CC');
            final cc = bytes[pos];
            final value = bytes[pos + 1];
            pos += 2;
            events.add(MidiEventRecord(
              type: MidiEventType.cc,
              timestampMs: absMs,
              channel: channel,
              ccNumber: cc,
              ccValue: value,
            ));
          } else if (type == 0xC0) {
            // Program Change
            if (pos + 1 > bytes.length) throw FormatException('Truncated Program Change');
            final program = bytes[pos];
            pos += 1;
            events.add(MidiEventRecord(
              type: MidiEventType.programChange,
              timestampMs: absMs,
              channel: channel,
              program: program,
            ));
          } else if (type == 0xA0 || type == 0xD0 || type == 0xE0) {
            // Poly aftertouch, channel aftertouch, pitch bend
            pos += type == 0xE0 ? 2 : 1;
          } else {
            // Unknown — skip one byte to avoid infinite loop
            pos += 1;
          }
        }
      }
    }

    events.sort((a, b) => a.timestampMs.compareTo(b.timestampMs));
    return events;
  }

  static String _readString(Uint8List bytes, int pos, int len) {
    return String.fromCharCodes(bytes.sublist(pos, pos + len));
  }

  static int _readUint16(Uint8List bytes, int pos) {
    return (bytes[pos] << 8) | bytes[pos + 1];
  }

  static int _readUint32(Uint8List bytes, int pos) {
    return (bytes[pos] << 24) |
        (bytes[pos + 1] << 16) |
        (bytes[pos + 2] << 8) |
        bytes[pos + 3];
  }

  static _VarLenResult _readVarLen(Uint8List bytes, int pos) {
    int value = 0;
    int i = 0;
    while (pos + i < bytes.length) {
      final b = bytes[pos + i];
      value = (value << 7) | (b & 0x7F);
      i++;
      if ((b & 0x80) == 0) break;
    }
    return _VarLenResult(value, i);
  }

  static int _ticksToMs(int ticks, int ppqn, int tempoUs) {
    return (ticks * tempoUs / ppqn / 1000).round();
  }
}

class _VarLenResult {
  final int value;
  final int bytesRead;
  _VarLenResult(this.value, this.bytesRead);
}
