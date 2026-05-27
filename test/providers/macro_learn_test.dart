import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:open_synth/models/macro_config.dart';
import 'package:open_synth/providers/macro_provider.dart';

void main() {
  late Box box;

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('open_synth_test');
    Hive.init(tempDir.path);
    box = await Hive.openBox('open_synth');
  });

  setUp(() {
    box.clear();
  });
  group('macroLearnModeProvider', () {
    test('initial state is -1 (no macro in learn mode)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final learnMode = container.read(macroLearnModeProvider);
      expect(learnMode, -1);
    });

    test('entering learn mode sets the correct macro index', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(macroLearnModeProvider.notifier).state = 2;
      expect(container.read(macroLearnModeProvider), 2);
    });

    test('exiting learn mode resets to -1', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(macroLearnModeProvider.notifier).state = 1;
      container.read(macroLearnModeProvider.notifier).state = -1;
      expect(container.read(macroLearnModeProvider), -1);
    });

    test('toggling same macro index exits learn mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(macroLearnModeProvider.notifier);
      notifier.state = 0;

      // Simulate toggle: if current == target, set to -1
      final current = container.read(macroLearnModeProvider);
      if (current == 0) {
        notifier.state = -1;
      }
      expect(container.read(macroLearnModeProvider), -1);
    });
  });

  group('MacroBankNotifier', () {
    test('default bank has 4 macros with sensible defaults', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final bank = container.read(macroBankProvider);
      expect(bank.macros.length, 4);
      expect(bank.getMacro(0).name, 'Cutoff');
      expect(bank.getMacro(1).name, 'Resonance');
      expect(bank.getMacro(2).name, 'LFO Depth');
      expect(bank.getMacro(3).name, 'Drive');
    });

    test('setMacroCc updates the correct macro CC number', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(macroBankProvider.notifier);
      notifier.setMacroCc(1, 74);

      final bank = container.read(macroBankProvider);
      expect(bank.getMacro(1).ccNumber, 74);
    });

    test('setMacroName updates the correct macro name', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(macroBankProvider.notifier);
      notifier.setMacroName(0, 'Filter Cut');

      final bank = container.read(macroBankProvider);
      expect(bank.getMacro(0).name, 'Filter Cut');
    });

    test('setMacroValue clamps to min/max range', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(macroBankProvider.notifier);
      // Default Cutoff range is 20-20000
      notifier.setMacroValue(0, 50000);
      expect(container.read(macroBankProvider).getMacro(0).value, 20000);

      notifier.setMacroValue(0, -100);
      expect(container.read(macroBankProvider).getMacro(0).value, 20);
    });

    test('resetAll restores factory defaults', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(macroBankProvider.notifier);
      notifier.setMacroCc(0, 99);
      notifier.setMacroName(0, 'Custom');
      notifier.resetAll();

      final bank = container.read(macroBankProvider);
      expect(bank.getMacro(0).ccNumber, 74);
      expect(bank.getMacro(0).name, 'Cutoff');
    });
  });

  group('MacroConfig model', () {
    test('copyWith preserves unchanged fields', () {
      const macro = MacroConfig(
        name: 'Test',
        ccNumber: 10,
        minValue: 0,
        maxValue: 100,
        value: 50,
      );
      final updated = macro.copyWith(value: 75);
      expect(updated.name, 'Test');
      expect(updated.ccNumber, 10);
      expect(updated.minValue, 0);
      expect(updated.maxValue, 100);
      expect(updated.value, 75);
    });

    test('toJson / fromJson roundtrip preserves values', () {
      const macro = MacroConfig(
        name: 'Resonance',
        ccNumber: 71,
        minValue: 0.0,
        maxValue: 1.0,
        value: 0.5,
      );
      final json = macro.toJson();
      final restored = MacroConfig.fromJson(json);
      expect(restored.name, macro.name);
      expect(restored.ccNumber, macro.ccNumber);
      expect(restored.minValue, macro.minValue);
      expect(restored.maxValue, macro.maxValue);
      expect(restored.value, macro.value);
    });
  });
}
