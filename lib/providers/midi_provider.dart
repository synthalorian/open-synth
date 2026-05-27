import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/arpeggiator_config.dart';
import '../models/midi_event.dart';
import '../models/mod_matrix.dart';
import 'arpeggiator_provider.dart';
import 'clock_provider.dart';
import 'macro_provider.dart';
import 'midi_recorder_provider.dart';
import 'mod_matrix_provider.dart';
import 'synth_providers.dart';

/// Currently available MIDI devices (updated on hot-plug).
final midiDevicesProvider = StreamProvider.autoDispose<List<MidiDevice>>((ref) {
  final command = MidiCommand();

  // Initial list
  final controller = StreamController<List<MidiDevice>>.broadcast();

  Future<void> refresh() async {
    try {
      final devices = await command.devices ?? <MidiDevice>[];
      controller.add(List.unmodifiable(devices));
    } catch (e, st) {
      developer.log('MIDI device scan failed', error: e, stackTrace: st, name: 'open_synth.midi');
      controller.add(<MidiDevice>[]);
    }
  }

  refresh();

  // Hot-plug stream
  final sub = command.onMidiSetupChanged?.listen((_) => refresh());

  ref.onDispose(() {
    sub?.cancel();
    controller.close();
  });

  return controller.stream;
});

/// The currently selected / connected MIDI device.
final selectedMidiDeviceProvider = StateProvider<MidiDevice?>((ref) => null);

/// Whether the MIDI listener is active and receiving data.
final midiConnectionStatusProvider = StateProvider<bool>((ref) => false);

/// Parsed MIDI events for debugging / display.
final midiEventLogProvider = StateProvider<List<String>>((ref) => []);

/// Starts the MIDI listener. Watches [selectedMidiDeviceProvider] and
/// automatically connects/disconnects. Feeds noteOn/noteOff into the
/// playback state provider.
///
/// Consumers `ref.watch` this to keep the listener alive.
final midiListenerProvider = Provider<void>((ref) {
  final device = ref.watch(selectedMidiDeviceProvider);

  if (device == null) {
    ref.read(midiConnectionStatusProvider.notifier).state = false;
    return;
  }

  final command = MidiCommand();

  Future<void> connect() async {
    try {
      await command.connectToDevice(device);
      ref.read(midiConnectionStatusProvider.notifier).state = true;
      developer.log('MIDI connected: ${device.name}', name: 'open_synth.midi');
    } catch (e, st) {
      developer.log('MIDI connect failed', error: e, stackTrace: st, name: 'open_synth.midi');
      ref.read(midiConnectionStatusProvider.notifier).state = false;
    }
  }

  connect();

  // Subscribe to MIDI data
  StreamSubscription<MidiPacket>? dataSub;
  try {
    dataSub = command.onMidiDataReceived?.listen((packet) {
      _handleMidiPacket(packet, ref);
    });
  } catch (e, st) {
    developer.log('MIDI data stream failed', error: e, stackTrace: st, name: 'open_synth.midi');
  }

  ref.onDispose(() {
    dataSub?.cancel();
    try {
      command.disconnectDevice(device);
    } catch (_) {}
    ref.read(midiConnectionStatusProvider.notifier).state = false;
  });
});

void _handleMidiPacket(
  MidiPacket packet,
  Ref ref,
) {
  final data = packet.data;
  if (data.isEmpty) return;

  final status = data[0];
  final channel = status & 0x0F;
  final msgType = status & 0xF0;

  // System Real-Time messages (single-byte, no channel)
  if (status == 0xF8 || status == 0xFA || status == 0xFB || status == 0xFC || status == 0xF6) {
    handleMidiClockByte(status, ref);
    return;
  }

  // Read arp config dynamically so toggling works while MIDI is active.
  final arpConfig = ref.read(arpeggiatorConfigProvider);
  final arpEnabled = arpConfig.enabled && arpConfig.pattern != ArpPattern.off;
  final playback = ref.read(playbackStateProvider.notifier);

  // Note On (0x90)
  if (msgType == 0x90 && data.length >= 3) {
    final note = data[1];
    final velocity = data[2];
    if (velocity > 0) {
      _logEvent(ref, 'Note On  ch${channel + 1}  note $note  vel $velocity');
      if (arpEnabled) {
        final current = ref.read(arpNotesProvider);
        ref.read(arpNotesProvider.notifier).state = {...current, note};
      } else {
        playback.noteOn(note, velocity: velocity / 127.0);
      }
    } else {
      // Velocity 0 is Note Off
      _logEvent(ref, 'Note Off ch${channel + 1}  note $note');
      if (arpEnabled) {
        final current = ref.read(arpNotesProvider);
        ref.read(arpNotesProvider.notifier).state = {...current}..remove(note);
      } else {
        playback.noteOff(note);
      }
    }
  }

  // Note Off (0x80)
  else if (msgType == 0x80 && data.length >= 3) {
    final note = data[1];
    _logEvent(ref, 'Note Off ch${channel + 1}  note $note');
    if (arpEnabled) {
      final current = ref.read(arpNotesProvider);
      ref.read(arpNotesProvider.notifier).state = {...current}..remove(note);
    } else {
      playback.noteOff(note);
    }
  }

  // Control Change (0xB0)
  else if (msgType == 0xB0 && data.length >= 3) {
    final cc = data[1];
    final value = data[2];
    _logEvent(ref, 'CC       ch${channel + 1}  CC $cc  val $value');
    _handleControlChange(ref, channel, cc, value);
    // Inline recording to avoid Ref/WidgetRef type mismatch in provider context
    final isRecording = ref.read(midiRecordingProvider);
    if (isRecording) {
      final notifier = ref.read(midiRecorderEventsProvider.notifier);
      final now = DateTime.now();
      final startTime = notifier.startTime ?? now;
      final elapsed = now.difference(startTime).inMilliseconds;
      notifier.addEvent(MidiEventRecord.cc(
        timestampMs: elapsed,
        ccNumber: cc,
        ccValue: value,
        channel: channel,
      ));
    }
  }
}

