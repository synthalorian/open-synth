import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/preset_category.dart';
import '../models/synth_preset.dart';
import '../providers/ab_comparison_provider.dart';
import '../providers/favorites_provider.dart';
import '../providers/mod_matrix_provider.dart';
import '../providers/recent_presets_provider.dart';
import '../providers/synth_providers.dart';
import '../theme/synth_theme.dart';
import '../screens/preset_editor_screen.dart';

/// Shows the "Add to Setlist" bottom sheet for any preset.
void showAddToSetlistForPreset(BuildContext context, WidgetRef ref, SynthPreset preset) {
  final setlists = ref.read(setlistsProvider);

  if (setlists.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No setlists yet. Create one in Performance mode.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    backgroundColor: SynthTheme.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ADD "${preset.name.toUpperCase()}" TO SETLIST',
                style: TextStyle(
                  color: SynthTheme.cyan,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              ...setlists.entries.map((entry) {
                final sl = entry.value;
                final alreadyIn = sl.presetIds.contains(preset.id);
                return GestureDetector(
                  onTap: () {
                    if (alreadyIn) {
                      ref.read(setlistsProvider.notifier).removeFromSetlist(sl.name, preset.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Removed from "${sl.name}"'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else {
                      ref.read(setlistsProvider.notifier).addToSetlist(sl.name, preset.id);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Added to "${sl.name}"'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: alreadyIn
                          ? SynthTheme.cyan.withValues(alpha: 0.15)
                          : SynthTheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: alreadyIn
                            ? SynthTheme.cyan.withValues(alpha: 0.4)
                            : SynthTheme.purple.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          alreadyIn ? Icons.check_circle : Icons.queue_music,
                          color: alreadyIn ? SynthTheme.cyan : SynthTheme.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            sl.name,
                            style: TextStyle(
                              color: alreadyIn ? SynthTheme.cyan : Colors.white.withValues(alpha: 0.9),
                              fontSize: 13,
                              fontWeight: alreadyIn ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text(
                          '${sl.presetIds.length} presets',
                          style: TextStyle(
                            color: SynthTheme.textSecondary.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      );
    },
  );
}

/// Shows a context menu bottom sheet for a quick-strip preset tile.
void showQuickPresetContextMenu(BuildContext context, WidgetRef ref, SynthPreset preset) {
  final canDelete = !preset.id.startsWith('factory-');

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
                preset.name.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.copy, color: SynthTheme.cyan),
                title: const Text('Copy Name', style: TextStyle(color: Colors.white)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Clipboard.setData(ClipboardData(text: preset.name));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Preset name copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.vertical_align_top, color: SynthTheme.cyan),
                title: const Text('Move to Top', style: TextStyle(color: Colors.white)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  ref.read(recentPresetsProvider.notifier).track(preset.id);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Moved "${preset.name}" to top of recents'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.content_copy, color: SynthTheme.magenta),
                title: const Text('Copy Preset', style: TextStyle(color: Colors.white)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  final copy = SynthPreset(
                    name: '${preset.name} Copy',
                    category: PresetCategory.custom,
                    osc1: preset.osc1,
                    osc2: preset.osc2,
                    filter: preset.filter,
                    ampEnvelope: preset.ampEnvelope,
                    filterEnvelope: preset.filterEnvelope,
                    lfo1: preset.lfo1,
                    lfo2: preset.lfo2,
                    chorus: preset.chorus,
                    delay: preset.delay,
                    reverb: preset.reverb,
                    phaser: preset.phaser,
                    flanger: preset.flanger,
                    compressor: preset.compressor,
                    drive: preset.drive,
                    masterVolume: preset.masterVolume,
                    tags: [...preset.tags],
                    author: preset.author,
                    isBassPreset: preset.isBassPreset,
                  );
                  ref.read(presetListProvider.notifier).addPreset(copy);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied "${preset.name}" to presets'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.edit_note, color: SynthTheme.cyan),
                title: const Text('Rename', style: TextStyle(color: Colors.white)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  _showRenameDialog(context, ref, preset);
                },
              ),
              ListTile(
                leading: Icon(Icons.queue_music, color: SynthTheme.purple),
                title: const Text('Add to Setlist', style: TextStyle(color: Colors.white)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  showAddToSetlistForPreset(context, ref, preset);
                },
              ),
              ListTile(
                leading: Icon(Icons.compare_arrows, color: SynthTheme.cyan),
                title: const Text('Capture to A/B', style: TextStyle(color: Colors.white)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  final isBankA = ref.read(abComparisonProvider).isBankA;
                  final targetBank = isBankA ? 'B' : 'A';
                  final modSlots = ref.read(modMatrixProvider).slots;
                  ref.read(abComparisonProvider.notifier).captureToBank(preset, modSlots, !isBankA);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Captured "${preset.name}" to Bank $targetBank'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.share, color: SynthTheme.cyan),
                title: const Text('Share Preset', style: TextStyle(color: Colors.white)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Clipboard.setData(ClipboardData(text: jsonEncode(preset.toJson())));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Preset JSON copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              if (canDelete)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                  title: const Text('Delete Preset', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, ref, preset);
                  },
                ),
              ListTile(
                leading: Icon(Icons.edit, color: SynthTheme.cyan),
                title: const Text('Open in Editor', style: TextStyle(color: Colors.white)),
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                  ref.read(currentPresetProvider.notifier).load(preset);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PresetEditorScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

void _showRenameDialog(BuildContext context, WidgetRef ref, SynthPreset preset) {
  final controller = TextEditingController(text: preset.name);
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: SynthTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'RENAME PRESET',
        style: TextStyle(
          color: SynthTheme.cyan,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      content: TextField(
        controller: controller,
        autofocus: true,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Enter new name...',
          hintStyle: TextStyle(color: SynthTheme.textSecondary.withValues(alpha: 0.4)),
          filled: true,
          fillColor: SynthTheme.surface,
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
            borderSide: BorderSide(color: SynthTheme.cyan),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL', style: TextStyle(color: SynthTheme.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            final newName = controller.text.trim();
            if (newName.isNotEmpty && newName != preset.name) {
              final updated = preset.copyWith(name: newName);
              ref.read(presetListProvider.notifier).updatePreset(updated);
              // If this is the currently loaded preset, update it too.
              final current = ref.read(currentPresetProvider);
              if (current.id == preset.id) {
                ref.read(currentPresetProvider.notifier).load(updated);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Renamed to "$newName"'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
            Navigator.pop(context);
          },
          child: Text('RENAME', style: TextStyle(color: SynthTheme.cyan, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

void _showDeleteConfirmation(BuildContext context, WidgetRef ref, SynthPreset preset) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: SynthTheme.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'DELETE PRESET',
        style: TextStyle(
          color: Colors.redAccent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
      content: Text(
        'Are you sure you want to delete "${preset.name}"? This cannot be undone.',
        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL', style: TextStyle(color: SynthTheme.textSecondary)),
        ),
        TextButton(
          onPressed: () {
            ref.read(presetListProvider.notifier).deletePreset(preset.id);
            // Also remove from favorites and recents if present.
            if (ref.read(favoritesProvider).contains(preset.id)) {
              ref.read(favoritesProvider.notifier).toggle(preset.id);
            }
            ref.read(recentPresetsProvider.notifier).untrack(preset.id);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('"${preset.name}" deleted'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: Text('DELETE', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

/// Pastes a preset from clipboard JSON into the library.
/// Returns the pasted preset on success, null on failure.
Future<SynthPreset?> pastePresetFromClipboard(BuildContext context, WidgetRef ref) async {
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  final text = data?.text;
  if (text == null || text.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clipboard is empty'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return null;
  }

  try {
    final json = jsonDecode(text) as Map<String, dynamic>;
    final pasted = SynthPreset.fromJson(json);
    // Ensure it gets a new UUID so it doesn't collide.
    final fresh = SynthPreset(
      name: pasted.name,
      category: pasted.category,
      osc1: pasted.osc1,
      osc2: pasted.osc2,
      filter: pasted.filter,
      ampEnvelope: pasted.ampEnvelope,
      filterEnvelope: pasted.filterEnvelope,
      lfo1: pasted.lfo1,
      lfo2: pasted.lfo2,
      chorus: pasted.chorus,
      delay: pasted.delay,
      reverb: pasted.reverb,
      phaser: pasted.phaser,
      flanger: pasted.flanger,
      compressor: pasted.compressor,
      drive: pasted.drive,
      masterVolume: pasted.masterVolume,
      tags: [...pasted.tags],
      author: pasted.author,
      isBassPreset: pasted.isBassPreset,
    );
    ref.read(presetListProvider.notifier).addPreset(fresh);
    ref.read(recentPresetsProvider.notifier).track(fresh.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pasted "${fresh.name}" into library'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return fresh;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clipboard does not contain a valid preset JSON'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return null;
  }
}
