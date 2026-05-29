// Smoke test — verifies the app builds and renders without crashing.
//
// The main app widget is OpenSynthApp (defined in lib/main.dart). This test
// ensures the widget tree can be pumped without throwing.

import 'dart:io' as io;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

import 'package:open_synth/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = await io.Directory.systemTemp.createTemp('hive_test_');
    Hive.init(dir.path);
    await Hive.openBox('open_synth');
  });

  testWidgets('Open Synth loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: OpenSynthApp()));
    // If we got here, the widget tree doesn't throw during build.
    expect(find.byType(OpenSynthApp), findsOneWidget);
  });
}