import 'package:flutter/foundation.dart';

/// Abstract interface for crash / error reporting.
///
/// The default concrete implementation is [NoOpCrashlyticsService] which does
/// nothing. In a future release this can be swapped for a Firebase Crashlytics
/// adapter without touching consumer code.
abstract class CrashlyticsService {
  /// Records a non-fatal exception together with contextual information.
  void recordError(Object exception, StackTrace stack, {String? reason});

  /// Logs a breadcrumb / contextual message.
  void log(String message);

  /// Sets a user identifier for the session.
  void setUserId(String userId);

  /// Adds a custom key-value pair to the current crash report context.
  void setCustomKey(String key, Object value);
}

/// No-op implementation suitable for local builds and test environments.
class NoOpCrashlyticsService implements CrashlyticsService {
  @override
  void recordError(Object exception, StackTrace stack, {String? reason}) {
    // no-op
  }

  @override
  void log(String message) {
    // no-op
  }

  @override
  void setUserId(String userId) {
    // no-op
  }

  @override
  void setCustomKey(String key, Object value) {
    // no-op
  }
}

/// Crashlytics singleton used by the app.
///
/// Assign a real implementation before [runApp] if crash reporting is desired.
CrashlyticsService crashlytics = NoOpCrashlyticsService();

/// Convenience helper that records a Flutter error to the active crash
/// reporter only when *not* in debug mode.
void recordFlutterError(FlutterErrorDetails details) {
  if (kDebugMode) return;
  crashlytics.recordError(
    details.exception,
    details.stack ?? StackTrace.current,
    reason: details.library,
  );
}
