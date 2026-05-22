// lib/providers/mixins/voice_mixin.dart
import 'package:flutter/foundation.dart';
import 'package:aplikasi_keuangan/core/constants/app_constants.dart';
import 'package:aplikasi_keuangan/models/category_model.dart';
import 'package:aplikasi_keuangan/models/wallet_model.dart';
import 'package:aplikasi_keuangan/services/voice_parser_service.dart';

mixin VoiceMixin on ChangeNotifier {
  List<CategoryModel> get myKategori;
  List<WalletModel> get mySumberDana;

  /// Mem-parsing raw text dari Voice Assistant untuk mendeteksi Tipe, Nominal, Kategori, dan Dompet.
  /// Fungsi ini asinkron walau cepat agar tidak memblokir main thread di perangkat mobile.
  Future<Map<String, dynamic>> parseVoiceIntent(String rawText) async {
    String lowerText = rawText.toLowerCase();

    // 1. Deteksi Nominal via VoiceParserService
    double nominal = VoiceParserService.extractAmount(rawText) ?? 0;
    if (nominal <= 0) {
      throw Exception(
        "Nominal uangnya nggak kedengeran. Coba ulangi dengan jelas nominalnya.",
      );
    }

    // 2. Deteksi Tipe Transaksi
    String jenis = TransactionTypes.expense;
    if (lowerText.contains('transfer') ||
        lowerText.contains('kirim') ||
        lowerText.contains('pindah')) {
      jenis = TransactionTypes.transfer;
    } else if (lowerText.contains('pemasukan') ||
        lowerText.contains('dapat') ||
        lowerText.contains('gaji') ||
        lowerText.contains('terima')) {
      jenis = TransactionTypes.income;
    }

    // 3. Deteksi Kategori via Smart VoiceParserService
    String kategoriId = 'Lain-lain';
    if (jenis != TransactionTypes.transfer) {
      String smartCategory = VoiceParserService.detectCategory(rawText);
      bool categoryFound = false;
      for (var kat in myKategori) {
        if (kat.jenis == jenis &&
            kat.name.toLowerCase() == smartCategory.toLowerCase()) {
          kategoriId = kat.name;
          categoryFound = true;
          break;
        }
      }

      // Jika tidak ada di daftar user, gunakan hasil cerdas langsung
      if (!categoryFound) {
        kategoriId = smartCategory;
      }
    }

    // 4. Deteksi Dompet (Asal & Tujuan)
    if (mySumberDana.isEmpty) {
      throw Exception(
        "Lu belum punya dompet sama sekali Jar! Bikin dompet dulu.",
      );
    }

    Map<String, List<String>> walletSyns = {
      'Tunai': ['tunai', 'cash', 'uang pas', 'dompet', 'uang'],
      'BCA': ['bca', 'm-bca', 'mbca'],
      'GoPay': ['gopay', 'go-pay'],
      'OVO': ['ovo', 'ofo'],
      'Dana': ['dana', 'aplikasi dana'],
    };

    String detectedDompetAsal = '';
    String detectedDompetTujuan = '';

    // Helper untuk mendeteksi dompet dari sebagian teks
    String cariDompet(String textSlice) {
      for (var dana in mySumberDana) {
        if (textSlice.contains(dana.namaAset.toLowerCase())) return dana.idDana;
      }
      for (var entry in walletSyns.entries) {
        if (entry.value.any((s) => textSlice.contains(s))) {
          var found = mySumberDana
              .where(
                (d) =>
                    d.namaAset.toLowerCase().contains(entry.key.toLowerCase()),
              )
              .toList();
          if (found.isNotEmpty) return found.first.idDana;
        }
      }
      return '';
    }

    if (jenis == TransactionTypes.transfer) {
      // Pola transfer ideal: "...dari [dompet A] ke [dompet B]"
      int indexDari = lowerText.indexOf('dari ');
      int indexKe = lowerText.indexOf('ke ');

      if (indexDari != -1 && indexKe != -1 && indexDari < indexKe) {
        String bagianAsal = lowerText.substring(indexDari + 5, indexKe);
        String bagianTujuan = lowerText.substring(indexKe + 3);
        detectedDompetAsal = cariDompet(bagianAsal);
        if (detectedDompetAsal.isEmpty) {
          String nAsal = bagianAsal.trim().split(' ').first;
          if (nAsal.isNotEmpty)
            throw Exception("dompet $nAsal belum dibuat nih.");
        }
        detectedDompetTujuan = cariDompet(bagianTujuan);
        if (detectedDompetTujuan.isEmpty) {
          String nTujuan = bagianTujuan.trim().split(' ').first;
          if (nTujuan.isNotEmpty)
            throw Exception("dompet $nTujuan belum dibuat nih.");
        }
      } else if (indexKe != -1) {
        String bagianTujuan = lowerText.substring(indexKe + 3);
        detectedDompetTujuan = cariDompet(bagianTujuan);
        if (detectedDompetTujuan.isEmpty) {
          String nTujuan = bagianTujuan.trim().split(' ').first;
          if (nTujuan.isNotEmpty)
            throw Exception("dompet $nTujuan belum dibuat nih.");
        }
        // Coba cari dompet asal dari sisa string (atau default ke dompet pertama kalau nggak ketemu)
        String sisaText = lowerText.substring(0, indexKe);
        detectedDompetAsal = cariDompet(sisaText);
      }

      if (detectedDompetAsal.isEmpty)
        detectedDompetAsal = mySumberDana.first.idDana;
      if (detectedDompetTujuan.isEmpty) {
        throw Exception(
          "Dompet tujuannya nggak jelas Jar. Bilang 'Transfer ke BCA' misalnya.",
        );
      }
      if (detectedDompetAsal == detectedDompetTujuan) {
        throw Exception(
          "Masa transfer ke dompet yang sama? Tolong cek lagi dompet tujuannya.",
        );
      }
    } else {
      // Pengeluaran / Pemasukan biasa
      detectedDompetAsal = cariDompet(lowerText);
      if (detectedDompetAsal.isEmpty) {
        int idxPakai = lowerText.indexOf('pakai ');
        int idxVia = lowerText.indexOf('via ');
        String? dompetGagal;
        if (idxPakai != -1) {
          dompetGagal = lowerText
              .substring(idxPakai + 6)
              .trim()
              .split(' ')
              .first;
        } else if (idxVia != -1)
          dompetGagal = lowerText.substring(idxVia + 4).trim().split(' ').first;

        if (dompetGagal != null &&
            dompetGagal.isNotEmpty &&
            dompetGagal.length >= 2) {
          throw Exception("dompet $dompetGagal belum dibuat nih.");
        }
        detectedDompetAsal = mySumberDana.first.idDana;
      }
    }

    // 5. Validasi Saldo (Khusus Pengeluaran & Transfer)
    var dompetAsalObj = mySumberDana.firstWhere(
      (d) => d.idDana == detectedDompetAsal,
    );
    if ((jenis == TransactionTypes.expense ||
            jenis == TransactionTypes.transfer) &&
        dompetAsalObj.saldoTerkini < nominal) {
      throw Exception(
        "Saldo ${dompetAsalObj.namaAset} lu nggak cukup buat transaksi ini.",
      );
    }

    var dompetTujuanObj = (jenis == TransactionTypes.transfer)
        ? mySumberDana.firstWhere(
            (d) => d.idDana == detectedDompetTujuan,
            orElse: () => mySumberDana.first,
          )
        : null;

    String capitalizedText = rawText.isNotEmpty
        ? rawText[0].toUpperCase() + rawText.substring(1)
        : 'Transaksi Suara';

    // Susun pesan konfirmasi TTS
    String ttsMessage;
    if (jenis == TransactionTypes.transfer) {
      ttsMessage =
          "Konfirmasi transfer ${nominal.toStringAsFixed(0)} rupiah, dari ${dompetAsalObj.namaAset} ke ${dompetTujuanObj!.namaAset}?";
    } else if (jenis == TransactionTypes.expense) {
      ttsMessage =
          "Konfirmasi pengeluaran ${nominal.toStringAsFixed(0)} rupiah, pakai ${dompetAsalObj.namaAset}?";
    } else {
      ttsMessage =
          "Konfirmasi pemasukan ${nominal.toStringAsFixed(0)} rupiah, masuk ke ${dompetAsalObj.namaAset}?";
    }

    return {
      'nominal': nominal,
      'kategori': kategoriId,
      'id_dana': dompetAsalObj.idDana,
      'id_dana_tujuan':
          dompetTujuanObj?.idDana, // Bisa null jika bukan transfer
      'nama_dompet': dompetAsalObj.namaAset,
      'nama_dompet_tujuan': dompetTujuanObj?.namaAset,
      'keterangan': capitalizedText,
      'jenis': jenis,
      'tanggal': DateTime.now().toIso8601String(),
      'tts_message': ttsMessage,
    };
  }
}
