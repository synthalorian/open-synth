import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Set of favorite preset IDs.
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});

/// Ordered list of favorite preset IDs (drag-reorderable).
final favoritesOrderProvider =
    Provider<List<String>>((ref) {
  return ref.watch(favoritesProvider.notifier).orderedFavorites;
});

/// Setlist: named collections of preset IDs for quick performance recall.
final setlistsProvider =
    StateNotifierProvider<SetlistsNotifier, Map<String, Setlist>>((ref) {
  return SetlistsNotifier();
});

/// Currently active setlist name.
final activeSetlistProvider = StateProvider<String?>((ref) => null);

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super({}) {
    _load();
  }

  Box? _box;
  List<String> _order = [];

  List<String> get orderedFavorites => _order.where((id) => state.contains(id)).toList();

  void _load() {
    _box = Hive.box('open_synth');
    final stored = _box?.get('favorite_preset_ids') as List?;
    if (stored != null) {
      state = stored.cast<String>().toSet();
    }
    final order = _box?.get('favorite_order') as List?;
    if (order != null) {
      _order = order.cast<String>().toList();
    }
  }

  void _save() {
    _box?.put('favorite_preset_ids', state.toList());
    _box?.put('favorite_order', _order.toList());
  }

  void toggle(String presetId) {
    if (state.contains(presetId)) {
      state = {...state}..remove(presetId);
      _order.remove(presetId);
    } else {
      state = {...state, presetId};
      if (!_order.contains(presetId)) {
        _order.add(presetId);
      }
    }
    _save();
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex--;
    final item = _order.removeAt(oldIndex);
    _order.insert(newIndex, item);
    _save();
  }

  bool isFavorite(String presetId) => state.contains(presetId);
}

/// A named collection of preset IDs for quick performance recall.
class Setlist {
  final String name;
  final List<String> presetIds;
  final DateTime createdAt;

  Setlist({
    required this.name,
    required this.presetIds,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Setlist copyWith({String? name, List<String>? presetIds}) {
    return Setlist(
      name: name ?? this.name,
      presetIds: presetIds ?? this.presetIds,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'presetIds': presetIds,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Setlist.fromJson(Map<String, dynamic> json) => Setlist(
        name: json['name'] as String,
        presetIds: (json['presetIds'] as List).cast<String>(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class SetlistsNotifier extends StateNotifier<Map<String, Setlist>> {
  SetlistsNotifier() : super({}) {
    _load();
  }

  Box? _box;

  void _load() {
    _box = Hive.box('open_synth');
    final stored = _box?.get('setlists');
    if (stored != null && stored is Map) {
      state = Map<String, Setlist>.from(
        stored.map(
          (k, v) => MapEntry(
            k as String,
            Setlist.fromJson(Map<String, dynamic>.from(v)),
          ),
        ),
      );
    }
  }

  void _save() {
    _box?.put(
      'setlists',
      state.map((k, v) => MapEntry(k, v.toJson())),
    );
  }

  void createSetlist(String name, [List<String>? presetIds]) {
    state = {...state, name: Setlist(name: name, presetIds: presetIds ?? [])};
    _save();
  }

  void deleteSetlist(String name) {
    state = {...state}..remove(name);
    _save();
  }

  void renameSetlist(String oldName, String newName) {
    final sl = state[oldName];
    if (sl == null) return;
    state = {...state}..remove(oldName);
    state = {...state, newName: sl.copyWith(name: newName)};
    _save();
  }

  void addToSetlist(String setName, String presetId) {
    final sl = state[setName];
    if (sl == null) return;
    if (sl.presetIds.contains(presetId)) return;
    state = {
      ...state,
      setName: sl.copyWith(presetIds: [...sl.presetIds, presetId]),
    };
    _save();
  }

  void removeFromSetlist(String setName, String presetId) {
    final sl = state[setName];
    if (sl == null) return;
    state = {
      ...state,
      setName: sl.copyWith(
        presetIds: sl.presetIds.where((id) => id != presetId).toList(),
      ),
    };
    _save();
  }

  void reorderSetlist(String setName, int oldIndex, int newIndex) {
    final sl = state[setName];
    if (sl == null || sl.presetIds.length < 2) return;
    if (oldIndex < 0 || oldIndex >= sl.presetIds.length) return;
    if (newIndex < 0 || newIndex >= sl.presetIds.length) return;
    final ids = [...sl.presetIds];
    final item = ids.removeAt(oldIndex);
    ids.insert(newIndex, item);
    state = {
      ...state,
      setName: sl.copyWith(presetIds: ids),
    };
    _save();
  }

  void updateSetlistOrder(String setName, List<String> newOrder) {
    final sl = state[setName];
    if (sl == null) return;
    state = {
      ...state,
      setName: sl.copyWith(presetIds: newOrder),
    };
    _save();
  }
}
