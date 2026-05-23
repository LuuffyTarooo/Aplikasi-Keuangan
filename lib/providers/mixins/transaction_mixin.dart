// lib/providers/mixins/transaction_mixin.dart
import 'package:flutter/foundation.dart';
import 'package:aplikasi_keuangan/core/constants/app_constants.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';
import 'package:aplikasi_keuangan/models/wallet_model.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:aplikasi_keuangan/models/user_model.dart';

/// Mixin untuk mengelola transaksi (CRUD) dan dampaknya terhadap saldo dompet.
mixin TransactionMixin on ChangeNotifier {
  // Diakses dari FinanceProvider
  List<TransactionModel> get allTransaksi;
  set allTransaksi(List<TransactionModel> val);
  List<WalletModel> get allWallets;
  set allWallets(List<WalletModel> val);
  UserModel? get currentUser;
  Future<void> syncToStorage();

  /// Menyimpan transaksi baru atau memperbarui yang sudah ada.
  /// Jika `idTransaksi` kosong → transaksi baru.
  /// Jika `idTransaksi` ada → revert saldo lama, hapus, lalu terapkan saldo baru.
  void handleSaveTransaksi(TransactionModel newTx) {
    final user = currentUser;
    if (user == null) return;

    TransactionModel finalTx = newTx;
    if (finalTx.idTransaksi.isEmpty) {
      // Transaksi baru: generate ID unik
      finalTx = TransactionModel(
        idTransaksi: 't_${DateTime.now().millisecondsSinceEpoch}',
        jenis: newTx.jenis, nominal: newTx.nominal,
        walletId: newTx.walletId, targetWalletId: newTx.targetWalletId,
        kategori: newTx.kategori, keterangan: newTx.keterangan,
        tanggal: newTx.tanggal, userId: user.id,
      );
      _applyBalanceImpact(finalTx, false);
      allTransaksi.insert(0, finalTx);
    } else {
      // Edit: revert saldo lama lalu terapkan saldo baru
      final existingIndex = allTransaksi.indexWhere((t) => t.idTransaksi == finalTx.idTransaksi);
      if (existingIndex != -1) {
        _applyBalanceImpact(allTransaksi[existingIndex], true);
        allTransaksi.removeAt(existingIndex);
      }
      _applyBalanceImpact(finalTx, false);
      allTransaksi.insert(0, finalTx);
    }

    allTransaksi.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    syncToStorage();
    notifyListeners();
  }

  /// Menghapus transaksi berdasarkan ID dan merevert dampak saldonya.
  void deleteTransaksi(String idTransaksi) {
    final index = allTransaksi.indexWhere((t) => t.idTransaksi == idTransaksi);
    if (index != -1) {
      _applyBalanceImpact(allTransaksi[index], true);
      allTransaksi.removeAt(index);
      syncToStorage();
      notifyListeners();
    }
  }

  /// Menghitung dampak transaksi terhadap saldo dompet.
  /// [isRevert] = true berarti membatalkan efek transaksi (saat edit/hapus).
  void _applyBalanceImpact(TransactionModel tx, bool isRevert) {
    final multiplier = isRevert ? -1 : 1;
    for (var i = 0; i < allWallets.length; i++) {
      final dana = allWallets[i];
      double newSaldo = dana.currentBalance;

      if (tx.walletId == dana.walletId) {
        if (tx.jenis == TransactionTypes.expense || tx.jenis == TransactionTypes.transfer) {
          newSaldo -= (tx.nominal * multiplier);
        } else if (tx.jenis == TransactionTypes.income) {
          newSaldo += (tx.nominal * multiplier);
        }
        allWallets[i] = WalletModel(
          walletId: dana.walletId, walletName: dana.walletName,
          initialBalance: dana.initialBalance, currentBalance: newSaldo,
          userId: dana.userId, isActive: dana.isActive,
        );
      }

      if (tx.jenis == TransactionTypes.transfer && tx.targetWalletId == dana.walletId) {
        newSaldo += (tx.nominal * multiplier);
        allWallets[i] = WalletModel(
          walletId: dana.walletId, walletName: dana.walletName,
          initialBalance: dana.initialBalance, currentBalance: newSaldo,
          userId: dana.userId, isActive: dana.isActive,
        );
      }
    }
  }
  /// Fitur EXPORT transaksi ke CSV
  Future<void> exportTransactionsCSV(List<TransactionModel> txs) async {
    try {
      List<List<dynamic>> rows = [];
      // Header CSV
      rows.add([
        "id_transaksi",
        "jenis",
        "nominal",
        "id_dana",
        "id_dana_tujuan",
        "kategori",
        "keterangan",
        "tanggal",
      ]);

      for (var tx in txs) {
        rows.add([
          tx.idTransaksi,
          tx.jenis,
          tx.nominal,
          tx.walletId,
          tx.targetWalletId ?? "",
          tx.kategori,
          tx.keterangan,
          tx.tanggal,
        ]);
      }

      String csvData = csv.encode(rows);
      
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/export_transaksi_${DateTime.now().millisecondsSinceEpoch}.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      // Share file yang sudah digenerate
      await Share.shareXFiles([XFile(path)], text: 'Export Transaksi Keuangan');
    } catch (e) {
      throw Exception("Gagal mengekspor file: $e");
    }
  }

  /// Fitur IMPORT transaksi dari CSV
  Future<int> importTransactionsCSV(String filePath) async {
    final user = currentUser;
    if (user == null) throw Exception("User belum login");

    try {
      final input = await File(filePath).readAsString();
      final fields = csv.decode(input);
      
      if (fields.isEmpty) throw Exception("File kosong");
      
      // Ambil Header
      final header = fields.first.map((e) => e.toString().toLowerCase().trim()).toList();
      
      // Validasi kolom wajib minimal
      if (!header.contains("nominal") || !header.contains("jenis") || !header.contains("tanggal")) {
        throw Exception("Format CSV tidak valid. Harus mengandung kolom: nominal, jenis, tanggal");
      }

      int countSuccess = 0;
      for (int i = 1; i < fields.length; i++) {
        final row = fields[i];
        if (row.length < header.length) continue;

        Map<String, dynamic> rowData = {};
        for (int j = 0; j < header.length; j++) {
          rowData[header[j]] = row[j];
        }

        try {
          double nominal = double.tryParse(rowData['nominal'].toString()) ?? 0.0;
          if (nominal <= 0) continue;

          String jenis = rowData['jenis'].toString().trim();
          if (jenis.isEmpty) jenis = TransactionTypes.expense;

          // Default dompet adalah dompet pertama jika tidak ketemu id_dana
          String walletId = rowData['id_dana']?.toString().trim() ?? '';
          if (walletId.isEmpty && allWallets.isNotEmpty) {
            walletId = allWallets.first.walletId;
          }

          String? targetWalletId = rowData['id_dana_tujuan']?.toString().trim();
          if (targetWalletId != null && targetWalletId.isEmpty) targetWalletId = null;

          String kategori = rowData['kategori']?.toString().trim() ?? 'Lain-lain';
          String keterangan = rowData['keterangan']?.toString().trim() ?? '';
          String tanggal = rowData['tanggal']?.toString().trim() ?? DateTime.now().toIso8601String();
          String idTransaksi = rowData['id_transaksi']?.toString().trim() ?? '';

          TransactionModel tx = TransactionModel(
            idTransaksi: idTransaksi,
            jenis: jenis,
            nominal: nominal,
            walletId: walletId,
            targetWalletId: targetWalletId,
            kategori: kategori,
            keterangan: keterangan,
            tanggal: tanggal,
            userId: user.id,
          );

          handleSaveTransaksi(tx);
          countSuccess++;
        } catch (e) {
          debugPrint("Skip baris ke-$i: $e");
        }
      }
      return countSuccess;
    } catch (e) {
      throw Exception("Gagal mengimpor file: $e");
    }
  }
}
