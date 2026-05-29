import 'package:flutter_test/flutter_test.dart';

import 'package:open_synth/utils/error_handler.dart';

void main() {
  group('guard', () {
    test('returns value on success', () async {
      final result = await guard<String>(() async => 'success');
      expect(result, equals('success'));
    });

    test('returns null on exception', () async {
      final result = await guard<int>(() async {
        throw Exception('boom');
      });
      expect(result, isNull);
    });

    test('invokes onError callback on exception', () async {
      Object? capturedError;
      StackTrace? capturedStack;

      await guard<String>(
        () async => throw Exception('boom'),
        onError: (error, stack) {
          capturedError = error;
          capturedStack = stack;
        },
      );

      expect(capturedError, isA<Exception>());
      expect(capturedStack, isNotNull);
    });

    test('returns null when operation returns null', () async {
      final result = await guard<String?>(() async => null);
      expect(result, isNull);
    });

    test('passes context through to log message', () async {
      // guard logs at WARNING level when an error occurs.
      // We can't easily spy on the logger, but we can verify the
      // function completes without throwing.
      final result = await guard<int>(
        () async => throw FormatException('bad'),
        context: 'parseConfig',
      );
      expect(result, isNull);
    });

    test('catches synchronous exceptions and returns null', () async {
      final result = await guard<int>(() async {
        // Even "synchronous" throws inside an async function are caught
        // by guard because the function is awaited inside a try/catch.
        throw StateError('sync');
      });
      expect(result, isNull);
    });
  });

  group('installGlobalErrorHandlers', () {
    test('is a callable function', () {
      // The function modifies global singletons (FlutterError.onError,
      // PlatformDispatcher.instance.onError) which are shared across the
      // entire test process. We only verify the symbol exists and is
      // callable; actual behaviour is covered by widget tests that pump
      // the full app (e.g. widget_test.dart).
      expect(installGlobalErrorHandlers, isA<Function>());
    });
  });
}
