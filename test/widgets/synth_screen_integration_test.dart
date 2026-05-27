import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:open_synth/providers/synth_providers.dart';
import 'package:open_synth/screens/synth_screen.dart';
import 'package:open_synth/theme/synth_theme.dart';

/// Pump frames enough for the AnimatedSection staggered-entry animations
/// to complete (4 sections × 80ms stagger + 400ms animation).
Future<void> pumpUntilSettled(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 100));
}

Widget createTestApp() {
  return ProviderScope(
    overrides: [
      currentPresetProvider.overrideWith((ref) => CurrentPresetNotifier()),
    ],
    child: MaterialApp(
      theme: SynthTheme.darkTheme,
      home: const SynthScreen(),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await io.Directory.systemTemp.createTemp('hive_test_');
    Hive.init(dir.path);
    final box = await Hive.openBox('open_synth');
    await box.put('onboarding_completed', true);
  });

  group('SynthScreen Integration', () {
    testWidgets('renders main sections', (tester) async {
      await tester.pumpWidget(createTestApp());
      await pumpUntilSettled(tester);

      // Core UI sections should be present
      expect(find.text('OSC 1'), findsOneWidget);
      expect(find.text('OSC 2'), findsOneWidget);
      expect(find.text('FILTER'), findsOneWidget);
      expect(find.text('AMP ENV'), findsOneWidget);
      expect(find.text('FILTER ENV'), findsOneWidget);
      expect(find.text('LFO 1'), findsAtLeastNWidgets(1));
      expect(find.text('LFO 2'), findsOneWidget);
      expect(find.text('MASTER'), findsOneWidget);
      expect(find.text('PANIC'), findsOneWidget);
    });

    testWidgets('renders FX panel sections', (tester) async {
      await tester.pumpWidget(createTestApp());
      await pumpUntilSettled(tester);

      // Scroll down to FX panel
      await tester.scrollUntilVisible(
        find.text('PHASER'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('DRIVE'), findsOneWidget);
      expect(find.text('CHORUS'), findsOneWidget);
      expect(find.text('DELAY'), findsOneWidget);
      expect(find.text('REVERB'), findsOneWidget);
      expect(find.text('PHASER'), findsOneWidget);
      expect(find.text('FLANGER'), findsOneWidget);
      expect(find.text('COMPRESSOR'), findsOneWidget);
    });

    testWidgets('toggle FX enable buttons', (tester) async {
      await tester.pumpWidget(createTestApp());
      await pumpUntilSettled(tester);

      // Scroll to FX panel
      await tester.scrollUntilVisible(
        find.text('CHORUS'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Find the chorus toggle circle and tap it
      final chorusToggle = find.descendant(
        of: find.ancestor(
          of: find.text('CHORUS'),
          matching: find.byType(Container),
        ),
        matching: find.byType(GestureDetector),
      ).first;
      await tester.tap(chorusToggle);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Should still have CHORUS visible (still rendered, just state changed)
      expect(find.text('CHORUS'), findsOneWidget);
    });

    testWidgets('app bar has action buttons', (tester) async {
      await tester.pumpWidget(createTestApp());
      await pumpUntilSettled(tester);

      expect(find.byIcon(Icons.undo), findsOneWidget);
      expect(find.byIcon(Icons.redo), findsOneWidget);
      expect(find.byIcon(Icons.shuffle), findsOneWidget);
      expect(find.byIcon(Icons.keyboard), findsOneWidget);
      expect(find.byIcon(Icons.piano), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('scroll down to sequencer and mod matrix', (tester) async {
      await tester.pumpWidget(createTestApp());
      await pumpUntilSettled(tester);

      // Scroll down to bottom sections
      await tester.scrollUntilVisible(
        find.text('STEP SEQUENCER'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Clear'), findsOneWidget); // Sequencer control button
    });

    testWidgets('init patch button resets preset name', (tester) async {
      await tester.pumpWidget(createTestApp());
      await pumpUntilSettled(tester);

      final initButton = find.byIcon(Icons.refresh);
      expect(initButton, findsOneWidget);

      await tester.tap(initButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Should show snackbar confirming init patch
      expect(find.text('Loaded init patch'), findsOneWidget);
    });
  });
}
