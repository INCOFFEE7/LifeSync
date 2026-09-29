import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white, // Pure white background
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2563EB), // Tailwind Blue 600
        secondary: const Color(0xFF3B82F6), 
        brightness: Brightness.light,
        surface: Colors.white, 
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1E3A8A), // Deep Blue 900 for titles
        surfaceTintColor: Colors.transparent, 
      ),
      cardTheme: CardThemeData(
        elevation: 0, // Flat elegant look
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE0E7FF), width: 1.5), // Very light indigo/blue border
        ),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB), // High contrast blue buttons
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF0F172A), // Very deep blue/slate
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF3B82F6), // Blue 500
        secondary: const Color(0xFF60A5FA),
        brightness: Brightness.dark,
        surface: const Color(0xFF1E293B), 
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF0F172A),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF334155), width: 1), // Subtle blue-slate border
        ),
        color: const Color(0xFF1E293B),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
