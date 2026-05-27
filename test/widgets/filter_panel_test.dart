import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_synth/models/filter_config.dart';
import 'package:open_synth/theme/synth_theme.dart';
import 'package:open_synth/widgets/filter_panel.dart';

void main() {
  group('FilterPanel', () {
    testWidgets('renders filter controls', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SynthTheme.darkTheme,
          home: Scaffold(
            body: FilterPanel(
              filter: const FilterConfig(),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('FILTER'), findsOneWidget);
      expect(find.text('RESO'), findsOneWidget);
      expect(find.text('CUTOFF'), findsOneWidget);
      expect(find.text('ENV'), findsOneWidget);
    });

    testWidgets('shows all filter type buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SynthTheme.darkTheme,
          home: Scaffold(
            body: FilterPanel(
              filter: const FilterConfig(),
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // LO, HI, BA, NO — first 2 chars of FilterType.displayName
      expect(find.text('LO'), findsOneWidget);
      expect(find.text('HI'), findsOneWidget);
      expect(find.text('BA'), findsOneWidget);
      expect(find.text('NO'), findsOneWidget);
    });

    testWidgets('shows lock icon when isLocked is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: SynthTheme.darkTheme,
          home: Scaffold(
            body: FilterPanel(
              filter: const FilterConfig(),
              onChanged: (_) {},
              isLocked: true,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.lock), findsOneWidget);
    });

    testWidgets('calls onChanged when a filter type is tapped',
        (tester) async {
      FilterConfig? updated;
      await tester.pumpWidget(
        MaterialApp(
          theme: SynthTheme.darkTheme,
          home: Scaffold(
            body: FilterPanel(
              filter: const FilterConfig(),
              onChanged: (f) => updated = f,
            ),
          ),
        ),
      );

      // Tap the "HI" (High Pass) filter type
      await tester.tap(find.text('HI'));
      expect(updated, isNotNull);
      expect(updated!.type.name, 'highpass');
    });
  });
}
