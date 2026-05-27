import 'dart:async';
import 'dart:developer' as developer;
import 'dart:typed_data';

import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'midi_provider.dart';

// ── Types ───────────────────────────────────────────────

enum ClockMode {
  off('Internal'),
  master('Master'),
  slave('Slave');

  const ClockMode(this.displayName);
  final String displayName;
}

// ── State Providers ───────────────────────────────────

final clockModeProvider = StateProvider<ClockMode>((ref) => ClockMode.off);
final clockBpmProvider = StateProvider<double>((ref) => 120.0);
final clockPlayingProvider = StateProvider<bool>((ref) => false);

/// 24 PPQN tick counter. Wraps at a large value to avoid overflow.
final clockTickProvider = StateProvider<int>((ref) => 0);

/// Exposes the effective BPM for consumers (sequencer, arpeggiator).
/// In slave mode this is derived from incoming clock; in master/internal
/// it comes from [clockBpmProvider].
final effectiveBpmProvider = Provider<double>((ref) {
  return ref.watch(clockBpmProvider);
});

// ── Transport Helpers ─────────────────────────────────

class ClockTransportNotifier extends StateNotifier<bool> {
  ClockTransportNotifier() : super(false);

  void play() => state = true;
  void stop() => state = false;
  void toggle() => state = !state;
}

// Re-export a dedicated transport notifier so panels can toggle cleanly.
final clockTransportProvider = StateNotifierProvider<ClockTransportNotifier, bool>((ref) {
  return ClockTransportNotifier();
});

// ── MIDI Clock Engine ─────────────────────────────────

/// The clock engine keeps the timer, sends/receives MIDI clock, and
/// updates shared tick / BPM / transport state.
///
/// When mode == master: generates 24 PPQN ticks and sends 0xF8
///   plus 0xFA / 0xFC on transport changes.
/// When mode == slave: incoming 0xF8 / 0xFA / 0xFB / 0xFC are handled
///   inside [midi_provider.dart]; this provider just stays alive.
/// When mode == off: does nothing.
final midiClockEngineProvider = Provider<void>((ref) {
  final mode = ref.watch(clockModeProvider);

  // Ensure connection status is tracked so we know if MIDI out is available.
  ref.watch(midiConnectionStatusProvider);

  if (mode == ClockMode.off) return;

  if (mode == ClockMode.master) {
    _startMasterClock(ref);
  }

  // Slave mode runs purely on incoming MIDI packets handled elsewhere.
  // We just keep this provider alive so consumers know clock is active.
});

void _startMasterClock(Ref ref) {
  Timer? clockTimer;
  Timer? transportDebounce;

  void startClock() {
    final bpm = ref.read(clockBpmProvider);
    // 24 ticks per quarter note
    // ms per tick = 60000 / (bpm * 24) = 2500 / bpm
    final periodMs = (2500.0 / bpm).clamp(5.0, 500.0);

    // Send start message
    _sendMidiByte(0xFA, ref);

    clockTimer = Timer.periodic(
      Duration(microseconds: (periodMs * 1000).round()),
      (_) {
        _sendMidiByte(0xF8, ref);
        final tickNotifier = ref.read(clockTickProvider.notifier);
        tickNotifier.state = (tickNotifier.state + 1) % 0xFFFFFF;
      },
    );

    ref.read(clockPlayingProvider.notifier).state = true;
    ref.read(clockTransportProvider.notifier).play();
  }

  void stopClock() {
    clockTimer?.cancel();
    clockTimer = null;
    _sendMidiByte(0xFC, ref);
    ref.read(clockPlayingProvider.notifier).state = false;
    ref.read(clockTransportProvider.notifier).stop();
  }

  // Listen to transport changes to start/stop clock
  void onTransportChange(bool? prev, bool next) {
    transportDebounce?.cancel();
    transportDebounce = Timer(const Duration(milliseconds: 10), () {
      if (next && clockTimer == null) {
        startClock();
      } else if (!next && clockTimer != null) {
        stopClock();
      }
    });
  }

  ref.listen(clockTransportProvider, onTransportChange);

  // Auto-start if transport is already playing when engine comes alive.
  if (ref.read(clockTransportProvider)) {
    startClock();
  }

  ref.onDispose(() {
    transportDebounce?.cancel();
    stopClock();
  });
}

void _sendMidiByte(int byte, Ref ref) {
  try {
    final device = ref.read(selectedMidiDeviceProvider);
    if (device == null) return;
    final command = MidiCommand();
    command.sendData(Uint8List.fromList([byte]), deviceId: device.id);
  } catch (e, st) {
    developer.log('MIDI clock send failed', error: e, stackTrace: st, name: 'open_synth.clock');
  }
}

// ── Slave Clock Handling ──────────────────────────────

/// Called from [midi_provider.dart] when a system-realtime byte arrives.
void handleMidiClockByte(int byte, Ref ref) {
  final mode = ref.read(clockModeProvider);
  if (mode != ClockMode.slave) return;

  switch (byte) {
    case 0xF8: // Clock tick
      _handleSlaveTick(ref);
      break;
    case 0xFA: // Start
      ref.read(clockTickProvider.notifier).state = 0;
      ref.read(clockPlayingProvider.notifier).state = true;
      ref.read(clockTransportProvider.notifier).play();
      break;
    case 0xFB: // Continue
      ref.read(clockPlayingProvider.notifier).state = true;
      ref.read(clockTransportProvider.notifier).play();
      break;
    case 0xFC: // Stop
      ref.read(clockPlayingProvider.notifier).state = false;
      ref.read(clockTransportProvider.notifier).stop();
      break;
    case 0xF6: // Active Sensing — ignore
      break;
  }
}

// Rolling window of last tick timestamps for BPM estimation.
final List<int> _tickHistory = [];

void _handleSlaveTick(Ref ref) {
  final now = DateTime.now().millisecondsSinceEpoch;
  _tickHistory.add(now);
  if (_tickHistory.length > 24) {
    _tickHistory.removeAt(0);
  }

  // Estimate BPM from average tick interval.
  if (_tickHistory.length >= 6) {
    var totalInterval = 0;
    for (int i = 1; i < _tickHistory.length; i++) {
      totalInterval += _tickHistory[i] - _tickHistory[i - 1];
    }
    final avgInterval = totalInterval / (_tickHistory.length - 1);
    if (avgInterval > 0) {
      final bpm = 60000.0 / (avgInterval * 24.0);
      ref.read(clockBpmProvider.notifier).state = bpm.clamp(30.0, 300.0);
    }
  }

  final tickNotifier = ref.read(clockTickProvider.notifier);
  tickNotifier.state = (tickNotifier.state + 1) % 0xFFFFFF;
}
