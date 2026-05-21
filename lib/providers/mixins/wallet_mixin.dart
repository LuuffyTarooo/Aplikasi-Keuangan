// lib/providers/mixins/wallet_mixin.dart
import 'package:flutter/foundation.dart';
import 'package:aplikasi_keuangan/models/wallet_model.dart';

/// Mixin untuk mengelola dompet/sumber dana (hapus & arsip).
mixin WalletMixin on ChangeNotifier {
  List<WalletModel> get allSumberDana;
  set allSumberDana(List<WalletModel> val);
  void syncToStorage();

  /// Menghapus dompet berdasarkan ID secara permanen.
  void deleteSumberDana(String idDana) {
    try {
      allSumberDana.removeWhere((w) => w.idDana == idDana);
      syncToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Gagal menghapus dompet: $e');
    }
  }

  /// Mengarsipkan atau mengaktifkan kembali dompet (toggle isActive).
  void toggleArsipSumberDana(String idDana, [dynamic extra]) {
    try {
      final index = allSumberDana.indexWhere((w) => w.idDana == idDana);
      if (index != -1) {
        allSumberDana[index].isActive = !allSumberDana[index].isActive;
        syncToStorage();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Gagal mengarsipkan dompet: $e');
    }
  }
}
