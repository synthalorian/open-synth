import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/preset_category.dart';
import '../models/synth_preset.dart';
import '../providers/synth_providers.dart';
import '../theme/synth_theme.dart';
import '../widgets/preset_card.dart';
import 'preset_editor_screen.dart';
import 'synth_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _categories = [null, ...PresetCategory.values]; // null = "All"

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
                tabs: _categories.map((c) {
                  return Tab(text: c?.displayName ?? 'All');
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) {
          var filtered = category == null
              ? presets
              : presets.where((p) => p.category == category).toList();

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
                  ref.read(currentPresetProvider.notifier).load(preset);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SynthScreen(),
                    ),
                  );
                },
                onLongPress: () => _showPresetOptions(context, ref, preset),
              );
            },
          );
        }).toList(),
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
