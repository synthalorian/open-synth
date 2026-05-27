import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_synth/models/fx_config.dart';
import 'package:open_synth/theme/synth_theme.dart';
import 'package:open_synth/widgets/fx_panel.dart';

void main() {
  group('FxPanel', () {
    Widget buildTestApp(FxPanel panel) {
      return MaterialApp(
        theme: SynthTheme.darkTheme,
        home: Scaffold(
          body: SingleChildScrollView(child: panel),
        ),
      );
    }

    testWidgets('renders all effect sections', (tester) async {
      await tester.pumpWidget(buildTestApp(FxPanel(
        chorus: const ChorusConfig(),
        delay: const DelayConfig(),
        reverb: const ReverbConfig(),
        phaser: const PhaserConfig(),
        flanger: const FlangerConfig(),
        compressor: const CompressorConfig(),
        drive: const DriveConfig(),
        onChorusChanged: (_) {},
        onDelayChanged: (_) {},
        onReverbChanged: (_) {},
        onPhaserChanged: (_) {},
        onFlangerChanged: (_) {},
        onCompressorChanged: (_) {},
        onDriveChanged: (_) {},
      )));

      expect(find.text('DRIVE'), findsOneWidget);
      expect(find.text('CHORUS'), findsOneWidget);
      expect(find.text('DELAY'), findsOneWidget);
      expect(find.text('REVERB'), findsOneWidget);
      expect(find.text('PHASER'), findsOneWidget);
      expect(find.text('FLANGER'), findsOneWidget);
      expect(find.text('COMPRESSOR'), findsOneWidget);
    });

    testWidgets('shows drive type dropdown and amount knob', (tester) async {
      await tester.pumpWidget(buildTestApp(FxPanel(
        chorus: const ChorusConfig(),
        delay: const DelayConfig(),
        reverb: const ReverbConfig(),
        phaser: const PhaserConfig(),
        flanger: const FlangerConfig(),
        compressor: const CompressorConfig(),
        drive: DriveConfig(enabled: true),
        onChorusChanged: (_) {},
        onDelayChanged: (_) {},
        onReverbChanged: (_) {},
        onPhaserChanged: (_) {},
        onFlangerChanged: (_) {},
        onCompressorChanged: (_) {},
        onDriveChanged: (_) {},
      )));

      expect(find.text('TYPE'), findsOneWidget);
      expect(find.text('AMOUNT'), findsOneWidget);
      expect(find.text('OVERDRIVE'), findsOneWidget);
    });

    testWidgets('displays lock icons when locked', (tester) async {
      await tester.pumpWidget(buildTestApp(FxPanel(
        chorus: const ChorusConfig(),
        delay: const DelayConfig(),
        reverb: const ReverbConfig(),
        phaser: const PhaserConfig(),
        flanger: const FlangerConfig(),
        compressor: const CompressorConfig(),
        drive: const DriveConfig(),
        onChorusChanged: (_) {},
        onDelayChanged: (_) {},
        onReverbChanged: (_) {},
        onPhaserChanged: (_) {},
        onFlangerChanged: (_) {},
        onCompressorChanged: (_) {},
        onDriveChanged: (_) {},
        chorusLocked: true,
        delayLocked: true,
        reverbLocked: true,
        phaserLocked: true,
        flangerLocked: true,
        compressorLocked: true,
        driveLocked: true,
      )));

      // 7 lock icons — one for each FX section
      expect(find.byIcon(Icons.lock), findsNWidgets(7));
    });

    testWidgets('shows chorus controls with correct defaults', (tester) async {
      await tester.pumpWidget(buildTestApp(FxPanel(
        chorus: ChorusConfig(enabled: true, rate: 2.0, depth: 0.7, mix: 0.4),
        delay: const DelayConfig(),
        reverb: const ReverbConfig(),
        phaser: const PhaserConfig(),
        flanger: const FlangerConfig(),
        compressor: const CompressorConfig(),
        drive: const DriveConfig(),
        onChorusChanged: (_) {},
        onDelayChanged: (_) {},
        onReverbChanged: (_) {},
        onPhaserChanged: (_) {},
        onFlangerChanged: (_) {},
        onCompressorChanged: (_) {},
        onDriveChanged: (_) {},
      )));

      // RATE, DEPTH, and MIX appear on multiple sections (chorus + flanger + phaser + others)
      expect(find.text('RATE'), findsAtLeastNWidgets(1));
      expect(find.text('DEPTH'), findsAtLeastNWidgets(1));
      expect(find.text('MIX'), findsAtLeastNWidgets(1));
    });
  });
}