void _handleControlChange(Ref ref, int channel, int cc, int value) {
  // Check if macro is in learn mode
  final learnMacro = ref.read(macroLearnModeProvider);
  if (learnMacro >= 0) {
    ref.read(macroBankProvider.notifier).setMacroCc(learnMacro, cc);
    ref.read(macroLearnModeProvider.notifier).state = -1;
    _logEvent(ref, 'Learned: CC $cc → Macro ${learnMacro + 1}');
    return;
  }

  // Check if mod matrix is in learn mode
  final learnSlot = ref.read(modMatrixLearnModeProvider);
  if (learnSlot >= 0) {
    final slot = ref.read(modMatrixProvider).slots[learnSlot];
    ref.read(ccAssignmentsProvider.notifier).assign(cc, slot.source);
    ref.read(modMatrixLearnModeProvider.notifier).state = -1;
    _logEvent(ref, 'Learned: CC $cc → Slot ${learnSlot + 1} (${slot.source.displayName})');
    return;
  }

  // Mod Wheel (CC 1)
  if (cc == 1) {
    final normalized = (value / 127.0).clamp(0.0, 1.0);
    final values = Map<ModSource, double>.from(ref.read(modSourceValuesProvider));
    values[ModSource.modWheel] = normalized;
    ref.read(modSourceValuesProvider.notifier).state = values;
  }
  // Expression (CC 11)
  else if (cc == 11) {
    final normalized = (value / 127.0).clamp(0.0, 1.0);
    final values = Map<ModSource, double>.from(ref.read(modSourceValuesProvider));
    values[ModSource.velocity] = normalized;
    ref.read(modSourceValuesProvider.notifier).state = values;
  }
  // Sustain pedal (CC 64)
  else if (cc == 64) {
    // Could implement sustain logic here
  }

  // Handle CC assignments for modulation matrix
  final assignments = ref.read(ccAssignmentsProvider);
  final source = assignments[cc];
  if (source != null) {
    final normalized = (value / 127.0).clamp(0.0, 1.0);
    final bipolarValue = (normalized - 0.5) * 2.0;
    final values = Map<ModSource, double>.from(ref.read(modSourceValuesProvider));
    values[source] = source == ModSource.modWheel || source == ModSource.velocity || source == ModSource.aftertouch
        ? normalized
        : bipolarValue;
    ref.read(modSourceValuesProvider.notifier).state = values;
  }
}

void _logEvent(dynamic ref, String message) {
  assert(ref is Ref, '_logEvent expects a Riverpod Ref');
  final r = ref as Ref;
  final log = r.read(midiEventLogProvider);
  final updated = [message, ...log];
  if (updated.length > 20) updated.removeLast();
  r.read(midiEventLogProvider.notifier).state = updated;
}

/// Sends a MIDI Control Change message to the currently selected output device.
/// [ref] can be any Riverpod ref (provider `Ref` or widget `WidgetRef`).
/// [channel] is 0-based (0 = channel 1).
void sendMidiCc(dynamic ref, int channel, int ccNumber, int value) {
  assert(ref is Ref, 'sendMidiCc expects a Riverpod Ref');
  final r = ref as Ref;
  final device = r.read(selectedMidiDeviceProvider);
  if (device == null) return;

  final clampedCc = ccNumber.clamp(0, 127);
  final clampedValue = value.clamp(0, 127);
  final status = 0xB0 | (channel.clamp(0, 15));
  final data = Uint8List.fromList([status, clampedCc, clampedValue]);

  try {
    MidiCommand().sendData(data, deviceId: device.id);
    _logEvent(ref, 'OUT CC ch${channel + 1}  CC $clampedCc  val $clampedValue');
  } catch (e, st) {
    developer.log('MIDI send failed', error: e, stackTrace: st, name: 'open_synth.midi');
  }
}
