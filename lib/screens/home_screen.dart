import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/preset_category.dart';
import '../models/synth_preset.dart';
import '../providers/favorites_provider.dart';
import '../providers/recent_presets_provider.dart';
import '../providers/synth_providers.dart';
import '../providers/undo_redo_provider.dart';
import '../theme/synth_theme.dart';
import '../widgets/preset_card.dart';
import 'preset_editor_screen.dart';
import 'settings_screen.dart';
import '../providers/navigation_provider.dart';

/// Horizontal strip of favorite presets shown at the top of the Home screen.
class _FavoritePresetStrip extends ConsumerWidget {
  const _FavoritePresetStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(presetListProvider);
    final current = ref.watch(currentPresetProvider);
    final favoritesNotifier = ref.watch(favoritesProvider.notifier);
    final orderedFavorites = favoritesNotifier.orderedFavorites;
    final presetMap = {for (final p in presets) p.id: p};
    final favs = orderedFavorites
        .map((id) => presetMap[id])
        .whereType<SynthPreset>()
        .toList();

    if (favs.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              'FAVORITES',
              style: TextStyle(
                color: SynthTheme.orange,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: favs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final p = favs[index];
                final isActive = p.id == current.id;
                return GestureDetector(
                  onTap: () {
                    ref.read(undoRedoProvider.notifier).save();
                    ref.read(currentPresetProvider.notifier).load(p);
                    ref.read(recentPresetsProvider.notifier).track(p.id);
                    ref.read(mainShellIndexProvider.notifier).state = 1;
                  },
                  onLongPress: () {
                    ref.read(favoritesProvider.notifier).toggle(p.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Removed "${p.name}" from favorites'),
                        duration: const Duration(seconds: 1),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 120,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? SynthTheme.magenta.withValues(alpha: 0.2)
                          : SynthTheme.orange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? SynthTheme.magenta.withValues(alpha: 0.6)
                            : SynthTheme.orange.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: SynthTheme.orange,
                              size: 10,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                p.name,
                                style: TextStyle(
                                  color: isActive ? SynthTheme.magenta : Colors.white.withValues(alpha: 0.9),
                                  fontSize: 10,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.category.displayName.toUpperCase(),
                          style: TextStyle(
                            color: SynthTheme.textSecondary.withValues(alpha: 0.6),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal strip of recently-used presets shown at the top of the Home screen.
class _RecentPresetStrip extends ConsumerWidget {
  const _RecentPresetStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(presetListProvider);
    final current = ref.watch(currentPresetProvider);
    final recentIds = ref.watch(recentPresetsProvider);
    final presetMap = {for (final p in presets) p.id: p};
    final recents = recentIds.reversed
        .map((id) => presetMap[id])
        .whereType<SynthPreset>()
        .take(12)
        .toList();

    if (recents.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              'RECENT',
              style: TextStyle(
                color: SynthTheme.cyan,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: recents.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final p = recents[index];
                final isActive = p.id == current.id;
                return GestureDetector(
                  onTap: () {
                    ref.read(undoRedoProvider.notifier).save();
                    ref.read(currentPresetProvider.notifier).load(p);
                    ref.read(recentPresetsProvider.notifier).track(p.id);
                    ref.read(mainShellIndexProvider.notifier).state = 1;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 110,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive
                          ? SynthTheme.magenta.withValues(alpha: 0.2)
                          : SynthTheme.card,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive
                            ? SynthTheme.magenta.withValues(alpha: 0.6)
                            : SynthTheme.purple.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          p.name,
                          style: TextStyle(
                            color: isActive ? SynthTheme.magenta : Colors.white.withValues(alpha: 0.9),
                            fontSize: 10,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.category.displayName.toUpperCase(),
                          style: TextStyle(
                            color: SynthTheme.textSecondary.withValues(alpha: 0.6),
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _categories = [null, ...PresetCategory.values, 'favorites']; // null = "All", 'favorites' = special

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final presets = ref.watch(presetListProvider);
    final currentPreset = ref.watch(currentPresetProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'OPEN SYNTH',
          style: GoogleFonts.orbitron(
            color: SynthTheme.magenta,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: SynthTheme.cyan),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.add, color: SynthTheme.cyan),
            tooltip: 'New Preset',
            onPressed: () => _createPreset(context, ref),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(84),
          child: Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  onChanged: (v) =>
                      ref.read(searchQueryProvider.notifier).state = v,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search presets...',
                    hintStyle: TextStyle(color: SynthTheme.textSecondary),
                    prefixIcon: Icon(Icons.search, color: SynthTheme.textSecondary, size: 20),
                    filled: true,
                    fillColor: SynthTheme.card,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: SynthTheme.purple.withValues(alpha: 0.3)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: SynthTheme.purple.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: SynthTheme.magenta),
                    ),
                  ),
                ),
              ),
              // Category tabs
              TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: SynthTheme.magenta,
                unselectedLabelColor: SynthTheme.textSecondary,
                indicatorColor: SynthTheme.magenta,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                tabs: _categories.map<Tab>((c) {
                  if (c == 'favorites') return const Tab(text: '★ Favs');
                  if (c is PresetCategory) return Tab(text: c.displayName);
                  return const Tab(text: 'All');
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Favorites Strip ──
          _FavoritePresetStrip(),
          // ── Recent Presets Strip ──
          _RecentPresetStrip(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _categories.map((category) {
                late List<SynthPreset> filtered;
                if (category == 'favorites') {
                  final favs = ref.watch(favoritesProvider);
                  filtered = presets.where((p) => favs.contains(p.id)).toList();
                } else {
                  filtered = category == null
                      ? presets
                      : presets.where((p) => p.category == category).toList();
                }

                if (searchQuery.isNotEmpty) {
                  final q = searchQuery.toLowerCase();
                  filtered = filtered.where((p) {
                    return p.name.toLowerCase().contains(q) ||
                        p.tags.any((t) => t.toLowerCase().contains(q)) ||
                        p.category.displayName.toLowerCase().contains(q);
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.music_off, size: 48, color: SynthTheme.purple.withValues(alpha: 0.3)),
                        const SizedBox(height: 12),
                        Text(
                          'No presets found',
                          style: TextStyle(color: SynthTheme.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final preset = filtered[index];
                    return PresetCard(
                      preset: preset,
                      isSelected: preset.id == currentPreset.id,
                      onTap: () {
                        ref.read(undoRedoProvider.notifier).save();
                        ref.read(currentPresetProvider.notifier).load(preset);
                        ref.read(recentPresetsProvider.notifier).track(preset.id);
                        ref.read(mainShellIndexProvider.notifier).state = 1; // switch to Synth tab
                      },
                      onLongPress: () => _showPresetOptions(context, ref, preset),
                    );
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _createPreset(BuildContext context, WidgetRef ref) {
    final newPreset = SynthPreset(
      name: 'New Preset',
      category: PresetCategory.custom,
      author: 'synth',
    );
    ref.read(presetListProvider.notifier).addPreset(newPreset);
    ref.read(currentPresetProvider.notifier).load(newPreset);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PresetEditorScreen()),
    );
  }

  void _showPresetOptions(BuildContext context, WidgetRef ref, SynthPreset preset) {
    showModalBottomSheet(
      context: context,
      backgroundColor: SynthTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  preset.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(Icons.edit, color: SynthTheme.cyan),
                  title: const Text('Edit', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    ref.read(currentPresetProvider.notifier).load(preset);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PresetEditorScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.copy, color: SynthTheme.purple),
                  title: const Text('Duplicate', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pop(context);
                    final dupe = preset.copyWith(
                      id: null, // generates new UUID
                      name: '${preset.name} (Copy)',
                    );
                    ref.read(presetListProvider.notifier).addPreset(dupe);
                  },
                ),
                if (!preset.id.startsWith('factory-'))
                  ListTile(
                    leading: Icon(Icons.delete_outline, color: SynthTheme.magenta),
                    title: Text('Delete', style: TextStyle(color: SynthTheme.magenta)),
                    onTap: () {
                      Navigator.pop(context);
                      ref.read(presetListProvider.notifier).deletePreset(preset.id);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
