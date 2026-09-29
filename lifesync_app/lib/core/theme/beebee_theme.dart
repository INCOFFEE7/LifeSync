import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BeebeeTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFFFF0F5), // Blush White
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFE91E8C), // Rose Pink
        secondary: const Color(0xFFC77DFF), // Lavender
        tertiary: const Color(0xFFFDE8E9), // Soft Beige/Pink
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFFE91E8C), 
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFCE7F3), width: 1.5), 
        ),
        color: Colors.white,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFE91E8C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFE91E8C),
        foregroundColor: Colors.white,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFF2A1B29), // Deep Plum
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFE91E8C),
        secondary: const Color(0xFFC77DFF),
        brightness: Brightness.dark,
        surface: const Color(0xFF382335),
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color(0xFF2A1B29),
        foregroundColor: Color(0xFFF472B6), // Pink 400
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFF50354C), width: 1),
        ),
        color: const Color(0xFF382335),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFFE91E8C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: Color(0xFFE91E8C),
        foregroundColor: Colors.white,
      ),
    );
  }
}
