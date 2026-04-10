import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/home_screen.dart';
import 'theme/synth_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('open_synth');
  runApp(const ProviderScope(child: OpenSynthApp()));
}

class OpenSynthApp extends StatelessWidget {
  const OpenSynthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Open Synth',
      debugShowCheckedModeBanner: false,
      theme: SynthTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
