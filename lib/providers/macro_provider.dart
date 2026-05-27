import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import '../models/macro_config.dart';
import '../models/mod_matrix.dart';
import 'midi_provider.dart';
import 'mod_matrix_provider.dart';

final macroBankProvider =
    StateNotifierProvider<MacroBankNotifier, MacroBank>((ref) {
  return MacroBankNotifier(ref);
});

/// Which macro index is currently in MIDI-learn mode (-1 = none).
final macroLearnModeProvider = StateProvider<int>((ref) => -1);

class MacroBankNotifier extends StateNotifier<MacroBank> {
  MacroBankNotifier(this._ref) : super(const MacroBank()) {
    _load();
  }

  final Ref _ref;
  Box? _box;

  Future<void> _load() async {
    _box = Hive.box('open_synth');
    final stored = _box?.get('macroBank');
    if (stored != null) {
      try {
        state = MacroBank.fromJson(
          Map<String, dynamic>.from(jsonDecode(stored as String)),
        );
      } catch (_) {
        // Fall back to defaults
      }
    }
  }

  void _save() {
    _box?.put('macroBank', jsonEncode(state.toJson()));
  }

  void updateMacro(int index, MacroConfig Function(MacroConfig) updater) {
    final macro = state.getMacro(index);
    final newMacro = updater(macro);
    state = state.copyWithMacro(index, newMacro);
    _save();
  }

  void setMacroValue(int index, double value) {
    final macro = state.getMacro(index);
    final clamped = value.clamp(macro.minValue, macro.maxValue);
    updateMacro(index, (m) => m.copyWith(value: clamped));
    _updateModSource(index, macro);
    _sendMacroCc(index, clamped, macro);
  }

  void _sendMacroCc(int index, double value, MacroConfig macro) {
    if (macro.ccNumber < 0) return; // unassigned — don't send spurious CC 0
    final normalized = ((value - macro.minValue) /
            (macro.maxValue - macro.minValue))
        .clamp(0.0, 1.0);
    final midiValue = (normalized * 127).round();
    sendMidiCc(_ref, 0, macro.ccNumber, midiValue);
  }

  void _updateModSource(int index, MacroConfig macro) {
    final normalized = (macro.value - macro.minValue) /
        (macro.maxValue - macro.minValue);
    final modSource = switch (index) {
      0 => ModSource.macro1,
      1 => ModSource.macro2,
      2 => ModSource.macro3,
      3 => ModSource.macro4,
      _ => null,
    };
    if (modSource == null) return;
    final values = Map<ModSource, double>.from(_ref.read(modSourceValuesProvider));
    values[modSource] = normalized.clamp(0.0, 1.0);
    _ref.read(modSourceValuesProvider.notifier).state = values;
  }

  void setMacroName(int index, String name) {
    updateMacro(index, (m) => m.copyWith(name: name));
  }

  void setMacroCc(int index, int cc) {
    updateMacro(index, (m) => m.copyWith(ccNumber: cc));
  }

  void setMacroRange(int index, double min, double max) {
    updateMacro(index, (m) => m.copyWith(minValue: min, maxValue: max));
  }

  void resetAll() {
    state = const MacroBank();
    _save();
  }
}
