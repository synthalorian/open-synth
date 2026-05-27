import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/preset_category.dart';
import '../providers/synth_providers.dart';
import '../providers/undo_redo_provider.dart';
import '../theme/synth_theme.dart';

class PresetEditorScreen extends ConsumerStatefulWidget {
  const PresetEditorScreen({super.key});

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _tagsController;
  late TextEditingController _authorController;

  @override
  void initState() {
    super.initState();
    final preset = ref.read(currentPresetProvider);
    _nameController = TextEditingController(text: preset.name);
    _tagsController = TextEditingController(text: preset.tags.join(', '));
    _authorController = TextEditingController(text: preset.author);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagsController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final preset = ref.watch(currentPresetProvider);
    final notifier = ref.read(currentPresetProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'EDIT PRESET',
          style: GoogleFonts.orbitron(
            color: SynthTheme.cyan,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(undoRedoProvider.notifier).save();
              // Save changes
              final tags = _tagsController.text
                  .split(',')
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList();
              notifier.update((p) => p.copyWith(
                    name: _nameController.text,
                    tags: tags,
                    author: _authorController.text,
                  ));
              ref.read(presetListProvider.notifier).updatePreset(
                    ref.read(currentPresetProvider),
                  );
              Navigator.pop(context);
            },
            child: Text(
              'SAVE',
              style: TextStyle(
                color: SynthTheme.magenta,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            _SectionLabel('Preset Name'),
            const SizedBox(height: 8),
            _StyledTextField(
              controller: _nameController,
              hintText: 'Enter preset name',
            ),
            const SizedBox(height: 24),

            // Category selector
            _SectionLabel('Category'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PresetCategory.values.map((cat) {
                final isSelected = cat == preset.category;
                return GestureDetector(
                  onTap: () => notifier.update((p) => p.copyWith(category: cat)),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? SynthTheme.magenta.withValues(alpha: 0.2)
                          : SynthTheme.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? SynthTheme.magenta
                            : SynthTheme.purple.withValues(alpha: 0.3),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Text(
                      cat.displayName,
                      style: TextStyle(
                        color: isSelected ? SynthTheme.magenta : SynthTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Bass preset toggle
            Row(
              children: [
                _SectionLabel('Bass Preset'),
                const Spacer(),
                Switch(
                  value: preset.isBassPreset,
                  activeTrackColor: SynthTheme.orange,
                  thumbColor: WidgetStatePropertyAll(SynthTheme.orange),
                  onChanged: (v) =>
                      notifier.update((p) => p.copyWith(isBassPreset: v)),
                ),
              ],
            ),
            Text(
              'Optimized for bass guitar input trigger',
              style: TextStyle(
                color: SynthTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),

            // Tags
            _SectionLabel('Tags'),
            const SizedBox(height: 8),
            _StyledTextField(
              controller: _tagsController,
              hintText: 'warm, analog, retro (comma-separated)',
            ),
            const SizedBox(height: 24),

            // Author
            _SectionLabel('Author'),
            const SizedBox(height: 8),
            _StyledTextField(
              controller: _authorController,
              hintText: 'Your name',
            ),
            const SizedBox(height: 24),

            // Preset ID (readonly info)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SynthTheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: SynthTheme.purple.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.fingerprint, color: SynthTheme.purple, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      preset.id,
                      style: TextStyle(
                        color: SynthTheme.textSecondary,
                        fontSize: 10,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
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

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        color: SynthTheme.cyan,
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const _StyledTextField({
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: SynthTheme.textSecondary),
        filled: true,
        fillColor: SynthTheme.card,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
