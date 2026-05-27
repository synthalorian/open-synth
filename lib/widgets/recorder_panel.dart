import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/midi_event.dart';
import '../models/recording_layer.dart';
import '../models/synth_preset.dart';
import '../providers/midi_recorder_provider.dart';
import '../providers/recording_layers_provider.dart';
import '../providers/synth_providers.dart';
import '../theme/synth_theme.dart';
import '../utils/audio_renderer.dart';
import '../utils/midi_file_reader.dart';

class RecorderPanel extends ConsumerStatefulWidget {
  const RecorderPanel({super.key});

  @override
  ConsumerState<RecorderPanel> createState() => _RecorderPanelState();
}

class _RecorderPanelState extends ConsumerState<RecorderPanel> {
  bool _showLayers = false;

  String _formatDuration(int ms) {
    final secs = (ms / 1000).round();
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = ref.watch(midiRecordingProvider);
    final events = ref.watch(midiRecorderEventsProvider);
    final savedSessions = ref.watch(savedSessionsProvider);
    final layers = ref.watch(recordingLayersProvider);
    final overdubState = ref.watch(overdubRecordingStateProvider);
    final preset = ref.watch(currentPresetProvider);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: overdubState.isRecording
              ? Colors.redAccent.withValues(alpha: 0.6)
              : isRecording
                  ? Colors.redAccent.withValues(alpha: 0.4)
                  : SynthTheme.orange.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: overdubState.isRecording
                      ? Colors.redAccent
                      : isRecording
                          ? Colors.redAccent
                          : SynthTheme.orange.withValues(alpha: 0.3),
                  boxShadow: (isRecording || overdubState.isRecording)
                      ? [
                          BoxShadow(
                            color: Colors.redAccent.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                overdubState.isRecording
                    ? 'OVERDUB RECORDING'
                    : 'SESSION RECORDER',
                style: TextStyle(
                  color: (isRecording || overdubState.isRecording)
                      ? Colors.redAccent
                      : SynthTheme.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              if (events.isNotEmpty)
                Text(
                  '${events.length} events  •  ${_formatDuration(events.last.timestampMs)}',
                  style: TextStyle(
                    color: SynthTheme.textSecondary,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Transport ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
              _RecBtn(
                icon: isRecording ? Icons.stop : Icons.fiber_manual_record,
                label: overdubState.isRecording
                    ? 'STOP OD'
                    : isRecording
                        ? 'STOP'
                        : 'REC',
                color: (isRecording || overdubState.isRecording)
                    ? Colors.redAccent
                    : Colors.redAccent,
                onTap: () {
                  if (overdubState.isRecording) {
                    // Stop overdub recording and create layer
                    _finalizeOverdubLayer(events, preset);
                    ref.read(overdubRecordingStateProvider.notifier).stopAll();
                    ref.read(midiRecorderEventsProvider.notifier).stopRecording();
                    ref.read(midiRecordingProvider.notifier).state = false;
                  } else if (isRecording) {
                    ref.read(midiRecordingProvider.notifier).state = false;
                    ref.read(midiRecorderEventsProvider.notifier).stopRecording();
                    // Auto-save session
                    if (events.isNotEmpty) {
                      final session = SavedSession(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        name: 'Session ${savedSessions.length + 1}',
                        createdAt: DateTime.now(),
                        durationMs: events.last.timestampMs,
                        events: List.from(events),
                      );
                      ref.read(savedSessionsProvider.notifier).addSession(session);
                    }
                  } else {
                    ref.read(midiRecorderEventsProvider.notifier).startRecording();
                    ref.read(midiRecordingProvider.notifier).state = true;
                  }
                },
              ),
              const SizedBox(width: 12),
              _RecBtn(
                icon: Icons.layers,
                label: 'OVERDUB',
                color: SynthTheme.magenta,
                onTap: layers.isEmpty || isRecording
                    ? null
                    : () {
                        // Start overdub: play existing layers, record new one
                        ref.read(midiRecorderEventsProvider.notifier).startRecording();
                        ref.read(midiRecordingProvider.notifier).state = true;
                        ref.read(overdubRecordingStateProvider.notifier).startRecording();
                      },
              ),
              const SizedBox(width: 12),
              _RecBtn(
                icon: Icons.save,
                label: 'EXPORT MIDI',
                color: SynthTheme.cyan,
                onTap: events.isEmpty
                    ? null
                    : () async {
                        final path = await exportRecordingToMidi(ref);
                        if (context.mounted) {
                          if (path != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('MIDI exported to $path'),
                                backgroundColor: SynthTheme.card,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Export failed'),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
              ),
              const SizedBox(width: 12),
              _RecBtn(
                icon: Icons.audiotrack,
                label: 'EXPORT WAV',
                color: SynthTheme.magenta,
                onTap: events.isEmpty
                    ? null
                    : () async {
                        final path = await exportMidiAsWav(
                          preset: preset,
                          events: events,
                          defaultName: '${preset.name}_render',
                        );
                        if (context.mounted) {
                          if (path != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('WAV exported to $path'),
                                backgroundColor: SynthTheme.card,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('WAV export failed or cancelled'),
                                backgroundColor: Colors.redAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
              ),
              const SizedBox(width: 12),
              _RecBtn(
                icon: Icons.file_upload_outlined,
                label: 'IMPORT',
                color: SynthTheme.cyan,
                onTap: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['mid', 'midi'],
                  );
                  if (result != null && result.files.single.path != null) {
                    final path = result.files.single.path!;
                    try {
                      final events = MidiFileReader.readEvents(path);
                      ref.read(midiRecorderEventsProvider.notifier).importEvents(events);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Imported ${events.length} events from "${result.files.single.name}"'),
                            backgroundColor: SynthTheme.card,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Import failed: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
              const SizedBox(width: 12),
              _RecBtn(
                icon: Icons.clear,
                label: 'CLEAR',
                color: SynthTheme.textSecondary,
                onTap: () => ref.read(midiRecorderEventsProvider.notifier).clear(),
              ),
            ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Layer Management ──
          if (layers.isNotEmpty) ...[
            Row(
              children: [
                GestureDetector(
                  onTap: () => setState(() => _showLayers = !_showLayers),
                  child: Row(
                    children: [
                      Icon(
                        _showLayers ? Icons.expand_less : Icons.expand_more,
                        color: SynthTheme.magenta,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${layers.length} LAYERS',
                        style: TextStyle(
                          color: SynthTheme.magenta,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _RecBtn(
                  icon: Icons.file_download,
                  label: 'EXPORT ALL',
                  color: SynthTheme.magenta,
                  onTap: layers.isEmpty
                      ? null
                      : () => _exportAllLayers(layers),
                ),
              ],
            ),
            if (_showLayers) ...[
              const SizedBox(height: 8),
              ...layers.reversed.take(8).map((layer) => _LayerTile(
                    layer: layer,
                    onDelete: () {
                      ref.read(recordingLayersProvider.notifier).removeLayer(layer.id);
                    },
                    onExport: () async {
                      final path = await FilePicker.platform.saveFile(
                        dialogTitle: 'Export Layer WAV',
                        fileName: '${layer.name}.wav',
                        type: FileType.custom,
                        allowedExtensions: ['wav'],
                      );
                      if (path != null) {
                        await renderMidiToWav(
                          preset: layer.preset,
                          events: layer.events,
                          outputPath: path,
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Layer "${layer.name}" exported'),
                              backgroundColor: SynthTheme.card,
                            ),
                          );
                        }
                      }
                    },
                  )),
            ],
          ],

          // ── Overdub Position ──
          if (overdubState.isPlaying || overdubState.isRecording) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sync,
                    color: Colors.redAccent,
                    size: 12,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    overdubState.isRecording
                        ? 'Recording layer on top of ${layers.length} existing...'
                        : 'Playing ${layers.length} layers...',
                    style: TextStyle(
                      color: Colors.redAccent.withValues(alpha: 0.8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Recent events log ──
          if (events.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0118),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: SynthTheme.orange.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LIVE EVENTS',
                    style: TextStyle(
                      color: SynthTheme.orange,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...events.reversed.take(6).map((e) {
                    String label;
                    switch (e.type) {
                      case MidiEventType.noteOn:
                        label = 'Note On  ${e.note}  vel ${e.velocity}';
                        break;
                      case MidiEventType.noteOff:
                        label = 'Note Off ${e.note}';
                        break;
                      case MidiEventType.cc:
                        label = 'CC ${e.ccNumber}  val ${e.ccValue}';
                        break;
                      case MidiEventType.programChange:
                        label = 'PC ${e.program}';
                        break;
                    }
                    return Text(
                      '${_formatDuration(e.timestampMs)}  $label',
                      style: TextStyle(
                        color: SynthTheme.textSecondary,
                        fontSize: 9,
                        fontFamily: 'monospace',
                        fontFamilyFallback: const ['monospace'],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],

          // ── Saved sessions ──
          if (savedSessions.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'SAVED SESSIONS',
              style: TextStyle(
                color: SynthTheme.orange,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 6),
            ...savedSessions.take(5).map((session) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${session.name}  •  ${_formatDuration(session.durationMs)}  •  ${session.events.length} events',
                        style: TextStyle(
                          color: SynthTheme.textSecondary,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref.read(savedSessionsProvider.notifier).deleteSession(session.id),
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent.withValues(alpha: 0.5),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  void _finalizeOverdubLayer(
      List<MidiEventRecord> events, SynthPreset preset) {
    if (events.isEmpty) return;
    final durationMs = events.last.timestampMs;
    final layerCount = ref.read(recordingLayersProvider).length;
    ref.read(recordingLayersProvider.notifier).finishRecording(
      name: 'Layer ${layerCount + 1}',
      preset: preset,
      events: events,
      durationMs: durationMs,
    );
  }

  Future<void> _exportAllLayers(List<RecordingLayer> layers) async {
    try {
      final dir = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Export All Layers',
      );
      if (dir == null) return;

      // Export each layer as separate WAV
      int exported = 0;
      for (final layer in layers) {
        if (layer.events.isEmpty) continue;
        final safeName = layer.name.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
        final outPath = '$dir/${safeName}_render.wav';
        final result = await renderMidiToWav(
          preset: layer.preset,
          events: layer.events,
          outputPath: outPath,
        );
        if (result != null) exported++;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exported $exported layers to $dir'),
          backgroundColor: SynthTheme.card,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

/// Export recorded MIDI events to a WAV audio file via offline rendering.
Future<String?> exportMidiAsWav({
  required SynthPreset preset,
  required List<MidiEventRecord> events,
  String defaultName = 'render',
}) async {
  final result = await FilePicker.platform.saveFile(
    dialogTitle: 'Export WAV Audio',
    fileName: '$defaultName.wav',
    type: FileType.custom,
    allowedExtensions: ['wav'],
  );
  if (result == null) return null;

  return renderMidiToWav(
    preset: preset,
    events: events,
    outputPath: result,
  );
}

/// A tile showing one recording layer with controls.
class _LayerTile extends ConsumerWidget {
  final RecordingLayer layer;
  final VoidCallback onDelete;
  final VoidCallback onExport;

  const _LayerTile({
    required this.layer,
    required this.onDelete,
    required this.onExport,
  });

  String _formatDuration(int ms) {
    final secs = (ms / 1000).round();
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: SynthTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: SynthTheme.magenta,
              boxShadow: [
                BoxShadow(
                  color: SynthTheme.magenta.withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  layer.name,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${layer.preset.name}  •  ${_formatDuration(layer.durationMs)}  •  ${layer.events.length} events',
                  style: TextStyle(
                    color: SynthTheme.textSecondary,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onExport,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: SynthTheme.magenta.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.file_download,
                color: SynthTheme.magenta,
                size: 14,
              ),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.delete_outline,
                color: Colors.redAccent.withValues(alpha: 0.6),
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _RecBtn({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.3,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: enabled ? 0.4 : 0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
