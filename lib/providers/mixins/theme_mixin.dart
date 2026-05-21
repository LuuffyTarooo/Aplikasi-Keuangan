// lib/providers/mixins/theme_mixin.dart
import 'package:flutter/material.dart';
import 'package:aplikasi_keuangan/core/constants/app_constants.dart';
import 'package:aplikasi_keuangan/services/local_storage_service.dart';

/// Mixin untuk mengelola tema (dark/light mode) dan warna aksen.
/// Semua getter warna adaptif berdasarkan mode aktif.
mixin ThemeMixin on ChangeNotifier {
  bool _isDarkMode = true;
  Color _themeAccentColor = const Color(0xFF00AA5B);

  bool get isDarkMode => _isDarkMode;
  Color get themeAccent => _themeAccentColor;

  Color get themeBg => _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F6F8);
  Color get themeCard => _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get themeText => _isDarkMode ? Colors.white : const Color(0xFF1A1A1A);
  Color get themeTextSub => _isDarkMode ? Colors.white54 : const Color(0xFF757575);
  Color get themeBorder => _isDarkMode ? Colors.white10 : const Color(0xFFE0E0E0);

  // Harus di-override oleh FinanceProvider agar bisa trigger sync.
  void syncToStorage();

  /// Memuat preferensi tema dari penyimpanan lokal.
  Future<void> loadThemePreferences() async {
    try {
      final savedTheme = await LocalStorageService.loadData(StorageKeys.isDarkMode);
      if (savedTheme != null) _isDarkMode = savedTheme as bool;

      final savedAccent = await LocalStorageService.loadData(StorageKeys.themeAccentColor);
      if (savedAccent != null) _themeAccentColor = Color(savedAccent as int);
    } catch (e) {
      debugPrint('⚠️ Gagal memuat preferensi tema: $e');
    }
  }

  /// Beralih antara mode gelap dan terang.
  void toggleTheme(bool value) {
    _isDarkMode = value;
    syncToStorage();
    notifyListeners();
  }

  /// Mengganti warna aksen utama aplikasi.
  void updateThemeAccent(Color color) {
    _themeAccentColor = color;
    syncToStorage();
    notifyListeners();
  }
}
