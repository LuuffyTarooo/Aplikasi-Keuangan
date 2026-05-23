// lib/providers/mixins/debt_mixin.dart
import 'package:flutter/foundation.dart';
import 'package:aplikasi_keuangan/models/debt_model.dart';

/// Mixin untuk mengelola fitur hutang/piutang.
mixin DebtMixin on ChangeNotifier {
  List<DebtModel> get allDebts;
  set allDebts(List<DebtModel> val);
  Future<void> syncToStorage();

  /// Menambahkan hutang/piutang baru ke daftar.
  void addDebt(DebtModel debt) {
    try {
      allDebts.insert(0, debt);
      syncToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Gagal menambah hutang: $e');
    }
  }

  /// Mencatat pembayaran hutang. Otomatis menandai selesai jika lunas.
  void payDebt(String id, double amount, String date) {
    try {
      final index = allDebts.indexWhere((d) => d.id == id);
      if (index != -1) {
        allDebts[index].paid += amount;
        if (allDebts[index].paid >= allDebts[index].amount) {
          allDebts[index].isCompleted = true;
        }
        allDebts[index].txDates.add(date);
        syncToStorage();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Gagal mencatat pembayaran hutang: $e');
    }
  }

  /// Menghapus hutang/piutang berdasarkan ID.
  void deleteDebt(String id) {
    try {
      allDebts.removeWhere((d) => d.id == id);
      syncToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Gagal menghapus hutang: $e');
    }
  }
}
