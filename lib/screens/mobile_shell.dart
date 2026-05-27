import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../ffi/audio_platform.dart';
import '../providers/navigation_provider.dart';
import '../providers/synth_providers.dart';
import '../theme/synth_theme.dart';
import 'home_screen.dart';
import 'performance_screen.dart';
import 'recorder_screen.dart';
import 'settings_screen.dart';
import 'split_screen.dart';
import 'synth_screen.dart';

/// Mobile shell — replaces [MainShell] on mobile platforms.
///
/// Uses a hamburger drawer for navigation instead of a bottom nav bar.
/// The drawer is dark-themed with synthwave accents.
class MobileShell extends ConsumerWidget {
  const MobileShell({super.key});

  static const _drawerItems = [
    _DrawerItem(label: 'Presets', icon: Icons.grid_view),
    _DrawerItem(label: 'Synth', icon: Icons.tune),
    _DrawerItem(label: 'Split', icon: Icons.call_split),
    _DrawerItem(label: 'Recorder', icon: Icons.mic_none),
    _DrawerItem(label: 'Performance', icon: Icons.fullscreen),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(mainShellIndexProvider);
    final preset = ref.watch(currentPresetProvider);

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          preset.name.toUpperCase(),
          style: GoogleFonts.orbitron(
            color: SynthTheme.magenta,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.shuffle, color: SynthTheme.purple, size: 20),
            tooltip: 'Randomize',
            onPressed: () {
              // Defer to the synth screen's randomize — just switch to synth tab
              ref.read(mainShellIndexProvider.notifier).state = 1;
            },
          ),
          IconButton(
            icon: Icon(Icons.settings, color: SynthTheme.textSecondary, size: 20),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, ref, currentIndex),
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
    );
  }

  Widget _buildDrawer(BuildContext context, WidgetRef ref, int currentIndex) {
    return Drawer(
      backgroundColor: SynthTheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // ── Drawer Header ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              decoration: BoxDecoration(
                color: SynthTheme.card,
                border: Border(
                  bottom: BorderSide(
                    color: SynthTheme.purple.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'OPEN SYNTH',
                    style: GoogleFonts.orbitron(
                      color: SynthTheme.magenta,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Synthwave gradient bar
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      gradient: LinearGradient(
                        colors: [
                          SynthTheme.magenta,
                          SynthTheme.purple,
                          SynthTheme.cyan,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Mobile Edition',
                    style: TextStyle(
                      color: SynthTheme.textSecondary.withValues(alpha: 0.6),
                      fontSize: 10,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // ── Navigation Items ──
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _drawerItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isActive = index == currentIndex;
                  return _DrawerNavItem(
                    item: item,
                    isActive: isActive,
                    onTap: () {
                      ref.read(mainShellIndexProvider.notifier).state = index;
                      Navigator.of(context).pop(); // close drawer
                    },
                  );
                }).toList(),
              ),
            ),

            // ── Drawer Footer ──
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: SynthTheme.purple.withValues(alpha: 0.15),
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: SynthTheme.cyan,
                      boxShadow: [
                        BoxShadow(
                          color: SynthTheme.cyan.withValues(alpha: 0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'v1.0 • ${audioBackendName}',
                    style: TextStyle(
                      color: SynthTheme.textSecondary.withValues(alpha: 0.4),
                      fontSize: 9,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single navigation item in the drawer.
class _DrawerNavItem extends StatelessWidget {
  final _DrawerItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerNavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isActive
          ? SynthTheme.magenta.withValues(alpha: 0.15)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: SynthTheme.magenta.withValues(alpha: 0.1),
        highlightColor: SynthTheme.magenta.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isActive ? SynthTheme.magenta : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: isActive ? SynthTheme.magenta : SynthTheme.textSecondary.withValues(alpha: 0.6),
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                item.label,
                style: TextStyle(
                  color: isActive ? SynthTheme.magenta : SynthTheme.textSecondary,
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerItem {
  final String label;
  final IconData icon;
  const _DrawerItem({required this.label, required this.icon});
}
