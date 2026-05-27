import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/synth_preset.dart';
import '../providers/favorites_provider.dart';
import '../providers/recent_presets_provider.dart';
import '../providers/synth_providers.dart';
import '../theme/synth_theme.dart';
import '../widgets/computer_keyboard_listener.dart';
import '../widgets/crt_overlay.dart';
import '../widgets/keyboard_widget.dart';
import '../widgets/performance_meters.dart';
import '../widgets/retro_grid_background.dart';
import '../providers/navigation_provider.dart';

/// Full-screen performance mode optimized for live playing.
/// Minimal chrome, big controls, X/Y expression pad.
class PerformanceScreen extends ConsumerStatefulWidget {
  const PerformanceScreen({super.key});

  @override
  ConsumerState<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends ConsumerState<PerformanceScreen> {
  bool _showControls = true;

  void _toggleControls() => setState(() => _showControls = !_showControls);

  @override
  Widget build(BuildContext context) {
    final preset = ref.watch(currentPresetProvider);
    final notifier = ref.read(currentPresetProvider.notifier);

    return CrtOverlay(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RetroGridBackground(
          child: ComputerKeyboardListener(
            active: ref.watch(mainShellIndexProvider) == 4,
            child: GestureDetector(
              onDoubleTap: _toggleControls,
              child: SafeArea(
                child: Column(
                  children: [
                    // ── Header ──
                    if (_showControls)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 20),
                              tooltip: 'Exit Performance Mode',
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  ref.read(mainShellIndexProvider.notifier).state = 1;
                                }
                              },
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    preset.name.toUpperCase(),
                                    style: GoogleFonts.orbitron(
                                      color: SynthTheme.magenta,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 3,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  Text(
                                    preset.category.displayName.toUpperCase(),
                                    style: TextStyle(
                                      color: SynthTheme.textSecondary,
                                      fontSize: 10,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          IconButton(
                            icon: const Icon(Icons.layers_outlined, color: Colors.white, size: 20),
                            tooltip: 'Toggle controls',
                            onPressed: _toggleControls,
                          ),
                          _SetlistPicker(),
                          _SetlistActionsMenu(),
                          ],
                        ),
                      ),

                    // ── X/Y Expression Pad ──
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _ExpressionPad(
                          cutoff: preset.filter.cutoff,
                          resonance: preset.filter.resonance,
                          onChanged: (cutoff, resonance) {
                            notifier.update(
                              (p) => p.copyWith(
                                filter: p.filter.copyWith(
                                  cutoff: cutoff,
                                  resonance: resonance,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // ── Big Master Volume ──
                    if (_showControls)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: _BigMasterVolume(
                          volume: preset.masterVolume,
                          onChanged: (v) => notifier.update(
                            (p) => p.copyWith(masterVolume: v),
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // ── Performance meters (CPU + voices) ──
                    if (_showControls) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: PerformanceMeters(),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // ── Setlist Presets ──
                    const _SetlistPresetStrip(),

                    // ── Keyboard ──
                    const KeyboardWidget(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef ExpressionPadCallback = void Function(double cutoff, double resonance);

class _ExpressionPad extends StatefulWidget {
  final double cutoff;
  final double resonance;
  final ExpressionPadCallback onChanged;

  const _ExpressionPad({
    required this.cutoff,
    required this.resonance,
    required this.onChanged,
  });

  @override
  State<_ExpressionPad> createState() => _ExpressionPadState();
}

class _ExpressionPadState extends State<_ExpressionPad> {
  Offset? _currentPos;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        final cutoffX = (widget.cutoff - 20) / (20000 - 20);
        final resonanceY = 1.0 - widget.resonance; // invert so up = more resonance

        final dotX = cutoffX * width;
        final dotY = resonanceY * height;

        return GestureDetector(
          onPanStart: (details) => _updatePosition(details.localPosition, width, height),
          onPanUpdate: (details) => _updatePosition(details.localPosition, width, height),
          onPanEnd: (_) => setState(() => _currentPos = null),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0A0118),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: SynthTheme.cyan.withValues(alpha: 0.3),
              ),
              boxShadow: [
                BoxShadow(
                  color: SynthTheme.cyan.withValues(alpha: 0.1),
                  blurRadius: 20,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CustomPaint(
                painter: _ExpressionPadPainter(
                  dotX: dotX,
                  dotY: dotY,
                  isActive: _currentPos != null,
                ),
                size: Size(width, height),
              ),
            ),
          ),
        );
      },
    );
  }

  void _updatePosition(Offset pos, double width, double height) {
    final x = pos.dx.clamp(0.0, width);
    final y = pos.dy.clamp(0.0, height);
    setState(() => _currentPos = Offset(x, y));

    final cutoff = 20.0 + (x / width) * (20000.0 - 20.0);
    final resonance = 1.0 - (y / height);
    widget.onChanged(cutoff, resonance.clamp(0.0, 1.0));
  }
}

class _ExpressionPadPainter extends CustomPainter {
  final double dotX;
  final double dotY;
  final bool isActive;

  _ExpressionPadPainter({
    required this.dotX,
    required this.dotY,
    required this.isActive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Grid lines
    final gridPaint = Paint()
      ..color = SynthTheme.purple.withValues(alpha: 0.08)
      ..strokeWidth = 1;

    for (int i = 1; i < 8; i++) {
      final x = width * i / 8;
      canvas.drawLine(Offset(x, 0), Offset(x, height), gridPaint);
      final y = height * i / 8;
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // Crosshair at dot
    final crosshairPaint = Paint()
      ..color = SynthTheme.cyan.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(dotX, 0), Offset(dotX, height), crosshairPaint);
    canvas.drawLine(Offset(0, dotY), Offset(width, dotY), crosshairPaint);

    // Glow around dot
    final glowPaint = Paint()
      ..color = SynthTheme.cyan.withValues(alpha: isActive ? 0.3 : 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    canvas.drawCircle(Offset(dotX, dotY), 30, glowPaint);

    // Dot
    canvas.drawCircle(
      Offset(dotX, dotY),
      8,
      Paint()..color = Colors.white.withValues(alpha: isActive ? 1.0 : 0.8),
    );

    // Ring
    canvas.drawCircle(
      Offset(dotX, dotY),
      12,
      Paint()
        ..color = SynthTheme.cyan.withValues(alpha: isActive ? 0.6 : 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Labels
    final labelStyle = TextStyle(
      color: SynthTheme.textSecondary.withValues(alpha: 0.5),
      fontSize: 10,
    );

    _drawLabel(canvas, 'FILTER CUTOFF', width / 2, height - 16, labelStyle);
    _drawLabel(canvas, 'RESONANCE', 10, height / 2, labelStyle, rotate: true);
  }

  void _drawLabel(Canvas canvas, String text, double x, double y, TextStyle style, {bool rotate = false}) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    if (rotate) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(-pi / 2);
      painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
      canvas.restore();
    } else {
      painter.paint(canvas, Offset(x - painter.width / 2, y - painter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _ExpressionPadPainter old) =>
      dotX != old.dotX || dotY != old.dotY || isActive != old.isActive;
}

class _BigMasterVolume extends StatelessWidget {
  final double volume;
  final ValueChanged<double> onChanged;

  const _BigMasterVolume({required this.volume, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(width: 60),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: SynthTheme.orange,
              inactiveTrackColor: SynthTheme.purple.withValues(alpha: 0.2),
              thumbColor: SynthTheme.orange,
              overlayColor: SynthTheme.orange.withValues(alpha: 0.2),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            ),
            child: Slider(
              value: volume,
              min: 0,
              max: 1,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 60,
          child: Text(
            '${(volume * 100).round()}%',
            style: TextStyle(
              color: SynthTheme.orange,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

/// Dropdown to select an active setlist for quick preset recall during live play.
class _SetlistPicker extends ConsumerWidget {
  const _SetlistPicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setlists = ref.watch(setlistsProvider);
    final activeName = ref.watch(activeSetlistProvider);

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: SynthTheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.25)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          isDense: true,
          value: activeName,
          dropdownColor: SynthTheme.surface,
          style: const TextStyle(color: Colors.white, fontSize: 11),
          icon: Icon(Icons.arrow_drop_down, color: SynthTheme.cyan, size: 16),
          hint: Text(
            'Setlist',
            style: TextStyle(color: SynthTheme.textSecondary.withValues(alpha: 0.6), fontSize: 11),
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('None'),
            ),
            ...setlists.keys.map((name) {
              return DropdownMenuItem<String?>(
                value: name,
                child: Text(name),
              );
            }),
          ],
          onChanged: (name) {
            ref.read(activeSetlistProvider.notifier).state = name;
          },
        ),
      ),
    );
  }
}

/// Popup menu for setlist CRUD: create, rename, delete.
class _SetlistActionsMenu extends ConsumerWidget {
  const _SetlistActionsMenu();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: SynthTheme.textSecondary, size: 18),
      color: SynthTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onSelected: (value) => _handleAction(context, ref, value),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'create',
          child: Row(
            children: [
              Icon(Icons.add, color: SynthTheme.cyan, size: 18),
              SizedBox(width: 8),
              Text('New Setlist', style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit, color: SynthTheme.cyan, size: 18),
              SizedBox(width: 8),
              Text('Rename Setlist', style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, color: SynthTheme.magenta, size: 18),
              SizedBox(width: 8),
              Text('Delete Setlist', style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, String action) {
    final activeName = ref.read(activeSetlistProvider);
    final currentPreset = ref.read(currentPresetProvider);

    switch (action) {
      case 'create':
        _showCreateDialog(context, ref, currentPreset.id);
        break;
      case 'rename':
        if (activeName != null) {
          _showRenameDialog(context, ref, activeName);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Select a setlist to rename'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        break;
      case 'delete':
        if (activeName != null) {
          _confirmDelete(context, ref, activeName);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Select a setlist to delete'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        break;
    }
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref, String initialPresetId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SynthTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: SynthTheme.cyan.withValues(alpha: 0.3)),
        ),
        title: Text(
          'New Setlist',
          style: TextStyle(color: SynthTheme.cyan, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Setlist name...',
            hintStyle: TextStyle(color: SynthTheme.textSecondary.withValues(alpha: 0.6)),
            filled: true,
            fillColor: SynthTheme.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: SynthTheme.purple.withValues(alpha: 0.2)),
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
              final name = controller.text.trim();
              if (name.isEmpty) return;
              if (ref.read(setlistsProvider).containsKey(name)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('A setlist named "$name" already exists'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              ref.read(setlistsProvider.notifier).createSetlist(name, [initialPresetId]);
              ref.read(activeSetlistProvider.notifier).state = name;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Created setlist "$name"'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'CREATE',
              style: TextStyle(color: SynthTheme.cyan, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SynthTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: SynthTheme.cyan.withValues(alpha: 0.3)),
        ),
        title: Text(
          'Rename Setlist',
          style: TextStyle(color: SynthTheme.cyan, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'New name...',
            hintStyle: TextStyle(color: SynthTheme.textSecondary.withValues(alpha: 0.6)),
            filled: true,
            fillColor: SynthTheme.card,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: SynthTheme.purple.withValues(alpha: 0.2)),
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
              if (newName.isEmpty || newName == oldName) return;
              if (ref.read(setlistsProvider).containsKey(newName)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('A setlist named "$newName" already exists'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              ref.read(setlistsProvider.notifier).renameSetlist(oldName, newName);
              ref.read(activeSetlistProvider.notifier).state = newName;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Renamed to "$newName"'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'RENAME',
              style: TextStyle(color: SynthTheme.cyan, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: SynthTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: SynthTheme.magenta.withValues(alpha: 0.3)),
        ),
        title: Text(
          'Delete Setlist?',
          style: TextStyle(color: SynthTheme.magenta, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "$name"? This cannot be undone.',
          style: TextStyle(color: SynthTheme.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: TextStyle(color: SynthTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              ref.read(setlistsProvider.notifier).deleteSetlist(name);
              ref.read(activeSetlistProvider.notifier).state = null;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Deleted "$name"'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: Text(
              'DELETE',
              style: TextStyle(color: SynthTheme.magenta, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal strip of presets from the active setlist with drag reorder.
class _SetlistPresetStrip extends ConsumerWidget {
  const _SetlistPresetStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeName = ref.watch(activeSetlistProvider);
    final setlists = ref.watch(setlistsProvider);
    final allPresets = ref.watch(presetListProvider);
    final current = ref.watch(currentPresetProvider);

    if (activeName == null || !setlists.containsKey(activeName)) {
      return const SizedBox.shrink();
    }

    final presetIds = setlists[activeName]!.presetIds;
    final presetMap = {for (final p in allPresets) p.id: p};
    final presets = presetIds
        .map((id) => presetMap[id])
        .whereType<SynthPreset>()
        .toList();

    if (presets.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        onReorder: (oldIndex, newIndex) {
          if (newIndex > oldIndex) newIndex--;
          final reordered = [...presets];
          final item = reordered.removeAt(oldIndex);
          reordered.insert(newIndex, item);

          // Rewrite raw presetIds: replace valid IDs in order, keep invalid IDs in place.
          final newRawIds = [...presetIds];
          var validIdx = 0;
          for (int i = 0; i < newRawIds.length; i++) {
            if (presetMap.containsKey(newRawIds[i])) {
              newRawIds[i] = reordered[validIdx++].id;
            }
          }

          ref.read(setlistsProvider.notifier).updateSetlistOrder(activeName, newRawIds);
        },
        proxyDecorator: (child, index, animation) {
          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.05,
                child: Material(
                  color: Colors.transparent,
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: child,
                ),
              );
            },
            child: child,
          );
        },
        itemBuilder: (context, index) {
          final p = presets[index];
          final isActive = p.id == current.id;
          return Container(
            key: ValueKey(p.id),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                ref.read(currentPresetProvider.notifier).load(p);
                ref.read(recentPresetsProvider.notifier).track(p.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Loaded "${p.name}"'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
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
            ),
          );
        },
      ),
    );
  }
}


