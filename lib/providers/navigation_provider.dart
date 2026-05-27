import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the active tab index for the bottom navigation shell.
final mainShellIndexProvider = StateProvider<int>((ref) => 0);
