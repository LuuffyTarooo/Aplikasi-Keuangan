// lib/core/utils/formatters.dart
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:aplikasi_keuangan/models/currency_model.dart';

class Formatters {
  // ==========================================
  // 1. DATA KONSTANTA & STATE
  // ==========================================
  static CurrencyModel activeCurrency = CurrencyModel(name: 'Indonesian Rupiah', code: 'IDR', symbol: 'Rp', exchangeRateToIdr: 1.0);

  static const List<String> monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  // ==========================================
  // 2. FUNGSI FORMAT UANG
  // ==========================================
  
  static String formatCurrency(double number, {bool isHidden = false}) {
    if (isHidden) return '${activeCurrency.symbol} ••••••••';
    if (number.isNaN || number.isInfinite) return '${activeCurrency.symbol} 0';

    double convertedNumber = number / activeCurrency.exchangeRateToIdr;
    String locale = activeCurrency.code == 'USD' ? 'en_US' : activeCurrency.code == 'EUR' ? 'de_DE' : 'id_ID';
    int fractionDigits = activeCurrency.code == 'IDR' ? 0 : 2;

    final formatter = NumberFormat.currency(
      locale: locale,
      name: activeCurrency.code,
      symbol: '${activeCurrency.symbol} ',
      decimalDigits: fractionDigits,
    );
    
    return formatter.format(convertedNumber);
  }

  static String formatUangCompact(double num) {
    if (num.isNaN || num.isInfinite) return '0';
    double converted = num / activeCurrency.exchangeRateToIdr;
    String locale = activeCurrency.code == 'USD' ? 'en_US' : activeCurrency.code == 'EUR' ? 'de_DE' : 'id_ID';

    final formatter = NumberFormat.compactCurrency(
      locale: locale,
      name: activeCurrency.code,
      symbol: '${activeCurrency.symbol} ',
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

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Keep only numbers
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    int value = int.parse(newText);
    String formatted = NumberFormat('#,###', 'id_ID').format(value);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}