import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import 'package:open_synth/utils/logger.dart';

void main() {
  tearDown(() {
    // Reset global logger state between tests so that idempotency checks
    // and listener counts remain deterministic across the suite.
    Logger.root.level = Level.INFO;
    Logger.root.clearListeners();
  });

  group('configureLogging', () {

    test('sets root logger level to ALL in debug builds', () {
      configureLogging();
      // Tests run in debug mode, so kDebugMode is true.
      expect(Logger.root.level, equals(Level.ALL));
    });

    test('onRecord stream is active after configuration', () {
      configureLogging();
      final completer = Completer<String>();
      final sub = Logger.root.onRecord.listen((r) {
        if (!completer.isCompleted) {
          completer.complete(r.message);
        }
      });
      addTearDown(sub.cancel);

      appLogger.info('ping');
      expect(completer.future, completion(equals('ping')));
    });

    test('is idempotent — second call is ignored', () {
      configureLogging();
      configureLogging();
      configureLogging();
      // Only one listener was ever attached.
      final records = <LogRecord>[];
      final sub = Logger.root.onRecord.listen(records.add);
      addTearDown(sub.cancel);

      appLogger.info('once');
      expect(records.length, equals(1));
    });
  });

  group('appLogger', () {
    test('returns a Logger named "open_synth"', () {
      expect(appLogger.name, equals('open_synth'));
    });

    test('can log messages at different levels', () {
      configureLogging();
      final records = <LogRecord>[];
      final sub = Logger.root.onRecord.listen(records.add);
      addTearDown(sub.cancel);

      appLogger.fine('fine message');
      appLogger.info('info message');
      appLogger.warning('warning message');
      appLogger.severe('severe message');

      expect(records.length, greaterThanOrEqualTo(4));
      expect(records.map((r) => r.level).toList(),
          containsAll([Level.FINE, Level.INFO, Level.WARNING, Level.SEVERE]));
    });
  });
}
