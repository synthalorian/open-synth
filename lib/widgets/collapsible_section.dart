import 'package:flutter/material.dart';
import '../theme/synth_theme.dart';

/// A reusable collapsible section widget styled for the synthwave theme.
///
/// Shows a colored indicator dot + title in the header. Starts collapsed.
/// Expands to reveal [child] content.
class CollapsibleSection extends StatefulWidget {
  final String title;
  final Color accentColor;
  final bool initiallyExpanded;
  final Widget child;

  const CollapsibleSection({
    super.key,
    required this.title,
    required this.accentColor,
    this.initiallyExpanded = false,
    required this.child,
  });

  @override
  State<CollapsibleSection> createState() => _CollapsibleSectionState();
}

class _CollapsibleSectionState extends State<CollapsibleSection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: SynthTheme.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: ExpansionTileThemeData(
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            iconColor: widget.accentColor,
            collapsedIconColor: SynthTheme.textSecondary.withValues(alpha: 0.4),
          ),
        ),
        child: ExpansionTile(
          initiallyExpanded: widget.initiallyExpanded,
          onExpansionChanged: (v) => setState(() => _expanded = v),
          tilePadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
          dense: true,
          title: Row(
            children: [
              // Colored indicator dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _expanded
                      ? widget.accentColor
                      : widget.accentColor.withValues(alpha: 0.5),
                  boxShadow: _expanded
                      ? [
                          BoxShadow(
                            color: widget.accentColor.withValues(alpha: 0.6),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.title,
                style: TextStyle(
                  color: _expanded ? widget.accentColor : SynthTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          children: [
            widget.child,
          ],
        ),
      ),
    );
  }
}
