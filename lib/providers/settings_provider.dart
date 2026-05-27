import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Available audio buffer sizes in samples.
const List<int> _bufferSizes = [64, 128, 256, 512, 1024];

/// Currently selected audio buffer size.
final audioBufferSizeProvider = StateNotifierProvider<AudioBufferSizeNotifier, int>((ref) {
  return AudioBufferSizeNotifier();
});

class AudioBufferSizeNotifier extends StateNotifier<int> {
  AudioBufferSizeNotifier() : super(256) {
    _load();
  }

  Box? _box;

  void _load() {
    _box = Hive.box('open_synth');
    final stored = _box?.get('audio_buffer_size') as int?;
    if (stored != null && _bufferSizes.contains(stored)) {
      state = stored;
    }
  }

  void set(int size) {
    if (!_bufferSizes.contains(size)) return;
    state = size;
    _box?.put('audio_buffer_size', size);
  }

  List<int> get availableSizes => _bufferSizes;
}

/// Selected audio output device index (-1 = default device).
final selectedAudioDeviceProvider =
    StateNotifierProvider<SelectedAudioDeviceNotifier, int>((ref) {
  return SelectedAudioDeviceNotifier();
});

class SelectedAudioDeviceNotifier extends StateNotifier<int> {
  SelectedAudioDeviceNotifier() : super(-1) {
    _load();
  }

  Box? _box;

  void _load() {
    _box = Hive.box('open_synth');
    final stored = _box?.get('audio_device_index') as int?;
    if (stored != null) {
      state = stored;
    }
  }

  void select(int deviceIndex) {
    state = deviceIndex;
    _box?.put('audio_device_index', deviceIndex);
  }
}

/// Theme mode preference.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  Box? _box;

  void _load() {
    _box = Hive.box('open_synth');
    final stored = _box?.get('theme_mode') as String?;
    if (stored != null) {
      state = ThemeMode.values.firstWhere(
        (m) => m.name == stored,
        orElse: () => ThemeMode.dark,
      );
    }
  }

  void set(ThemeMode mode) {
    state = mode;
    _box?.put('theme_mode', mode.name);
  }

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    _box?.put('theme_mode', state.name);
  }
}
