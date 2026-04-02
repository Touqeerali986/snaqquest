import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData light() {
    const baseBackground = Color(0xFFF9F4EC);
    const cardSurface = Color(0xFFFFFCF8);
    const inkDark = Color(0xFF1C1A18);
    const accent = Color(0xFF0E8A7A);
    const accentDeep = Color(0xFF0A6E61);

    final textTheme = GoogleFonts.spaceGroteskTextTheme().copyWith(
      headlineLarge: GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w700,
        color: inkDark,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w700,
        color: inkDark,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        fontWeight: FontWeight.w600,
        color: inkDark,
      ),
      bodyLarge: GoogleFonts.spaceGrotesk(color: inkDark),
      bodyMedium: GoogleFonts.spaceGrotesk(
        color: inkDark.withValues(alpha: 0.85),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: baseBackground,
      textTheme: textTheme,
      colorScheme: const ColorScheme.light(
        primary: accent,
        onPrimary: Colors.white,
        secondary: Color(0xFFDB8A00),
        onSecondary: Colors.white,
        surface: cardSurface,
        onSurface: inkDark,
        error: Color(0xFFB3261E),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accent, width: 1.4),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          foregroundColor: accentDeep,
          side: const BorderSide(color: accentDeep),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
