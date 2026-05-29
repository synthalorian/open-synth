import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../services/crashlytics_service.dart';

final _log = Logger('ErrorHandler');

/// Installs global error handlers so that *every* uncaught error is logged
/// and (in release mode) forwarded to [CrashlyticsService].
///
/// Call once, before [runApp].
///
/// `FlutterError.onError` catches widget build errors and
/// `PlatformDispatcher.instance.onError` catches async errors.
void installGlobalErrorHandlers() {
  // Capture errors thrown inside Flutter widgets.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _log.severe(
      'Flutter error in ${details.library}',
      details.exception,
      details.stack,
    );
    recordFlutterError(details);
  };

  // Capture errors thrown in asynchronous zones (Futures, async/await).
  PlatformDispatcher.instance.onError = (error, stack) {
    _log.severe('Uncaught async error', error, stack);
    crashlytics.recordError(error, stack);
    return true;
  };
}

/// Wraps an async function call with a catch-all that logs and reports
/// failures without crashing the UI.
///
/// Usage:
/// ```dart
/// final result = await guard(() => loadPreset(id));
/// ```
Future<T?> guard<T>(
  Future<T?> Function() operation, {
  String? context,
  void Function(Object error, StackTrace stack)? onError,
}) async {
  try {
    return await operation();
  } catch (e, st) {
    final msg = context != null ? '$context: $e' : e.toString();
    _log.warning(msg, e, st);
    if (!kDebugMode) {
      crashlytics.recordError(e, st, reason: context);
    }
    onError?.call(e, st);
    return null;
  }
}
