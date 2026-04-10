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

  static Color get bg => _bg;
  static Color get magenta => _magenta;
  static Color get orange => _orange;
  static Color get purple => _purple;
  static Color get cyan => _cyan;
  static Color get card => _card;
  static Color get surface => _surface;
  static Color get textSecondary => _textSecondary;

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _bg,
        colorScheme: const ColorScheme.dark(
          primary: _magenta,
          secondary: _orange,
          surface: _surface,
        ),
        cardColor: _card,
        appBarTheme: AppBarTheme(
          backgroundColor: _bg,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.orbitron(
            color: _magenta,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        textTheme: GoogleFonts.interTextTheme(
          const TextTheme(
            headlineLarge: TextStyle(
                color: _textPrimary, fontWeight: FontWeight.bold),
            bodyLarge: TextStyle(color: _textPrimary),
            bodyMedium: TextStyle(color: _textSecondary),
          ),
        ),
      );
}
