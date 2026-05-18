// lib/core/constants/app_constants.dart
import 'package:flutter/material.dart';

/// * APP CONSTANTS
/// * Tempat menyimpan semua daftar baku agar tidak hardcoded di file UI.
/// * Biar kalau ada perubahan label atau key database, cukup ganti di sini Jar!

class StorageKeys {
  StorageKeys._(); // Private constructor biar nggak bisa di-instantiate

  static const String transactions = 'all_transaksi';
  static const String wallets = 'all_sumberDana';
  static const String debts = 'app_debts';
  static const String savings = 'all_savings';
  static const String reminders = 'all_reminders';
  static const String budgets = 'all_budgets';
  static const String shortcuts = 'app_shortcuts';
  static const String settings = 'app_settings';
  
  // Tambahan dari provider lu kemarin
  static const String users = 'duit_users'; 
  static const String categories = 'all_kategori';
}

class TransactionTypes {
  TransactionTypes._();

  static const String expense = 'Pengeluaran';
  static const String income = 'Pemasukan';
  static const String transfer = 'Transfer';
}

class AppColors {
  AppColors._();

  // THEME COLORS (Konversi dari Tailwind yang lu pake)
  static const Color primary = Colors.orange;       // orange-500
  static const Color success = Colors.green;        // pengganti emerald-500
  static const Color danger = Colors.pinkAccent;    // pengganti rose-500
  static const Color warning = Colors.amber;        // amber-500
  static const Color info = Colors.blue;            // blue-500

  // SHORTCUT COLORS
  static const List<Color> shortcutColors = [
    Colors.orange,
    Colors.pinkAccent,
    Colors.blue,
    Colors.amber,
    Colors.green,
    Color(0xFFA855F7), // Neon Purple (ciri khas Duit Tracker lu)
  ];
}