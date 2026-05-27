import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SynthTheme {
  static const _bg = Color(0xFF0D0221);
  static const _surface = Color(0xFF150530);
  static const _card = Color(0xFF1E0840);
  static const _magenta = Color(0xFFFF2975);
  static const _orange = Color(0xFFFF6B35);
  static const _purple = Color(0xFF9B30FF);
  static const _cyan = Color(0xFF00E5FF);
  static const _textPrimary = Color(0xFFFFFFFF);
  static const _textSecondary = Color(0xFFA090C0);

  // Light theme colors
  static const _lightBg = Color(0xFFF5F0FF);
  static const _lightSurface = Color(0xFFFFFFFF);
  static const _lightCard = Color(0xFFEDE8F7);
  static const _lightTextPrimary = Color(0xFF1A0A2E);
  static const _lightTextSecondary = Color(0xFF6B5B8A);

  static Color get bg => _bg;
  static Color get magenta => _magenta;
  static Color get orange => _orange;
  static Color get purple => _purple;
  static Color get cyan => _cyan;
  static Color get card => _card;
  static Color get surface => _surface;
  static Color get textSecondary => _textSecondary;

  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        bg: _bg,
        surface: _surface,
        card: _card,
        textPrimary: _textPrimary,
        textSecondary: _textSecondary,
      );

  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        bg: _lightBg,
        surface: _lightSurface,
        card: _lightCard,
        textPrimary: _lightTextPrimary,
        textSecondary: _lightTextSecondary,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color bg,
    required Color surface,
    required Color card,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: _magenta,
        onPrimary: Colors.white,
        secondary: _orange,
        onSecondary: Colors.white,
        error: Colors.redAccent,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
      cardColor: card,
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: GoogleFonts.orbitron(
          color: _magenta,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
      textTheme: GoogleFonts.interTextTheme(
        TextTheme(
          headlineLarge: TextStyle(
              color: textPrimary, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textSecondary),
        ),
      ),
      dividerColor: isDark ? _purple.withValues(alpha: 0.1) : _purple.withValues(alpha: 0.15),
    );
  }
}
