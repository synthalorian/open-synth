import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/midi_provider.dart';
import '../theme/synth_theme.dart';

/// Compact MIDI device selector and status panel.
class _MidiOutputTest extends StatefulWidget {
  final WidgetRef ref;
  const _MidiOutputTest({required this.ref});

  @override
  State<_MidiOutputTest> createState() => _MidiOutputTestState();
}

class _MidiOutputTestState extends State<_MidiOutputTest> {
  int _testCc = 1;
  int _testValue = 64;
  bool _isSending = false;

  void _sendTestPulse() {
    if (_isSending) return;
    setState(() => _isSending = true);
    sendMidiCc(widget.ref, 0, _testCc, _testValue);
    Timer(const Duration(milliseconds: 400), () {
      sendMidiCc(widget.ref, 0, _testCc, 0);
      if (mounted) setState(() => _isSending = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SynthTheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SynthTheme.orange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.send, color: SynthTheme.orange, size: 14),
              const SizedBox(width: 6),
              Text(
                'OUTPUT TEST',
                style: TextStyle(
                  color: SynthTheme.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CC Number', style: TextStyle(color: SynthTheme.textSecondary, fontSize: 9)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: SynthTheme.card,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.2)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isDense: true,
                          value: _testCc,
                          dropdownColor: SynthTheme.card,
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                          icon: Icon(Icons.arrow_drop_down, color: SynthTheme.orange, size: 16),
                          items: [
                            const DropdownMenuItem(value: 1, child: Text('CC 1 — Mod Wheel')),
                            const DropdownMenuItem(value: 7, child: Text('CC 7 — Volume')),
                            const DropdownMenuItem(value: 10, child: Text('CC 10 — Pan')),
                            const DropdownMenuItem(value: 11, child: Text('CC 11 — Expression')),
                            const DropdownMenuItem(value: 64, child: Text('CC 64 — Sustain')),
                            const DropdownMenuItem(value: 74, child: Text('CC 74 — Cutoff')),
                            const DropdownMenuItem(value: 71, child: Text('CC 71 — Resonance')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _testCc = v);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Value: $_testValue', style: TextStyle(color: SynthTheme.textSecondary, fontSize: 9)),
                    Slider(
                      value: _testValue.toDouble(),
                      min: 0,
                      max: 127,
                      divisions: 127,
                      activeColor: SynthTheme.orange,
                      inactiveColor: SynthTheme.purple.withValues(alpha: 0.15),
                      onChanged: (v) => setState(() => _testValue = v.round()),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _sendTestPulse,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _isSending
                          ? SynthTheme.orange.withValues(alpha: 0.3)
                          : SynthTheme.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: SynthTheme.orange.withValues(alpha: 0.4)),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _isSending ? 'SENDING...' : 'SEND TEST PULSE',
                      style: TextStyle(
                        color: SynthTheme.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => sendMidiCc(widget.ref, 0, _testCc, _testValue),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: SynthTheme.card,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.25)),
                  ),
                  child: Text(
                    'SEND STATIC',
                    style: TextStyle(
                      color: SynthTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MidiPanel extends ConsumerWidget {
  const MidiPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(midiDevicesProvider);
    final selectedDevice = ref.watch(selectedMidiDeviceProvider);
    final isConnected = ref.watch(midiConnectionStatusProvider);
    final eventLog = ref.watch(midiEventLogProvider);

    // Keep the MIDI listener alive while this panel is visible.
    ref.watch(midiListenerProvider);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: SynthTheme.cyan.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.usb,
                color: isConnected ? SynthTheme.cyan : SynthTheme.textSecondary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'MIDI INPUT',
                style: TextStyle(
                  color: isConnected ? SynthTheme.cyan : SynthTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              // Connection status dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected ? SynthTheme.cyan : Colors.redAccent,
                  boxShadow: [
                    BoxShadow(
                      color: (isConnected ? SynthTheme.cyan : Colors.redAccent)
                          .withValues(alpha: 0.6),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isConnected ? 'CONNECTED' : 'OFFLINE',
                style: TextStyle(
                  color: isConnected ? SynthTheme.cyan : Colors.redAccent,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          devicesAsync.when(
            data: (devices) {
              if (devices.isEmpty) {
                return Text(
                  'No MIDI devices detected.\nPlug in a USB MIDI keyboard and wait a moment.',
                  style: TextStyle(
                    color: SynthTheme.textSecondary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                );
              }

              final dropdownItems = [
                const DropdownMenuItem<MidiDevice?>(
                  value: null,
                  child: Text('None'),
                ),
                ...devices.map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(
                        d.name,
                        style: const TextStyle(fontSize: 12),
                      ),
                    )),
              ];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: SynthTheme.surface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: SynthTheme.cyan.withValues(alpha: 0.2),
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<MidiDevice?>(
                        isExpanded: true,
                        value: selectedDevice,
                        dropdownColor: SynthTheme.surface,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down,
                          color: SynthTheme.cyan.withValues(alpha: 0.5),
                          size: 18,
                        ),
                        items: dropdownItems,
                        onChanged: (device) {
                          ref.read(selectedMidiDeviceProvider.notifier).state = device;
                        },
                      ),
                    ),
                  ),
                  if (eventLog.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0118),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: SynthTheme.purple.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EVENT LOG',
                            style: TextStyle(
                              color: SynthTheme.purple,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...eventLog.take(5).map((e) => Text(
                                e,
                                style: TextStyle(
                                  color: SynthTheme.textSecondary,
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  fontFamilyFallback: const ['monospace'],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  // ── Output Test Utility ──
                  _MidiOutputTest(ref: ref),
                ],
              );
            },
            loading: () => SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(SynthTheme.cyan),
              ),
            ),
            error: (err, _) => Text(
              'MIDI error: $err',
              style: TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
