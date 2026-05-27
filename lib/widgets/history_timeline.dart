import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/undo_redo_provider.dart';
import '../theme/synth_theme.dart';

void _showBookmarkDialog(BuildContext context, WidgetRef ref, int index, String? existingName) {
  final controller = TextEditingController(text: existingName ?? '');
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: SynthTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          existingName != null ? 'Edit Bookmark' : 'Bookmark State',
          style: TextStyle(color: SynthTheme.cyan, fontSize: 14, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 13),
          decoration: InputDecoration(
            hintText: 'Name this state...',
            hintStyle: TextStyle(color: SynthTheme.textSecondary.withValues(alpha: 0.5)),
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
          onSubmitted: (value) {
            final name = value.trim();
            if (name.isNotEmpty) {
              ref.read(undoRedoProvider.notifier).bookmark(index, name);
            }
            Navigator.pop(context);
          },
        ),
        actions: [
          if (existingName != null)
            TextButton(
              onPressed: () {
                ref.read(undoRedoProvider.notifier).removeBookmark(index);
                Navigator.pop(context);
              },
              child: Text('Remove', style: TextStyle(color: Colors.redAccent)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: SynthTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(undoRedoProvider.notifier).bookmark(index, name);
              }
              Navigator.pop(context);
            },
            child: Text('Save', style: TextStyle(color: SynthTheme.cyan)),
          ),
        ],
      );
    },
  );
}

class HistoryTimeline extends ConsumerWidget {
  const HistoryTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(undoRedoProvider);
    final history = state.history;
    final currentIndex = state.currentIndex;

    return Container(
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: SynthTheme.cyan,
                    boxShadow: [
                      BoxShadow(
                        color: SynthTheme.cyan.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'HISTORY TIMELINE',
                  style: GoogleFonts.orbitron(
                    color: SynthTheme.cyan,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Text(
                  '${history.length} / 50',
                  style: TextStyle(
                    color: SynthTheme.textSecondary.withValues(alpha: 0.5),
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: SynthTheme.surface,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.close,
                      color: SynthTheme.textSecondary,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Timeline list
          if (history.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text(
                  'No history yet.\nMake some changes to build a timeline.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              height: 320,
              child: ListView.builder(
                reverse: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final isCurrent = index == currentIndex;
                  final isRedoable = index > currentIndex;
                  final snapshot = history[index];
                  final time = snapshot.createdAt ?? DateTime.now();
                  final timeStr =
                      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';

                  return GestureDetector(
                    onTap: () {
                      if (index == currentIndex) return;
                      final notifier = ref.read(undoRedoProvider.notifier);
                      if (index < currentIndex) {
                        for (int i = 0; i < currentIndex - index; i++) {
                          notifier.undo();
                        }
                      } else {
                        for (int i = 0; i < index - currentIndex; i++) {
                          notifier.redo();
                        }
                      }
                    },
                    onLongPress: () => _showBookmarkDialog(context, ref, index, snapshot.bookmarkName),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? SynthTheme.cyan.withValues(alpha: 0.1)
                            : isRedoable
                                ? SynthTheme.surface.withValues(alpha: 0.5)
                                : SynthTheme.surface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isCurrent
                              ? SynthTheme.cyan.withValues(alpha: 0.5)
                              : isRedoable
                                  ? SynthTheme.purple.withValues(alpha: 0.15)
                                  : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Index + indicator
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCurrent
                                  ? SynthTheme.cyan.withValues(alpha: 0.3)
                                  : isRedoable
                                      ? SynthTheme.purple.withValues(alpha: 0.15)
                                      : SynthTheme.purple.withValues(alpha: 0.1),
                              border: Border.all(
                                color: isCurrent
                                    ? SynthTheme.cyan
                                    : Colors.transparent,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '$index',
                              style: TextStyle(
                                color: isCurrent
                                    ? SynthTheme.cyan
                                    : SynthTheme.textSecondary
                                        .withValues(alpha: 0.5),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Connection line
                          Container(
                            width: 2,
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  if (isCurrent) ...[
                                    SynthTheme.cyan,
                                    SynthTheme.cyan.withValues(alpha: 0.3),
                                  ] else if (isRedoable) ...[
                                    SynthTheme.purple.withValues(alpha: 0.3),
                                    SynthTheme.purple.withValues(alpha: 0.1),
                                  ] else ...[
                                    SynthTheme.purple.withValues(alpha: 0.15),
                                    Colors.transparent,
                                  ],
                                ],
                              ),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                          const SizedBox(width: 10),
                          // Preset name + timestamp
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  snapshot.preset.name,
                                  style: TextStyle(
                                    color: isCurrent
                                        ? SynthTheme.cyan
                                        : isRedoable
                                            ? SynthTheme.textSecondary
                                                .withValues(alpha: 0.5)
                                            : Colors.white70,
                                    fontSize: 11,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Text(
                                      timeStr,
                                      style: TextStyle(
                                        color: SynthTheme.textSecondary
                                            .withValues(alpha: 0.4),
                                        fontSize: 9,
                                      ),
                                    ),
                                    if (snapshot.bookmarkName != null) ...[
                                      const SizedBox(width: 6),
                                      Icon(
                                        Icons.bookmark,
                                        color: SynthTheme.orange,
                                        size: 10,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        snapshot.bookmarkName!,
                                        style: TextStyle(
                                          color: SynthTheme.orange,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                    if (isCurrent) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: SynthTheme.cyan
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          'ACTIVE',
                                          style: TextStyle(
                                            color: SynthTheme.cyan,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ] else if (isRedoable) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: SynthTheme.purple
                                              .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          'REDO',
                                          style: TextStyle(
                                            color: SynthTheme.purple,
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // Bottom actions
          if (history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Text(
                    'Tap any entry to jump to that state',
                    style: TextStyle(
                      color: SynthTheme.textSecondary.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                  ),
                  const Spacer(),
                  _SmallBtn(
                    label: 'Clear History',
                    onTap: () {
                      ref.read(undoRedoProvider.notifier).clear();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SmallBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: SynthTheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: SynthTheme.purple.withValues(alpha: 0.25)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: SynthTheme.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
