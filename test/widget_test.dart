// Smoke test — verifies the app builds and renders without crashing.
//
// The main app widget is OpenSynthApp (defined in lib/main.dart). This test
// ensures the widget tree can be pumped without throwing.

import 'package:flutter_test/flutter_test.dart';

import 'package:open_synth/main.dart';

void main() {
  testWidgets('Open Synth loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const OpenSynthApp());
    // If we got here, the widget tree doesn't throw during build.
    expect(find.byType(OpenSynthApp), findsOneWidget);
  });
}