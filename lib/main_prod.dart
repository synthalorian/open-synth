import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'main.dart';
import 'utils/error_handler.dart';
import 'utils/logger.dart';

/// Production entry point.
///
/// Compared to [main] this variant:
///   • Installs global error handlers (widget + async + zone).
///   • Configures structured logging with release-appropriate levels.
///   • Suppresses the debug banner (handled by OpenSynthApp already).
///   • Keeps Hive and Riverpod initialization identical.
///
/// Build with:
///   flutter run -t lib/main_prod.dart --release
///   flutter build linux -t lib/main_prod.dart
///   flutter build apk -t lib/main_prod.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  configureLogging();
  installGlobalErrorHandlers();

  final log = appLogger;
  log.info('Open Synth starting in production mode');

  try {
    await Hive.initFlutter();
    await Hive.openBox('open_synth');
  } catch (e, st) {
    log.severe('Failed to initialize Hive', e, st);
    // Do not block app launch for local-storage failures.
  }

  runApp(const ProviderScope(child: OpenSynthApp()));
}
