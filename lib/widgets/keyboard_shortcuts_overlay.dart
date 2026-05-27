import 'package:flutter/material.dart';
import '../theme/synth_theme.dart';

// A bottom-sheet overlay listing all keyboard shortcuts for Open Synth.
class KeyboardShortcutsOverlay extends StatelessWidget {
  const KeyboardShortcutsOverlay({super.key});

  static final _shortcuts = <_ShortcutGroup>[
    _ShortcutGroup('Piano Keys — Lower Octave', [
      _Shortcut('Z S X D C V G B H N J M ,', 'C C# D D# E F F# G G# A A# B C (octave)'),
    ]),
    _ShortcutGroup('Piano Keys — Upper Octave', [
      _Shortcut('Q 2 W 3 E R 5 T 6 Y 7 U I', 'C C# D D# E F F# G G# A A# B C (octave+1)'),
    ]),
    _ShortcutGroup('Octave & Panic', [
      _Shortcut('[', 'Octave down'),
      _Shortcut(']', 'Octave up'),
      _Shortcut('\\', 'Panic — all notes off'),
    ]),
    _ShortcutGroup('Transport', [
      _Shortcut('Space', 'Toggle sequencer play/stop'),
      _Shortcut('R', 'Toggle sequencer recording'),
    ]),
    _ShortcutGroup('Undo / Redo', [
      _Shortcut('Ctrl+Z', 'Undo'),
      _Shortcut('Ctrl+Shift+Z', 'Redo'),
      _Shortcut('Ctrl+Y', 'Redo'),
    ]),
    _ShortcutGroup('A/B Comparison', [
      _Shortcut('Shift+B', 'Capture current snapshot'),
      _Shortcut('Ctrl+B', 'Toggle A/B bank'),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: SynthTheme.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(
              top: BorderSide(color: SynthTheme.purple.withValues(alpha: 0.3)),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: SynthTheme.purple.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    Icon(Icons.keyboard, color: SynthTheme.cyan, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'KEYBOARD SHORTCUTS',
                      style: TextStyle(
                        color: SynthTheme.cyan,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: SynthTheme.purple.withValues(alpha: 0.2), height: 1),
              // Shortcuts list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final group in _shortcuts) ...[
                      _GroupHeader(label: group.label),
                      const SizedBox(height: 6),
                      for (final shortcut in group.items)
                        _ShortcutRow(shortcut: shortcut),
                      const SizedBox(height: 16),
                    ],
                    // Footer hint
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: SynthTheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: SynthTheme.cyan.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: SynthTheme.cyan, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tap anywhere on the synth screen to re-focus the keyboard before playing.',
                              style: TextStyle(
                                color: SynthTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShortcutGroup {
  final String label;
  final List<_Shortcut> items;
  const _ShortcutGroup(this.label, this.items);
}

class _Shortcut {
  final String keys;
  final String description;
  const _Shortcut(this.keys, this.description);
}

class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: SynthTheme.magenta,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ShortcutRow extends StatelessWidget {
  final _Shortcut shortcut;
  const _ShortcutRow({required this.shortcut});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            constraints: const BoxConstraints(minWidth: 120),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: SynthTheme.surface,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: SynthTheme.purple.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              shortcut.keys,
              style: TextStyle(
                color: SynthTheme.cyan,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              shortcut.description,
              style: TextStyle(
                color: SynthTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
