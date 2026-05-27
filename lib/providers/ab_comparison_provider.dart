import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/mod_matrix.dart';
import '../models/synth_preset.dart';

/// Full patch snapshot for A/B comparison.
class PatchSnapshot {
  final SynthPreset preset;
  final List<ModMatrixSlot> modSlots;
  final DateTime createdAt;

  const PatchSnapshot({
    required this.preset,
    required this.modSlots,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'preset': preset.toJson(),
        'modSlots': modSlots.map((s) => s.toJson()).toList(),
        'createdAt': createdAt.millisecondsSinceEpoch,
      };

  factory PatchSnapshot.fromJson(Map<String, dynamic> json) => PatchSnapshot(
        preset: SynthPreset.fromJson(
            Map<String, dynamic>.from(json['preset'] as Map)),
        modSlots: (json['modSlots'] as List)
            .map((e) => ModMatrixSlot.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            json['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      );
}

/// Holds snapshot A and B plus the active bank.
class ABComparisonState {
  final PatchSnapshot? snapshotA;
  final PatchSnapshot? snapshotB;
  final bool isBankA;

  const ABComparisonState({
    this.snapshotA,
    this.snapshotB,
    this.isBankA = true,
  });

  PatchSnapshot? get activeSnapshot => isBankA ? snapshotA : snapshotB;
  PatchSnapshot? get inactiveSnapshot => isBankA ? snapshotB : snapshotA;

  ABComparisonState copyWith({
    PatchSnapshot? snapshotA,
    PatchSnapshot? snapshotB,
    bool? isBankA,
  }) {
    return ABComparisonState(
      snapshotA: snapshotA ?? this.snapshotA,
      snapshotB: snapshotB ?? this.snapshotB,
      isBankA: isBankA ?? this.isBankA,
    );
  }

  Map<String, dynamic> toJson() => {
        'snapshotA': snapshotA?.toJson(),
        'snapshotB': snapshotB?.toJson(),
        'isBankA': isBankA,
      };

  factory ABComparisonState.fromJson(Map<String, dynamic> json) {
    return ABComparisonState(
      snapshotA: json['snapshotA'] != null
          ? PatchSnapshot.fromJson(
              Map<String, dynamic>.from(json['snapshotA'] as Map))
          : null,
      snapshotB: json['snapshotB'] != null
          ? PatchSnapshot.fromJson(
              Map<String, dynamic>.from(json['snapshotB'] as Map))
          : null,
      isBankA: json['isBankA'] as bool? ?? true,
    );
  }
}

final abComparisonProvider =
    StateNotifierProvider<ABComparisonNotifier, ABComparisonState>((ref) {
  return ABComparisonNotifier();
});

class ABComparisonNotifier extends StateNotifier<ABComparisonState> {
  ABComparisonNotifier() : super(const ABComparisonState()) {
    _load();
  }

  Box? _box;

  Future<void> _load() async {
    _box = Hive.box('open_synth');
    final stored = _box?.get('abComparison');
    if (stored != null) {
      try {
        state = ABComparisonState.fromJson(
          Map<String, dynamic>.from(jsonDecode(stored as String)),
        );
      } catch (_) {
        // Fall back to defaults
      }
    }
  }

  void _save() {
    _box?.put('abComparison', jsonEncode(state.toJson()));
  }

  /// Capture the current preset + mod matrix into the active bank.
  void captureCurrent(SynthPreset preset, List<ModMatrixSlot> modSlots) {
    final snapshot = PatchSnapshot(
      preset: preset,
      modSlots: modSlots,
      createdAt: DateTime.now(),
    );
    state = state.isBankA
        ? state.copyWith(snapshotA: snapshot)
        : state.copyWith(snapshotB: snapshot);
    _save();
  }

  /// Switch between bank A and bank B.
  void toggleBank() {
    state = state.copyWith(isBankA: !state.isBankA);
    _save();
  }

  /// Select bank A.
  void selectBankA() => state = state.copyWith(isBankA: true);

  /// Select bank B.
  void selectBankB() => state = state.copyWith(isBankA: false);

  /// Capture into a specific bank (A or B) without switching the active bank.
  void captureToBank(SynthPreset preset, List<ModMatrixSlot> modSlots, bool bankA) {
    final snapshot = PatchSnapshot(
      preset: preset,
      modSlots: modSlots,
      createdAt: DateTime.now(),
    );
    state = bankA
        ? state.copyWith(snapshotA: snapshot)
        : state.copyWith(snapshotB: snapshot);
    _save();
  }

  /// Clear both snapshots.
  void clear() {
    state = const ABComparisonState();
    _save();
  }
}
