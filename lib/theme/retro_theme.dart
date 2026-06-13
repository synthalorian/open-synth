import 'package:flutter/material.dart';

/// Synthwave '84 aesthetic for Open Synth.
///
/// Deep purples, electric magenta, hot pink, and neon yellow
/// against a near-black background. Inspired by Outrun, Hotline Miami,
/// and the neon grid of 1984.
class RetroTheme {
  // ── Primary Synthwave Colors ─────────────────────────────────────
  /// Deep purple — primary background, the void of the grid
  static const deepPurple = Color(0xFF240037);

  /// Electric purple — secondary accent, voltage running through circuits
  static const electricPurple = Color(0xFF8F00FF);

  /// Neon yellow — primary accent, like a Juno-106 button LED
  static const neonYellow = Color(0xFFF3E70F);

  /// Hot pink — selected states, active controls, the sunset gradient
  static const hotPink = Color(0xFFFF7EDB);

  /// Magenta — warnings, clipping, the edge of the grid
  static const magenta = Color(0xFFFF00FF);

  // ── Chassis / Panel Colors ───────────────────────────────────────
  /// Near-black chassis — darker than deep purple for depth
  static const chassis = Color(0xFF0D0014);

  /// Raised panel — deep purple with slight lift
  static const panel = Color(0xFF1A0029);

  /// Active/selected panel — glowing with purple energy
  static const panelActive = Color(0xFF2D0044);

  /// Shadow for recessed areas — the dark between circuits
  static const shadow = Color(0xFF080010);

  /// Highlight for raised edges — neon reflection
  static const highlight = Color(0xFF3D0066);

  // ── Text Colors ──────────────────────────────────────────────────
  /// Primary text — warm white, like CRT phosphor
  static const textPrimary = Color(0xFFF0E8FF);

  /// Secondary text — dimmed purple, like distant grid lines
  static const textSecondary = Color(0xFF8A70A0);

  /// Text on dark backgrounds — for labels on panels
  static const textDark = Color(0xFF1A0033);

  // ── LCD Colors ───────────────────────────────────────────────────
  /// LCD background — deep purple, almost black
  static const lcdBg = Color(0xFF140022);

  /// LCD active pixels — neon yellow phosphor glow
  static const lcdPixel = Color(0xFFF3E70F);

  /// LCD dim pixels — ghosting from previous frames
  static const lcdGhost = Color(0xFF3D3050);

  // ── LED Colors ───────────────────────────────────────────────────
  /// LED off — dark, barely visible
  static const ledOff = Color(0xFF1A0A2E);

  /// LED on — neon yellow
  static const ledOn = Color(0xFFF3E70F);

  /// LED selected — hot pink
  static const ledSelected = Color(0xFFFF7EDB);

  // ── Knob Colors ──────────────────────────────────────────────────
  /// Knob body — dark bakelite with purple tint
  static const knobBody = Color(0xFF1A0033);

  /// Knob cap — slightly lighter
  static const knobCap = Color(0xFF26004D);

  /// Knob indicator line — neon yellow
  static const knobIndicator = Color(0xFFF3E70F);

  /// Knob tick marks — dim purple
  static const knobTicks = Color(0xFF4A3066);

  /// Knob active arc — hot pink glow
  static const knobArc = Color(0xFFFF7EDB);

  // ── Key Colors ───────────────────────────────────────────────────
  /// White key — aged ivory with purple shadow
  static const keyWhite = Color(0xFFF0E8F8);

  /// Black key — warm black with purple undertone
  static const keyBlack = Color(0xFF140A1E);

  /// Key pressed — hot pink glow
  static const keyPressed = Color(0xFFFFB8F0);

  // ── Gradients ────────────────────────────────────────────────────
  static LinearGradient get chassisGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A0029), Color(0xFF0D0014)],
  );

  static LinearGradient get panelGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2D0044), Color(0xFF1A0029)],
  );

  static LinearGradient get sunsetGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF240037),  // deep purple
      Color(0xFF8F00FF),  // electric purple
      Color(0xFFFF7EDB),  // hot pink
      Color(0xFFFF00FF),  // magenta
    ],
  );

  // ── Glow Effects ─────────────────────────────────────────────────
  static BoxShadow get yellowGlow => BoxShadow(
    color: neonYellow.withOpacity(0.4),
    blurRadius: 10,
    spreadRadius: 2,
  );

  static BoxShadow get pinkGlow => BoxShadow(
    color: hotPink.withOpacity(0.35),
    blurRadius: 12,
    spreadRadius: 2,
  );

  static BoxShadow get magentaGlow => BoxShadow(
    color: magenta.withOpacity(0.4),
    blurRadius: 14,
    spreadRadius: 3,
  );

  // ── Typography ───────────────────────────────────────────────────
  static TextStyle get lcdText => const TextStyle(
    fontFamily: 'Courier',
    fontFamilyFallback: ['monospace'],
    color: lcdPixel,
    fontSize: 14,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.0,
  );

  static TextStyle get labelText => const TextStyle(
    fontFamily: 'Courier',
    fontFamilyFallback: ['monospace'],
    color: textSecondary,
    fontSize: 9,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5,
  );

  static TextStyle get valueText => const TextStyle(
    fontFamily: 'Courier',
    fontFamilyFallback: ['monospace'],
    color: textPrimary,
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  static TextStyle get headerText => const TextStyle(
    fontFamily: 'Courier',
    fontFamilyFallback: ['monospace'],
    color: neonYellow,
    fontSize: 12,
    fontWeight: FontWeight.bold,
    letterSpacing: 2.0,
  );

  // ── ThemeData ────────────────────────────────────────────────────
  static ThemeData get theme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: chassis,
    colorScheme: const ColorScheme.dark(
      primary: neonYellow,
      secondary: hotPink,
      surface: panel,
      onSurface: textPrimary,
    ),
    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: textPrimary, fontFamily: 'Courier'),
      bodySmall: TextStyle(color: textSecondary, fontFamily: 'Courier'),
      titleMedium: TextStyle(color: neonYellow, fontFamily: 'Courier', fontWeight: FontWeight.bold),
    ),
  );
}
