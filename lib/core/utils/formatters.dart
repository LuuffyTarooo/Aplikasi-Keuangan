// lib/core/utils/formatters.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Formatters {
  // ==========================================
  // 1. DATA KONSTANTA & TEMA WARNA
  // ==========================================
  static const Map<String, double> kurs = {
    'IDR': 1.0,
    'USD': 16200.0,
    'EUR': 17500.0,
  };

  static const List<String> monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  // Palet Warna Neon untuk Grafik (Chart)
  static const List<Color> neonColors = [
    Color(0xFFA855F7), // Purple
    Color(0xFFD946EF), // Fuchsia
    Color(0xFF8B5CF6), // Violet
    Color(0xFFC084FC), // Light Purple
    Color(0xFFE879F9), // Light Fuchsia
    Color(0xFFA78BFA), // Light Violet
  ];

  // ==========================================
  // 2. FUNGSI FORMAT UANG
  // ==========================================
  
  static String formatCurrency(double number, {String currencyCode = 'IDR', bool isHidden = false}) {
    if (isHidden) return 'Rp ••••••••';
    if (number.isNaN || number.isInfinite) return 'Rp 0';

    double convertedNumber = number / (kurs[currencyCode] ?? 1.0);
    String locale = currencyCode == 'USD' ? 'en_US' : currencyCode == 'EUR' ? 'de_DE' : 'id_ID';
    int fractionDigits = currencyCode == 'IDR' ? 0 : 2;

    final formatter = NumberFormat.currency(
      locale: locale,
      name: currencyCode,
      symbol: currencyCode == 'IDR' ? 'Rp ' : (currencyCode == 'USD' ? '\$ ' : '€ '),
      decimalDigits: fractionDigits,
    );
    
    return formatter.format(convertedNumber);
  }

  static String formatUangCompact(double num, {String currencyCode = 'IDR'}) {
    if (num.isNaN || num.isInfinite) return '0';
    double converted = num / (kurs[currencyCode] ?? 1.0);
    String locale = currencyCode == 'USD' ? 'en_US' : currencyCode == 'EUR' ? 'de_DE' : 'id_ID';

    final formatter = NumberFormat.compactCurrency(
      locale: locale,
      name: currencyCode,
      symbol: currencyCode == 'IDR' ? 'Rp ' : (currencyCode == 'USD' ? '\$ ' : '€ '),
      decimalDigits: 1,
    );
    
    return formatter.format(converted);
  }

  static String formatRibuan(dynamic angkaStr) {
    if (angkaStr == null) return '';
    String value = angkaStr.toString().replaceAll(RegExp(r'\D'), '');
    if (value.isEmpty) return '';
    int parsed = int.parse(value);
    return NumberFormat('#,###', 'id_ID').format(parsed);
  }

  // ==========================================
  // 3. FUNGSI WAKTU & TANGGAL
  // ==========================================
  
  static int getDaysLeft(String dateString) {
    DateTime today = DateTime.now();
    today = DateTime(today.year, today.month, today.day); // Set ke jam 00:00:00
    
    DateTime due = DateTime.parse(dateString);
    due = DateTime(due.year, due.month, due.day);
    
    return due.difference(today).inDays;
  }
}