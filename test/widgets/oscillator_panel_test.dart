import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_synth/models/oscillator.dart';
import 'package:open_synth/models/waveform.dart';
import 'package:open_synth/theme/synth_theme.dart';
import 'package:open_synth/widgets/oscillator_panel.dart';

void main() {
  group('OscillatorPanel', () {
    testWidgets('renders title and basic controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SynthTheme.darkTheme,
          home: Scaffold(
            body: OscillatorPanel(
              title: 'OSC 1',
              oscillator: const Oscillator(),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('OSC 1'), findsOneWidget);
      expect(find.text('OCTAVE'), findsOneWidget);
      expect(find.text('DETUNE'), findsOneWidget);
      expect(find.text('PW'), findsOneWidget);
      expect(find.text('VOL'), findsOneWidget);
    });

    testWidgets('shows wavetable position knob when waveform is wavetable',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SynthTheme.darkTheme,
          home: Scaffold(
            body: OscillatorPanel(
              title: 'OSC 1',
              oscillator: const Oscillator(waveform: Waveform.wavetable),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('WT POS'), findsOneWidget);
    });

    testWidgets('hides wavetable position knob for non-wavetable waveforms',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SynthTheme.darkTheme,
          home: Scaffold(
            body: OscillatorPanel(
              title: 'OSC 1',
              oscillator: const Oscillator(waveform: Waveform.saw),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('WT POS'), findsNothing);
    });

    testWidgets('displays lock icon when isLocked is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SynthTheme.darkTheme,
          home: Scaffold(
            body: OscillatorPanel(
              title: 'OSC 1',
              oscillator: const Oscillator(),
              onChanged: (_) {},
              isLocked: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('calls onChanged when envelope toggle is tapped',
        (tester) async {
      Oscillator? updatedOsc;
      await tester.pumpWidget(
        MaterialApp(
          theme: SynthTheme.darkTheme,
          home: Scaffold(
            body: OscillatorPanel(
              title: 'OSC 1',
              oscillator: const Oscillator(enabled: true),
              onChanged: (osc) => updatedOsc = osc,
            ),
          ),
        ),
      );

      // Tap the circle indicator to toggle enabled
      final circles = tester.widgetList<Container>(
        find.byWidgetPredicate(
          (w) => w is Container && w.decoration is BoxDecoration,
        ),
      );
      // Find the circle indicator (first Container with BoxDecoration that's circular)
      for (final container in circles) {
        final decoration = container.decoration as BoxDecoration;
        if (decoration.shape == BoxShape.circle) {
          await tester.tap(find.byWidget(container));
          break;
        }
      }

      expect(updatedOsc, isNotNull);
      expect(updatedOsc!.enabled, isFalse);
    });
  });
}
