import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/logger.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

import '../models/midi_event.dart';
import '../utils/midi_file_writer.dart';

/// Whether recording is active.
final midiRecordingProvider = StateProvider<bool>((ref) => false);

/// Current recording session events.
final midiRecorderEventsProvider =
    StateNotifierProvider<MidiRecorderNotifier, List<MidiEventRecord>>((ref) {
  return MidiRecorderNotifier();
});

class MidiRecorderNotifier extends StateNotifier<List<MidiEventRecord>> {
  MidiRecorderNotifier() : super([]);

  DateTime? _startTime;

  /// Tracks last recorded automation value per CC number to throttle
  /// redundant events (only record if delta >= 0.01).
  final Map<int, double> _lastAutomationValues = {};

  void startRecording() {
    state = [];
    _startTime = DateTime.now();
    _lastAutomationValues.clear();
  }

  void stopRecording() {
    _startTime = null;
  }

  DateTime? get startTime => _startTime;

  void addEvent(MidiEventRecord event) {
    if (_startTime == null) return;
    state = [...state, event];
  }

  /// Returns true if the value should be recorded (changed enough).
  bool shouldRecordAutomation(int ccNumber, double normalizedValue) {
    final last = _lastAutomationValues[ccNumber];
    if (last == null) {
      _lastAutomationValues[ccNumber] = normalizedValue;
      return true;
    }
    if ((normalizedValue - last).abs() >= 0.01) {
      _lastAutomationValues[ccNumber] = normalizedValue;
      return true;
    }
    return false;
  }

  void clear() {
    state = [];
    _startTime = null;
    _lastAutomationValues.clear();
  }

  void importEvents(List<MidiEventRecord> events) {
    state = events;
    _startTime = DateTime.now();
    _lastAutomationValues.clear();
  }

  int get durationMs {
    if (state.isEmpty) return 0;
    return state.last.timestampMs;
  }
}

/// Helper to record a note on event.
void recordNoteOn(WidgetRef ref, int note, {double velocity = 1.0, int channel = 0}) {
  final isRecording = ref.read(midiRecordingProvider);
  if (!isRecording) return;

  final notifier = ref.read(midiRecorderEventsProvider.notifier);
  final now = DateTime.now();
  final startTime = notifier.startTime ?? now;
  final elapsed = now.difference(startTime).inMilliseconds;

  notifier.addEvent(MidiEventRecord.noteOn(
    timestampMs: elapsed,
    note: note,
    velocity: (velocity * 127).round().clamp(0, 127),
    channel: channel,
  ));
}

/// Helper to record a note off event.
void recordNoteOff(WidgetRef ref, int note, {int channel = 0}) {
  final isRecording = ref.read(midiRecordingProvider);
  if (!isRecording) return;

  final notifier = ref.read(midiRecorderEventsProvider.notifier);
  final now = DateTime.now();
  final startTime = notifier.startTime ?? now;
  final elapsed = now.difference(startTime).inMilliseconds;

  notifier.addEvent(MidiEventRecord.noteOff(
    timestampMs: elapsed,
    note: note,
    channel: channel,
  ));
}

/// Helper to record a CC event.
void recordCC(WidgetRef ref, int ccNumber, int value, {int channel = 0}) {
  final isRecording = ref.read(midiRecordingProvider);
  if (!isRecording) return;

  final notifier = ref.read(midiRecorderEventsProvider.notifier);
  final now = DateTime.now();
  final startTime = notifier._startTime ?? now;
  final elapsed = now.difference(startTime).inMilliseconds;

  notifier.addEvent(MidiEventRecord.cc(
    timestampMs: elapsed,
    ccNumber: ccNumber,
    ccValue: value,
    channel: channel,
  ));
}

/// Record an automation parameter change as a synthetic CC event.
/// Uses CC numbers 100+ to avoid collision with standard MIDI CCs.
/// Throttled: only records if value changed by >= 0.01 since last record.
void recordAutomationCC(WidgetRef ref, int ccNumber, double normalizedValue, {int channel = 0}) {
  final isRecording = ref.read(midiRecordingProvider);
  if (!isRecording) return;

  final notifier = ref.read(midiRecorderEventsProvider.notifier);
  final clamped = normalizedValue.clamp(0.0, 1.0);
  if (!notifier.shouldRecordAutomation(ccNumber, clamped)) return;

  final now = DateTime.now();
  final startTime = notifier.startTime ?? now;
  final elapsed = now.difference(startTime).inMilliseconds;

  final value = (clamped * 127).round();

  notifier.addEvent(MidiEventRecord.cc(
    timestampMs: elapsed,
    ccNumber: ccNumber,
    ccValue: value,
    channel: channel,
  ));
}

/// Export current recording to a MIDI file in the Documents directory.
Future<String?> exportRecordingToMidi(WidgetRef ref, {double bpm = 120.0}) async {
  final events = ref.read(midiRecorderEventsProvider);
  if (events.isEmpty) return null;

  try {
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final path = '${dir.path}/open_synth_session_$timestamp.mid';
    MidiFileWriter.write(path, events, bpm: bpm);
    appLogger.info('MIDI exported to $path');
    return path;
  } catch (e, st) {
    appLogger.severe('MIDI export failed', e, st);
    return null;
  }
}

// ── Saved Sessions ──────────────────────────────────────

final savedSessionsProvider =
    StateNotifierProvider<SavedSessionsNotifier, List<SavedSession>>((ref) {
  return SavedSessionsNotifier();
});

class SavedSession {
  final String id;
  final String name;
  final DateTime createdAt;
  final int durationMs;
  final List<MidiEventRecord> events;

  SavedSession({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.durationMs,
    required this.events,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'durationMs': durationMs,
        'events': events.map((e) => e.toJson()).toList(),
      };

  factory SavedSession.fromJson(Map<String, dynamic> json) => SavedSession(
        id: json['id'] as String,
        name: json['name'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        durationMs: json['durationMs'] as int,
        events: (json['events'] as List)
            .map((e) => MidiEventRecord.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class SavedSessionsNotifier extends StateNotifier<List<SavedSession>> {
  SavedSessionsNotifier() : super([]) {
    _load();
  }

  Box? _box;

  Future<void> _load() async {
    _box = Hive.box('open_synth');
    final stored = _box?.get('saved_sessions') as List?;
    if (stored != null) {
      try {
        state = stored
            .map((e) => SavedSession.fromJson(
                Map<String, dynamic>.from(jsonDecode(e as String))))
            .toList();
      } catch (e) {
        state = [];
      }
    }
  }

  void _save() {
    _box?.put('saved_sessions',
        state.map((s) => jsonEncode(s.toJson())).toList());
  }

  void addSession(SavedSession session) {
    state = [session, ...state];
    _save();
  }

  void deleteSession(String id) {
    state = state.where((s) => s.id != id).toList();
    _save();
  }
}
