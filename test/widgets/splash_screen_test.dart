import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_synth/screens/splash_screen.dart';
import 'package:open_synth/theme/synth_theme.dart';

void main() {
  group('SplashScreen', () {
    testWidgets('renders logo and title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SynthTheme.darkTheme,
          home: const SplashScreen(nextScreen: Scaffold(body: Text('Home'))),
        ),
      );

      // Title should appear
      expect(find.text('OPEN SYNTH'), findsOneWidget);
      // Music note icon should be present
      expect(find.byIcon(Icons.music_note), findsOneWidget);
    });

    testWidgets('renders status text and loading bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SynthTheme.darkTheme,
          home: const SplashScreen(nextScreen: Scaffold(body: Text('Home'))),
        ),
      );

      // Initial status text
      expect(find.text('INITIALIZING DSP ENGINE...'), findsOneWidget);

      // Loading indicator should be present
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('displays tagline and version info', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SynthTheme.darkTheme,
          home: const SplashScreen(nextScreen: Scaffold(body: Text('Home'))),
        ),
      );

      expect(find.text('SOFTWARE SYNTHESIZER'), findsOneWidget);
      // Corner decorations
      expect(find.text('// SYSTEM'), findsOneWidget);
    });

    testWidgets('navigates to next screen after animation completes',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SynthTheme.darkTheme,
          home: const SplashScreen(nextScreen: Scaffold(body: Text('Home Screen'))),
        ),
      );

      // Fast-forward through the animation
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should have navigated to the next screen
      expect(find.text('Home Screen'), findsOneWidget);
      expect(find.text('OPEN SYNTH'), findsNothing);
    });
  });
}
