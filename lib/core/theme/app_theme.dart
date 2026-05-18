// lib/core/theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  // 🟢 WARNA AKSEN UTAMA (Hijau ala GoPay)
  static const Color primaryAccent = Color(0xFF00AA5B); 

  // =========================================
  // 🌑 TEMA GELAP (STANDAR INDUSTRI)
  // =========================================
  static const Color darkBg = Color(0xFF121212);
  static const Color darkCard = Color(0xFF1E1E1E);
  static const Color darkText = Colors.white;
  static const Color darkTextSub = Colors.white54;
  static const Color darkBorder = Colors.white10;

  // =========================================
  // ☀️ TEMA TERANG (BERSIH & MINIMALIS)
  // =========================================
  static const Color lightBg = Color(0xFFF5F6F8);
  static const Color lightCard = Colors.white;
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color lightTextSub = Color(0xFF757575);
  static const Color lightBorder = Color(0xFFE0E0E0);

  // 🟢 OBAT ERROR main.dart: Kita kasih lagi ThemeData bawaannya
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBg,
      colorScheme: const ColorScheme.dark(primary: primaryAccent, surface: darkCard),
    );
  }
}