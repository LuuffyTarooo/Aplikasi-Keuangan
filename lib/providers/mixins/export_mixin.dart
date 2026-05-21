// lib/providers/mixins/export_mixin.dart
//
// ⚠️ DISABLED: Mixin ini membutuhkan package berikut di pubspec.yaml:
//   - pdf
//   - path_provider
//   - share_plus
//
// Aktifkan kembali setelah menjalankan:
//   flutter pub add pdf path_provider share_plus
//
// Lalu uncomment seluruh isi file ini dan tambahkan ExportMixin
// ke daftar `with` di FinanceProvider.

// import 'dart:io';
// import 'package:flutter/foundation.dart';
// import 'package:pdf/pdf.dart';
// import 'package:pdf/widgets.dart' as pw;
// import 'package:path_provider/path_provider.dart';
// import 'package:share_plus/share_plus.dart';
//
// import 'package:aplikasi_keuangan/core/constants/app_constants.dart';
// import 'package:aplikasi_keuangan/models/transaction_model.dart';
// import 'package:aplikasi_keuangan/models/wallet_model.dart';
//
// mixin ExportMixin on ChangeNotifier {
//   List<TransactionModel> get myTransaksi;
//   List<WalletModel> get mySumberDana;
//
//   Future<void> exportData({
//     required String format,
//     required String period,
//     required String type,
//     required String category,
//     required String walletId,
//   }) async {
//     // ... full implementation preserved ...
//   }
// }
