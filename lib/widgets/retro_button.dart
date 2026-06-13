import 'package:flutter/material.dart';
import '../theme/retro_theme.dart';

/// A retro push-button widget — hardware-style with LED indicator.
///
/// Can be momentary (default) or toggle. Shows an LED that glows
/// when the button is active/pressed.
class RetroButton extends StatefulWidget {
  final String label;
  final bool isActive;
  final bool isToggle;
  final VoidCallback? onPressed;
  final double width;
  final double height;

  const RetroButton({
    super.key,
    required this.label,
    this.isActive = false,
    this.isToggle = false,
    this.onPressed,
    this.width = 64,
    this.height = 32,
  });

  @override
  State<RetroButton> createState() => _RetroButtonState();
}

class _RetroButtonState extends State<RetroButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bool showActive = widget.isToggle ? widget.isActive : _pressed;

    return GestureDetector(
      onTapDown: (_) {
        if (!widget.isToggle) {
          setState(() => _pressed = true);
        }
        widget.onPressed?.call();
      },
      onTapUp: (_) {
        if (!widget.isToggle) {
          setState(() => _pressed = false);
        }
      },
      onTapCancel: () {
        if (!widget.isToggle) {
          setState(() => _pressed = false);
        }
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: showActive
                ? [RetroTheme.panelActive, RetroTheme.panel]
                : [RetroTheme.panel, RetroTheme.shadow.withOpacity(0.3)],
          ),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(
            color: showActive
                ? RetroTheme.neonYellow.withOpacity(0.4)
                : RetroTheme.highlight.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            // Raised when not pressed, recessed when pressed
            BoxShadow(
              color: showActive
                  ? Colors.black.withOpacity(0.6)
                  : Colors.black.withOpacity(0.3),
              blurRadius: showActive ? 1 : 3,
              offset: showActive ? const Offset(0, 1) : const Offset(0, 2),
            ),
            if (showActive)
              BoxShadow(
                color: RetroTheme.neonYellow.withOpacity(0.15),
                blurRadius: 6,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LED
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: showActive ? RetroTheme.ledOn : RetroTheme.ledOff,
                boxShadow: showActive
                    ? [
                        BoxShadow(
                          color: RetroTheme.ledOn.withOpacity(0.6),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            ),
            const SizedBox(height: 3),
            // Label
            Text(
              widget.label.toUpperCase(),
              style: RetroTheme.labelText.copyWith(
                fontSize: 8,
                color: showActive
                    ? RetroTheme.textPrimary
                    : RetroTheme.textSecondary.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
