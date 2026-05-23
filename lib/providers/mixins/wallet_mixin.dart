// lib/providers/mixins/wallet_mixin.dart
import 'package:flutter/foundation.dart';
import 'package:aplikasi_keuangan/models/wallet_model.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';

/// Mixin untuk mengelola dompet/sumber dana (hapus & arsip).
mixin WalletMixin on ChangeNotifier {
  List<WalletModel> get allWallets;
  set allWallets(List<WalletModel> val);
  List<TransactionModel> get allTransaksi;
  Future<void> syncToStorage();

  /// Menambahkan dompet baru.
  void addWallet(WalletModel wallet) {
    try {
      allWallets.add(wallet);
      syncToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Gagal menambahkan dompet: $e');
    }
  }

  /// Menghapus dompet berdasarkan ID secara permanen.
  void deleteWallet(String walletId) {
    try {
      final hasTransactions = allTransaksi.any((t) => t.walletId == walletId || t.targetWalletId == walletId);
      if (hasTransactions) {
        // Gabungan A & D: Jangan hapus permanen, ganti ke arsip
        toggleArchiveWallet(walletId);
        debugPrint('ℹ️ Dompet $walletId memiliki transaksi. Mengarsipkan dompet alih-alih menghapus permanen.');
      } else {
        // Hapus permanen karena kosong
        allWallets.removeWhere((w) => w.walletId == walletId);
        syncToStorage();
        notifyListeners();
        debugPrint('✅ Dompet $walletId dihapus permanen karena tidak ada riwayat transaksi.');
      }
    } catch (e) {
      debugPrint('⚠️ Gagal menghapus dompet: $e');
    }
  }

  /// Mengarsipkan atau mengaktifkan kembali dompet (toggle isActive).
  void toggleArchiveWallet(String walletId, [dynamic extra]) {
    try {
      final index = allWallets.indexWhere((w) => w.walletId == walletId);
      if (index != -1) {
        allWallets[index].isActive = !allWallets[index].isActive;
        syncToStorage();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Gagal mengarsipkan dompet: $e');
    }
  }
}
