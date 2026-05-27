import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/navigation_provider.dart';
import '../theme/synth_theme.dart';
import 'home_screen.dart';
import 'performance_screen.dart';
import 'recorder_screen.dart';
import 'split_screen.dart';
import 'synth_screen.dart';

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  static const _tabs = [
    _TabConfig(label: 'Presets', icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view),
    _TabConfig(label: 'Synth', icon: Icons.tune_outlined, activeIcon: Icons.tune),
    _TabConfig(label: 'Split', icon: Icons.call_split_outlined, activeIcon: Icons.call_split),
    _TabConfig(label: 'Recorder', icon: Icons.mic_none_outlined, activeIcon: Icons.mic),
    _TabConfig(label: 'Perf', icon: Icons.fullscreen_outlined, activeIcon: Icons.fullscreen),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainShellIndexProvider);

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: const [
          HomeScreen(),
          SynthScreen(),
          SplitScreen(),
          RecorderScreen(),
          PerformanceScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: SynthTheme.surface,
          border: Border(
            top: BorderSide(color: SynthTheme.purple.withValues(alpha: 0.2)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: (index) => ref.read(mainShellIndexProvider.notifier).state = index,
            backgroundColor: Colors.transparent,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedItemColor: SynthTheme.magenta,
            unselectedItemColor: SynthTheme.textSecondary.withValues(alpha: 0.5),
            selectedFontSize: 10,
            unselectedFontSize: 9,
            iconSize: 22,
            items: _tabs.map((t) {
              final isActive = _tabs.indexOf(t) == currentIndex;
              return BottomNavigationBarItem(
                icon: Icon(isActive ? t.activeIcon : t.icon),
                label: t.label,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _TabConfig {
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _TabConfig({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
