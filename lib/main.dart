import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/performance_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/synth_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('open_synth');
  runApp(const ProviderScope(child: OpenSynthApp()));
}

class OpenSynthApp extends ConsumerWidget {
  const OpenSynthApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Open Synth',
      debugShowCheckedModeBanner: false,
      theme: SynthTheme.lightTheme,
      darkTheme: SynthTheme.darkTheme,
      themeMode: themeMode,
      home: SplashScreen(nextScreen: const HomeScreen()),
      routes: {
        '/performance': (context) => const PerformanceScreen(),
      },
    );
  }
}
