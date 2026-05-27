import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Ordered list of recently used preset IDs (most recent first).
final recentPresetsProvider =
    StateNotifierProvider<RecentPresetsNotifier, List<String>>((ref) {
  return RecentPresetsNotifier();
});

class RecentPresetsNotifier extends StateNotifier<List<String>> {
  RecentPresetsNotifier() : super([]) {
    _load();
  }

  static const int _maxRecent = 30;
  Box? _box;

  void _load() {
    _box = Hive.box('open_synth');
    final stored = _box?.get('recent_preset_ids') as List?;
    if (stored != null) {
      state = stored.cast<String>().toList();
    }
  }

  void _save() {
    _box?.put('recent_preset_ids', state.toList());
  }

  /// Record that a preset was just used. Moves it to front if already present,
  /// or inserts at front if new. Trims to max length.
  void track(String presetId) {
    final updated = [...state];
    updated.remove(presetId);
    updated.insert(0, presetId);
    if (updated.length > _maxRecent) {
      updated.removeRange(_maxRecent, updated.length);
    }
    state = updated;
    _save();
  }

  void clear() {
    state = [];
    _save();
  }

  /// Remove a specific preset ID from recents.
  void untrack(String presetId) {
    final updated = state.where((id) => id != presetId).toList();
    if (updated.length != state.length) {
      state = updated;
      _save();
    }
  }
}
