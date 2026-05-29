import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Global logger instance for the app.
///
/// Usage:
/// ```dart
/// import 'package:open_synth/utils/logger.dart';
///
/// final _log = Logger('MyClass');
/// _log.info('Something happened');
/// ```
final _rootLogger = Logger('open_synth');

bool _loggingConfigured = false;

/// Configures the logging infrastructure.
///
/// In debug mode all messages are printed to the console via [debugPrint].
/// In release mode only warnings and errors are forwarded, and they are
/// sent through [developer.log] so they show up in the Dart DevTools timeline.
///
/// Call once before [runApp], typically in [main] or [main_prod].
/// Safe to call multiple times — subsequent calls are ignored.
void configureLogging() {
  // Always (re-)apply the level so that tests that reset state between runs
  // do not accidentally leave the root at a different level.
  Logger.root.level = kDebugMode ? Level.ALL : Level.WARNING;

  if (_loggingConfigured) return;
  _loggingConfigured = true;

  Logger.root.onRecord.listen((record) {
    final message = _format(record);
    if (kDebugMode) {
      // ignore: avoid_print
      print(message);
    } else {
      developer.log(
        record.message,
        time: record.time,
        sequenceNumber: record.sequenceNumber,
        level: record.level.value,
        name: record.loggerName,
        error: record.error,
        stackTrace: record.stackTrace,
      );
    }
  });
}

String _format(LogRecord record) {
  final buffer = StringBuffer();
  buffer.write('[${record.time.toIso8601String()}] ');
  buffer.write('${record.level.name.padRight(7)} ');
  buffer.write('${record.loggerName.isEmpty ? 'ROOT' : record.loggerName} — ');
  buffer.write(record.message);
  if (record.error != null) {
    buffer.write(' | error: ${record.error}');
  }
  if (record.stackTrace != null) {
    buffer.write('\n${record.stackTrace}');
  }
  return buffer.toString();
}

/// Convenience top-level logger for bootstrapping code.
Logger get appLogger => _rootLogger;
