import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/preset_category.dart';
import '../models/synth_preset.dart';
import '../providers/favorites_provider.dart';
import '../providers/synth_providers.dart';
import '../providers/undo_redo_provider.dart';
import '../theme/synth_theme.dart';

/// Current search query for the preset browser.
final presetBrowserSearchProvider = StateProvider<String>((ref) => '');

/// Currently selected category filter for the preset browser.
final presetBrowserCategoryProvider = StateProvider<PresetCategory?>((ref) => null);

/// Whether to show only favorites in the preset browser.
final presetBrowserFavoritesOnlyProvider = StateProvider<bool>((ref) => false);

class PresetBrowser extends ConsumerWidget {
  final ScrollController? scrollController;

  const PresetBrowser({super.key, this.scrollController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final search = ref.watch(presetBrowserSearchProvider).toLowerCase();
    final selectedCategory = ref.watch(presetBrowserCategoryProvider);
    final favoritesOnly = ref.watch(presetBrowserFavoritesOnlyProvider);
    final favorites = ref.watch(favoritesProvider);
    final allPresets = ref.watch(presetListProvider);

    final filtered = allPresets.where((preset) {
      // Category filter
      if (selectedCategory != null && preset.category != selectedCategory) {
        return false;
      }
      // Favorites filter
      if (favoritesOnly && !favorites.contains(preset.id)) {
        return false;
      }
      // Search filter (name or tags)
      if (search.isNotEmpty) {
        final nameMatch = preset.name.toLowerCase().contains(search);
        final tagMatch = preset.tags.any((t) => t.toLowerCase().contains(search));
        final authorMatch = preset.author.toLowerCase().contains(search);
        if (!nameMatch && !tagMatch && !authorMatch) return false;
      }
      return true;
    }).toList();

    return Container(
      decoration: BoxDecoration(
        color: SynthTheme.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(color: SynthTheme.magenta.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 8, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: SynthTheme.purple.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Text(
            'PATCH BROWSER',
            style: GoogleFonts.orbitron(
              color: SynthTheme.magenta,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) {
                ref.read(presetBrowserSearchProvider.notifier).state = value;
              },
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search presets, tags...',
                hintStyle: TextStyle(
                  color: SynthTheme.textSecondary.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
                prefixIcon: Icon(Icons.search, color: SynthTheme.textSecondary, size: 18),
                suffixIcon: search.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          ref.read(presetBrowserSearchProvider.notifier).state = '';
                        },
                        child: Icon(Icons.clear, color: SynthTheme.textSecondary, size: 18),
                      )
                    : null,
                filled: true,
                fillColor: SynthTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: SynthTheme.purple.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: SynthTheme.purple.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: SynthTheme.magenta.withValues(alpha: 0.5)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Category chips + favorites toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'ALL',
                    selected: selectedCategory == null,
                    onTap: () => ref.read(presetBrowserCategoryProvider.notifier).state = null,
                    activeColor: SynthTheme.cyan,
                  ),
                  ...PresetCategory.values.map((cat) {
                    return _FilterChip(
                      label: cat.displayName.toUpperCase(),
                      selected: selectedCategory == cat,
                      onTap: () => ref.read(presetBrowserCategoryProvider.notifier).state = cat,
                      activeColor: _categoryColor(cat),
                    );
                  }),
                  _FilterChip(
                    label: '★ FAV',
                    selected: favoritesOnly,
                    onTap: () => ref.read(presetBrowserFavoritesOnlyProvider.notifier).state = !favoritesOnly,
                    activeColor: SynthTheme.orange,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),            // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$filtered patches found',
                style: TextStyle(
                  color: SynthTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Preset grid
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, color: SynthTheme.textSecondary, size: 40),
                        const SizedBox(height: 12),
                        Text(
                          'No patches match your filters',
                          style: TextStyle(color: SynthTheme.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2.4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final preset = filtered[index];
                      return _PresetCard(
                        preset: preset,
                        isFavorite: favorites.contains(preset.id),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

}

Color _categoryColor(PresetCategory cat) {
  return switch (cat) {
    PresetCategory.pads => const Color(0xFF9B30FF),
    PresetCategory.leads => const Color(0xFFFF2975),
    PresetCategory.bass => const Color(0xFFFF6B35),
    PresetCategory.keys => const Color(0xFF00E5FF),
    PresetCategory.arps => const Color(0xFF39FF14),
    PresetCategory.fx => const Color(0xFFFFD700),
    PresetCategory.synthwave => const Color(0xFFFF00FF),
    PresetCategory.custom => const Color(0xFF808080),
  };
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color activeColor;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? activeColor.withValues(alpha: 0.2) : SynthTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? activeColor.withValues(alpha: 0.6) : SynthTheme.purple.withValues(alpha: 0.15),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? activeColor : SynthTheme.textSecondary,
              fontSize: 10,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetCard extends ConsumerWidget {
  final SynthPreset preset;
  final bool isFavorite;

  const _PresetCard({required this.preset, required this.isFavorite});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor = _categoryColor(preset.category);

    return GestureDetector(
      onTap: () {
        ref.read(undoRedoProvider.notifier).save();
        ref.read(currentPresetProvider.notifier).load(preset);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loaded "${preset.name}"'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: SynthTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: categoryColor.withValues(alpha: 0.25),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              SynthTheme.card,
              SynthTheme.card.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    preset.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    ref.read(favoritesProvider.notifier).toggle(preset.id);
                  },
                  child: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? SynthTheme.orange : SynthTheme.textSecondary.withValues(alpha: 0.4),
                    size: 16,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Wrap(
              spacing: 4,
              runSpacing: 2,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    preset.category.displayName.toUpperCase(),
                    style: TextStyle(
                      color: categoryColor,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ...preset.tags.take(2).map((tag) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: SynthTheme.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      tag.toUpperCase(),
                      style: TextStyle(
                        color: SynthTheme.textSecondary.withValues(alpha: 0.8),
                        fontSize: 8,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
