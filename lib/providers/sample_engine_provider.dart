import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ffi/sample_engine.dart';
import '../models/sample_preset.dart';
import '../data/sample_presets.dart';
import '../utils/logger.dart';
import '../utils/sample_path_resolver.dart';

/// The currently loaded sample preset (null if none loaded).
final samplePresetProvider = StateProvider<SamplePreset?>((ref) => null);

/// Whether a sample preset is currently loading.
final samplePresetLoadingProvider = StateProvider<bool>((ref) => false);

/// Loading progress (0.0 - 1.0) for sample preset loading.
final samplePresetLoadProgressProvider = StateProvider<double>((ref) => 0.0);

/// The active SampleEngine instance.
/// ONLY created when a sample preset is selected. Disposed when unloaded.
final sampleEngineProvider = Provider<SampleEngine?>((ref) {
  final preset = ref.watch(samplePresetProvider);
  if (preset == null) return null;

  SampleEngine engine;
  try {
    engine = SampleEngine.create();
  } catch (e) {
    appLogger.warning('Failed to create SampleEngine: $e');
    return null;
  }

  engine.setSampleRate(48000.0);
  engine.setBlockSize(256);

  // Load the SFZ file with platform-specific path resolution
  final sfzPath = resolveSamplePath(preset.sfzPath);
  appLogger.info('Loading SFZ: $sfzPath');
  final loaded = engine.loadSfzFile(sfzPath);
  if (!loaded) {
    appLogger.warning('Failed to load SFZ: $sfzPath (original: ${preset.sfzPath})');
    engine.dispose();
    return null;
  }
  appLogger.info('SFZ loaded: ${preset.name} (${engine.numRegions} regions, ${engine.numPreloadedSamples} preloaded)');

  ref.onDispose(() {
    appLogger.info('Disposing sample engine');
    engine.dispose();
  });
  return engine;
});

/// List of available bundled sample presets.
/// On desktop, filters out presets whose SFZ files cannot be resolved.
final availableSamplePresetsProvider = Provider<List<SamplePreset>>((ref) {
  if (!samplesAvailable) {
    return const [];
  }
  return bundledSamplePresets;
});

/// Currently selected sample category filter.
final sampleCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Filtered list of sample presets based on category.
final filteredSamplePresetsProvider = Provider<List<SamplePreset>>((ref) {
  final presets = ref.watch(availableSamplePresetsProvider);
  final filter = ref.watch(sampleCategoryFilterProvider);
  if (filter == null) return presets;
  return presets.where((p) => p.category == filter).toList();
});
