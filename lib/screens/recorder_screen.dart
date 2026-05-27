import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/midi_event.dart';
import '../providers/midi_recorder_provider.dart';
import '../providers/recording_layers_provider.dart';
import '../theme/synth_theme.dart';
import '../widgets/keyboard_widget.dart';
import '../widgets/recorder_panel.dart';

class RecorderScreen extends ConsumerWidget {
  const RecorderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isRecording = ref.watch(midiRecordingProvider);
    final events = ref.watch(midiRecorderEventsProvider);
    final overdubState = ref.watch(overdubRecordingStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RECORDER',
          style: GoogleFonts.orbitron(
            color: SynthTheme.orange,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          // Recording status indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: (isRecording || overdubState.isRecording)
                  ? Colors.redAccent.withValues(alpha: 0.15)
                  : SynthTheme.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: (isRecording || overdubState.isRecording)
                    ? Colors.redAccent.withValues(alpha: 0.5)
                    : SynthTheme.purple.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (isRecording || overdubState.isRecording)
                        ? Colors.redAccent
                        : SynthTheme.textSecondary.withValues(alpha: 0.3),
                    boxShadow: (isRecording || overdubState.isRecording)
                        ? [
                            BoxShadow(
                              color: Colors.redAccent.withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  (isRecording || overdubState.isRecording) ? 'REC' : 'IDLE',
                  style: TextStyle(
                    color: (isRecording || overdubState.isRecording)
                        ? Colors.redAccent
                        : SynthTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Scrollable recorder controls
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  const RecorderPanel(),
                  const SizedBox(height: 12),
                  // Event count summary
                  if (events.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: SynthTheme.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: SynthTheme.orange.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SESSION STATS',
                            style: TextStyle(
                              color: SynthTheme.orange,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _StatPill(
                                label: 'EVENTS',
                                value: '${events.length}',
                                color: SynthTheme.cyan,
                              ),
                              const SizedBox(width: 8),
                              _StatPill(
                                label: 'DURATION',
                                value: _formatDuration(events.last.timestampMs),
                                color: SynthTheme.magenta,
                              ),
                              const SizedBox(width: 8),
                              _StatPill(
                                label: 'NOTE ONS',
                                value: '${events.where((e) => e.type == MidiEventType.noteOn).length}',
                                color: SynthTheme.purple,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Fixed keyboard at bottom
          const KeyboardWidget(),
        ],
      ),
    );
  }

  String _formatDuration(int ms) {
    final secs = (ms / 1000).round();
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: SynthTheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: SynthTheme.textSecondary,
                fontSize: 8,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
