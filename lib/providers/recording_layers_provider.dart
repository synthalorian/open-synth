import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:file_picker/file_picker.dart';

import '../models/midi_event.dart';
import '../models/recording_layer.dart';
import '../models/synth_preset.dart';
import '../utils/audio_renderer.dart';

// ── Recording Layers ─────────────────────────────────────────────────────────

final recordingLayersProvider =
    StateNotifierProvider<RecordingLayersNotifier, List<RecordingLayer>>((ref) {
  return RecordingLayersNotifier();
});

/// Whether we are currently overdub-recording (recording a new layer while
/// hearing previously recorded layers).
final isOverdubRecordingProvider = StateProvider<bool>((ref) => false);

/// Timing state for overdub recording.
final overdubRecordingStateProvider =
    StateNotifierProvider<OverdubRecordingStateNotifier, OverdubRecordingState>(
        (ref) {
  return OverdubRecordingStateNotifier();
});

class OverdubRecordingState {
  final bool isPlaying; // Are we playing back existing layers?
  final bool isRecording; // Are we recording a new layer?
  final int positionMs; // Current playback/recording position in ms
  final String? recordingLayerId; // ID of the layer being recorded

  const OverdubRecordingState({
    this.isPlaying = false,
    this.isRecording = false,
    this.positionMs = 0,
    this.recordingLayerId,
  });

  OverdubRecordingState copyWith({
    bool? isPlaying,
    bool? isRecording,
    int? positionMs,
    String? recordingLayerId,
  }) {
    return OverdubRecordingState(
      isPlaying: isPlaying ?? this.isPlaying,
      isRecording: isRecording ?? this.isRecording,
      positionMs: positionMs ?? this.positionMs,
      recordingLayerId: recordingLayerId ?? this.recordingLayerId,
    );
  }
}

class OverdubRecordingStateNotifier
    extends StateNotifier<OverdubRecordingState> {
  OverdubRecordingStateNotifier() : super(const OverdubRecordingState());

  Timer? _positionTimer;
  DateTime? _startTime;

  void startPlayback({required int totalDurationMs}) {
    _startTime = DateTime.now();
    state = state.copyWith(isPlaying: true, isRecording: false, positionMs: 0);

    _positionTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (_startTime == null) return;
      final elapsed = DateTime.now().difference(_startTime!).inMilliseconds;
      if (!state.isPlaying && !state.isRecording) {
        _positionTimer?.cancel();
        return;
      }
      if (elapsed >= totalDurationMs) {
        _startTime = DateTime.now();
        state = state.copyWith(positionMs: 0);
      } else {
        state = state.copyWith(positionMs: elapsed);
      }
    });
  }

  void startRecording() {
    state = state.copyWith(
      isPlaying: true,
      isRecording: true,
      recordingLayerId: 'layer_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  void stopRecording({int? finalDurationMs}) {
    state = state.copyWith(isRecording: false, recordingLayerId: null);
    if (finalDurationMs != null) {
      state = state.copyWith(positionMs: finalDurationMs);
    }
  }

  void stopAll() {
    _startTime = null;
    _positionTimer?.cancel();
    _positionTimer = null;
    state = const OverdubRecordingState();
  }

  @override
  void dispose() {
    _positionTimer?.cancel();
    super.dispose();
  }
}

class RecordingLayersNotifier extends StateNotifier<List<RecordingLayer>> {
  RecordingLayersNotifier() : super([]) {
    _load();
  }

  Box? _box;

  Future<void> _load() async {
    _box = Hive.box('open_synth');
    final stored = _box?.get('recording_layers') as List?;
    if (stored != null) {
      try {
        state = stored
            .map((e) => RecordingLayer.fromJson(
                Map<String, dynamic>.from(jsonDecode(e as String))))
            .toList();
      } catch (e) {
        developer.log('Failed to load recording layers',
            error: e, name: 'open_synth.layers');
        state = [];
      }
    }
  }

  void _save() {
    _box?.put('recording_layers',
        state.map((l) => jsonEncode(l.toJson())).toList());
  }

  void addLayer(RecordingLayer layer) {
    state = [...state, layer];
    _save();
  }

  void removeLayer(String id) {
    state = state.where((l) => l.id != id).toList();
    _save();
  }

  void updateLayer(RecordingLayer layer) {
    state = [
      for (final l in state)
        if (l.id == layer.id) layer else l,
    ];
    _save();
  }

  void clear() {
    state = [];
    _save();
  }

  /// Finalize a recording pass: commit the events to a new layer.
  RecordingLayer finishRecording({
    required String name,
    required SynthPreset preset,
    required List<MidiEventRecord> events,
    required int durationMs,
  }) {
    final layer = RecordingLayer(
      id: 'layer_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      createdAt: DateTime.now(),
      preset: preset,
      events: List.from(events),
      durationMs: durationMs,
    );
    addLayer(layer);
    return layer;
  }
}

// ── Combined WAV Export ──────────────────────────────────────────────────────

