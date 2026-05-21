// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

/// Sumber kebenaran tunggal untuk semua styling visual aplikasi.
/// Semua warna, spacing, sizing, dan typography constants ada di sini.
class AppTheme {
  AppTheme._();

  // =========================================
  // 🟢 WARNA AKSEN UTAMA
  // =========================================
  static const Color primaryAccent = Color(0xFF00AA5B);

  // =========================================
  // 🌑 TEMA GELAP
  // =========================================
  static const Color darkBg = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkText = Colors.white;
  static const Color darkTextSub = Colors.white54;
  static const Color darkBorder = Colors.white10;

  // =========================================
  // ☀️ TEMA TERANG
  // =========================================
  static const Color lightBg = Color(0xFFF5F6F8);
  static const Color lightCard = Colors.white;
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color lightTextSub = Color(0xFF757575);
  static const Color lightBorder = Color(0xFFE0E0E0);

  // =========================================
  // 📐 SPACING & SIZING
  // =========================================
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0;
  static const double radiusXl = 32.0;

  static const double paddingSm = 8.0;
  static const double paddingMd = 16.0;
  static const double paddingLg = 24.0;

  static const double fontXs = 10.0;
  static const double fontSm = 12.0;
  static const double fontMd = 14.0;
  static const double fontLg = 18.0;
  static const double fontXl = 24.0;

  // =========================================
  // 🎨 CHART COLORS (pindah dari Formatters)
  // =========================================
  static const List<Color> chartColors = [
    Color(0xFFA855F7), // Purple
    Color(0xFFD946EF), // Fuchsia
    Color(0xFF8B5CF6), // Violet
    Color(0xFFC084FC), // Light Purple
    Color(0xFFE879F9), // Light Fuchsia
    Color(0xFFA78BFA), // Light Violet
  ];

  // =========================================
  // 🎭 THEME DATA
  // =========================================
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(
        primary: primaryAccent,
        surface: darkCard,
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: lightBg,
      colorScheme: const ColorScheme.light(
        primary: primaryAccent,
        surface: lightCard,
      ),
    );
  }
}