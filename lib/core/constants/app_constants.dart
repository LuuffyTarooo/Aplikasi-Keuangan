// lib/core/constants/app_constants.dart
import 'package:flutter/material.dart';

/// Tempat menyimpan semua daftar baku agar tidak hardcoded di file UI.
/// Biar kalau ada perubahan label atau key database, cukup ganti di sini.

class StorageKeys {
  StorageKeys._();

  static const String transactions = 'all_transaksi';
  static const String wallets = 'all_sumberDana';
  static const String debts = 'all_debts';
  static const String savings = 'all_savings';
  static const String reminders = 'all_reminders';
  static const String budgets = 'all_budgets';
  static const String shortcuts = 'app_shortcuts';
  static const String settings = 'app_settings';
  static const String users = 'duit_users';
  static const String categories = 'all_kategori';

  // Key untuk PIN & Security
  static const String userPin = 'user_pin';
  static const String pinLockoutUntil = 'pin_lockout_until';

  // Key untuk Theme
  static const String isDarkMode = 'is_dark_mode';
  static const String themeAccentColor = 'theme_accent_color';
}

class TransactionTypes {
  TransactionTypes._();

  static const String expense = 'Pengeluaran';
  static const String income = 'Pemasukan';
  static const String transfer = 'Transfer';
}

class ExportConstants {
  ExportConstants._();

  static const String formatExcel = 'Excel (CSV)';
  static const String formatPdf = 'PDF';
  static const String periodAll = 'Semua';
  static const String periodThisMonth = 'Bulan Ini';
  static const String filterAll = 'Semua';
}

class AppColors {
  AppColors._();

  static const Color primary = Colors.orange;
  static const Color success = Colors.green;
  static const Color danger = Colors.pinkAccent;
  static const Color warning = Colors.amber;
  static const Color info = Colors.blue;

  static const List<Color> shortcutColors = [
    Colors.orange,
    Colors.pinkAccent,
    Colors.blue,
    Colors.amber,
    Colors.green,
    Color(0xFFA855F7),
  ];
}