/// Export all layers as separate WAV files, one per layer.
/// Returns list of file paths that were written.
Future<List<String>> exportLayersAsSeparateWavs({
  required List<RecordingLayer> layers,
  required String directory,
}) async {
  final paths = <String>[];
  for (final layer in layers) {
    if (layer.events.isEmpty) continue;
    final safeName = layer.name.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
    final outPath = '$directory/${safeName}_render.wav';
    final result = await renderMidiToWav(
      preset: layer.preset,
      events: layer.events,
      outputPath: outPath,
    );
    if (result != null) {
      paths.add(result);
    }
  }
  return paths;
}

/// Export all layers as one stereo WAV mixed together.
/// Renders each layer, reads the WAVs back, mixes them, and writes the result.
Future<String?> exportLayersAsMixedWav({
  required List<RecordingLayer> layers,
  String defaultName = 'full_mix',
}) async {
  if (layers.isEmpty) return null;

  final result = await FilePicker.platform.saveFile(
    dialogTitle: 'Export Mixed WAV',
    fileName: '$defaultName.wav',
    type: FileType.custom,
    allowedExtensions: ['wav'],
  );
  if (result == null) return null;

  final tempDir = Directory.systemTemp.createTempSync('open_synth_mix_');
  try {
    // Render each layer to a temp WAV
    final tempFiles = <String>[];
    for (final layer in layers) {
      if (layer.events.isEmpty) continue;
      final tempPath = '${tempDir.path}/${layer.id}.wav';
      final rendered = await renderMidiToWav(
        preset: layer.preset,
        events: layer.events,
        outputPath: tempPath,
      );
      if (rendered != null) {
        tempFiles.add(rendered);
      }
    }

    if (tempFiles.isEmpty) return null;

    // Read all WAVs and find the longest
    final buffers = <List<double>>[];
    int maxLen = 0;
    for (final f in tempFiles) {
      final buf = await _readWavAsFloats(f);
      buffers.add(buf);
      if (buf.length > maxLen) maxLen = buf.length;
    }

    // Mix with per-layer normalization
    final mixed = List<double>.filled(maxLen, 0.0);
    final numLayers = buffers.length;
    for (int li = 0; li < numLayers; li++) {
      final buf = buffers[li];
      final gain = 1.0 / numLayers;
      for (int i = 0; i < buf.length; i++) {
        mixed[i] += buf[i] * gain;
      }
    }

    // Write mixed WAV
    await _writeFloatsAsWav(mixed, result, sampleRate: 44100);
    return result;
  } catch (e, st) {
    developer.log('Mixed WAV export failed',
        error: e, stackTrace: st, name: 'open_synth.layers');
    return null;
  } finally {
    // Cleanup temp dir
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  }
}

/// Read a 16-bit mono WAV file into a list of float samples (-1..1).
Future<List<double>> _readWavAsFloats(String path) async {
  final file = File(path);
  final bytes = await file.readAsBytes();
  if (bytes.length < 44) return [];

  final samples = <double>[];
  for (int i = 44; i + 1 < bytes.length; i += 2) {
    final sample = (bytes[i] | (bytes[i + 1] << 8)).toSigned(16);
    samples.add(sample / 32768.0);
  }
  return samples;
}

/// Write a list of float samples as a 16-bit mono WAV file.
Future<void> _writeFloatsAsWav(
    List<double> samples, String path,
    {int sampleRate = 44100}) async {
  final bytes = <int>[];
  final dataSize = samples.length * 2;

  // RIFF header
  bytes.addAll([0x52, 0x49, 0x46, 0x46]); // "RIFF"
  _writeInt32(bytes, 36 + dataSize);
  bytes.addAll([0x57, 0x41, 0x56, 0x45]); // "WAVE"

  // fmt chunk
  bytes.addAll([0x66, 0x6D, 0x74, 0x20]); // "fmt "
  _writeInt32(bytes, 16);
  _writeInt16(bytes, 1); // PCM
  _writeInt16(bytes, 1); // mono
  _writeInt32(bytes, sampleRate);
  _writeInt32(bytes, sampleRate * 2);
  _writeInt16(bytes, 2); // block align
  _writeInt16(bytes, 16); // bits per sample

  // data chunk
  bytes.addAll([0x64, 0x61, 0x74, 0x61]); // "data"
  _writeInt32(bytes, dataSize);

  // Samples
  for (final sample in samples) {
    final clamped = (sample * 32767).clamp(-32768, 32767).round();
    _writeInt16(bytes, clamped);
  }

  await File(path).writeAsBytes(bytes);
}

void _writeInt16(List<int> bytes, int value) {
  bytes.add(value & 0xFF);
  bytes.add((value >> 8) & 0xFF);
}

void _writeInt32(List<int> bytes, int value) {
  bytes.add(value & 0xFF);
  bytes.add((value >> 8) & 0xFF);
  bytes.add((value >> 16) & 0xFF);
  bytes.add((value >> 24) & 0xFF);
}
