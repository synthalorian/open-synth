import 'package:flutter/material.dart';
import '../theme/retro_theme.dart';

/// A rack module container — expandable hardware panel with screws and depth.
///
/// Inspired by 19" rack units and synth front panels. Has corner screws,
/// a header with LED indicator, and a recessed body that expands/collapses.
class RetroRackModule extends StatefulWidget {
  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final bool isActive;
  final VoidCallback? onToggle;

  const RetroRackModule({
    super.key,
    required this.title,
    required this.child,
    this.initiallyExpanded = true,
    this.isActive = true,
    this.onToggle,
  });

  @override
  State<RetroRackModule> createState() => _RetroRackModuleState();
}

class _RetroRackModuleState extends State<RetroRackModule> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: RetroTheme.panelGradient,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: widget.isActive
              ? RetroTheme.highlight.withOpacity(0.3)
              : RetroTheme.shadow.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          // Drop shadow — panel is raised
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
          // Inner highlight — top edge
          BoxShadow(
            color: RetroTheme.highlight.withOpacity(0.1),
            blurRadius: 0,
            spreadRadius: 1,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header with screws ─────────────────────────────────────
          GestureDetector(
            onTap: () {
              setState(() => _expanded = !_expanded);
              widget.onToggle?.call();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: RetroTheme.panel.withOpacity(0.8),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(4),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: RetroTheme.shadow.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Screw
                  _Screw(),
                  const SizedBox(width: 10),
                  // LED indicator
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isActive
                          ? RetroTheme.ledOn
                          : RetroTheme.ledOff,
                      boxShadow: widget.isActive
                          ? [
                              BoxShadow(
                                color: RetroTheme.ledOn.withOpacity(0.5),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Title
                  Expanded(
                    child: Text(
                      widget.title.toUpperCase(),
                      style: RetroTheme.headerText.copyWith(
                        color: widget.isActive
                            ? RetroTheme.neonYellow
                            : RetroTheme.neonYellow.withOpacity(0.4),
                      ),
                    ),
                  ),
                  // Expand/collapse arrow
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: RetroTheme.textSecondary,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  // Screw
                  _Screw(),
                ],
              ),
            ),
          ),
          // ── Body ───────────────────────────────────────────────────
          AnimatedCrossFade(
            firstChild: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RetroTheme.chassis.withOpacity(0.5),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(4),
                ),
              ),
              child: widget.child,
            ),
            secondChild: const SizedBox.shrink(),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

/// A small screw widget for the rack module corners.
class _Screw extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: RetroTheme.highlight.withOpacity(0.3),
        border: Border.all(
          color: RetroTheme.shadow.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Center(
        child: Container(
          width: 4,
          height: 1,
          color: RetroTheme.shadow.withOpacity(0.5),
        ),
      ),
    );
  }
}
