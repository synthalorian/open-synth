import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Set of favorite preset IDs.
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({}) {
    _load();
  }

  Box? _box;

  void _load() {
    _box = Hive.box('open_synth');
    final stored = _box?.get('favorite_preset_ids') as List?;
    if (stored != null) {
      state = stored.cast<String>().toSet();
    }
  }

  void _save() {
    _box?.put('favorite_preset_ids', state.toList());
  }

  void toggle(String presetId) {
    if (state.contains(presetId)) {
      state = {...state}..remove(presetId);
    } else {
      state = {...state, presetId};
    }
    _save();
  }

  bool isFavorite(String presetId) => state.contains(presetId);
}
