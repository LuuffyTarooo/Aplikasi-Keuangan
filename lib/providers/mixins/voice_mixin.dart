// lib/providers/mixins/voice_mixin.dart
import 'package:flutter/foundation.dart';
import 'package:aplikasi_keuangan/core/constants/app_constants.dart';
import 'package:aplikasi_keuangan/models/category_model.dart';
import 'package:aplikasi_keuangan/models/wallet_model.dart';

mixin VoiceMixin on ChangeNotifier {
  List<CategoryModel> get myKategori;
  List<WalletModel> get mySumberDana;

  /// Mem-parsing raw text dari Voice Assistant untuk mendeteksi Tipe, Nominal, Kategori, dan Dompet.
  /// Fungsi ini asinkron walau cepat agar tidak memblokir main thread di perangkat mobile.
  Future<Map<String, dynamic>> parseVoiceIntent(String rawText) async {
    String lowerText = rawText.toLowerCase();

    // 1. Deteksi Tipe Transaksi
    String jenis = TransactionTypes.expense;
    if (lowerText.contains('transfer') || lowerText.contains('kirim') || lowerText.contains('pindah')) {
      jenis = TransactionTypes.transfer;
    } else if (lowerText.contains('pemasukan') || lowerText.contains('dapat') || lowerText.contains('gaji') || lowerText.contains('terima')) {
      jenis = TransactionTypes.income;
    }

    // 2. Deteksi Nominal
    double nominal = 0;
    RegExp regExp = RegExp(r'\d+');
    Iterable<RegExpMatch> matches = regExp.allMatches(lowerText.replaceAll('.', ''));
    
    if (matches.isNotEmpty) {
      String numStr = matches.map((m) => m.group(0)).join('');
      double parsedNum = double.tryParse(numStr) ?? 0;
      if (lowerText.contains('ribu') && parsedNum < 1000) parsedNum *= 1000;
      if (lowerText.contains('juta') && parsedNum < 1000) parsedNum *= 1000000;
      nominal = parsedNum;
    } else {
      if (lowerText.contains('gocap')) {
        nominal = 50000;
      } else if (lowerText.contains('cepek')) {
        nominal = 100000;
      } else if (lowerText.contains('goceng')) {
        nominal = 5000;
      } else if (lowerText.contains('ceng')) {
        nominal = 1000;
      }
    }

    if (nominal <= 0) {
      throw Exception("Nominal uangnya nggak kedengeran. Coba ulangi dengan jelas nominalnya.");
    }

    // 3. Deteksi Kategori
    String kategoriId = 'Lain-lain';
    if (jenis != TransactionTypes.transfer) {
      Map<String, List<String>> synMap = {
        'Makan & Minuman': ['makan', 'kopi', 'jajan', 'nasi', 'minum', 'bakso', 'sate', 'gofood', 'grabfood', 'kafe', 'indomie', 'starbucks', 'mcd'],
        'Transportasi': ['bensin', 'parkir', 'ojek', 'grab', 'gojek', 'kereta', 'tol', 'angkot', 'bus'],
        'Belanja': ['beli', 'indomaret', 'alfamart', 'belanja', 'shopee', 'tokopedia', 'supermarket', 'rokok'],
        'Tagihan': ['listrik', 'air', 'wifi', 'internet', 'token', 'pajak', 'kos', 'kosan'],
        'Hiburan': ['nonton', 'bioskop', 'netflix', 'game', 'spotify', 'main'],
        'Gaji': ['gaji', 'upah', 'bayaran', 'honor'],
        'Bonus': ['bonus', 'hadiah', 'thr'],
      };

      bool categoryFound = false;
      for (var kat in myKategori) {
        if (kat.jenis == jenis && lowerText.contains(kat.name.toLowerCase())) {
          kategoriId = kat.name;
          categoryFound = true;
          break;
        }
      }

      if (!categoryFound) {
        for (var entry in synMap.entries) {
          if (entry.value.any((s) => lowerText.contains(s))) {
            var found = myKategori.where((k) => k.jenis == jenis && k.name.toLowerCase().contains(entry.key.toLowerCase())).toList();
            kategoriId = found.isNotEmpty ? found.first.name : entry.key;
            break;
          }
        }
      }
    }

    // 4. Deteksi Dompet (Asal & Tujuan)
    if (mySumberDana.isEmpty) {
      throw Exception("Lu belum punya dompet sama sekali Jar! Bikin dompet dulu.");
    }

    Map<String, List<String>> walletSyns = {
      'Tunai': ['tunai', 'cash', 'uang pas', 'dompet', 'uang'],
      'BCA': ['bca', 'm-bca', 'mbca'],
      'GoPay': ['gopay', 'go-pay'],
      'OVO': ['ovo', 'ofo'],
      'Dana': ['dana', 'aplikasi dana']
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
          var found = mySumberDana.where((d) => d.namaAset.toLowerCase().contains(entry.key.toLowerCase())).toList();
          if (found.isNotEmpty) return found.first.idDana;
        }
      }
      return '';
    }

    if (jenis == TransactionTypes.transfer) {
      // Pola transfer ideal: "...dari [dompet A] ke [dompet B]"
      int indexDari = lowerText.indexOf('dari');
      int indexKe = lowerText.indexOf('ke ');
      
      if (indexDari != -1 && indexKe != -1 && indexDari < indexKe) {
        String bagianAsal = lowerText.substring(indexDari + 4, indexKe);
        String bagianTujuan = lowerText.substring(indexKe + 3);
        detectedDompetAsal = cariDompet(bagianAsal);
        detectedDompetTujuan = cariDompet(bagianTujuan);
      } else if (indexKe != -1) {
        String bagianTujuan = lowerText.substring(indexKe + 3);
        detectedDompetTujuan = cariDompet(bagianTujuan);
        // Coba cari dompet asal dari sisa string (atau default ke dompet pertama kalau nggak ketemu)
        String sisaText = lowerText.substring(0, indexKe);
        detectedDompetAsal = cariDompet(sisaText);
      }

      if (detectedDompetAsal.isEmpty) detectedDompetAsal = mySumberDana.first.idDana;
      if (detectedDompetTujuan.isEmpty) {
        throw Exception("Dompet tujuannya nggak jelas Jar. Bilang 'Transfer ke BCA' misalnya.");
      }
      if (detectedDompetAsal == detectedDompetTujuan) {
        throw Exception("Masa transfer ke dompet yang sama? Tolong cek lagi dompet tujuannya.");
      }
    } else {
      // Pengeluaran / Pemasukan biasa
      detectedDompetAsal = cariDompet(lowerText);
      if (detectedDompetAsal.isEmpty) detectedDompetAsal = mySumberDana.first.idDana;
    }

    // 5. Validasi Saldo (Khusus Pengeluaran & Transfer)
    var dompetAsalObj = mySumberDana.firstWhere((d) => d.idDana == detectedDompetAsal);
    if ((jenis == TransactionTypes.expense || jenis == TransactionTypes.transfer) && dompetAsalObj.saldoTerkini < nominal) {
      throw Exception("Saldo ${dompetAsalObj.namaAset} lu nggak cukup buat transaksi ini.");
    }

    var dompetTujuanObj = (jenis == TransactionTypes.transfer) 
        ? mySumberDana.firstWhere((d) => d.idDana == detectedDompetTujuan, orElse: () => mySumberDana.first) 
        : null;

    String capitalizedText = rawText.isNotEmpty ? rawText[0].toUpperCase() + rawText.substring(1) : 'Transaksi Suara';
    
    // Susun pesan konfirmasi TTS
    String ttsMessage;
    if (jenis == TransactionTypes.transfer) {
      ttsMessage = "Konfirmasi transfer ${nominal.toStringAsFixed(0)} rupiah, dari ${dompetAsalObj.namaAset} ke ${dompetTujuanObj!.namaAset}?";
    } else if (jenis == TransactionTypes.expense) {
      ttsMessage = "Konfirmasi pengeluaran ${nominal.toStringAsFixed(0)} rupiah, pakai ${dompetAsalObj.namaAset}?";
    } else {
      ttsMessage = "Konfirmasi pemasukan ${nominal.toStringAsFixed(0)} rupiah, masuk ke ${dompetAsalObj.namaAset}?";
    }

    return {
      'nominal': nominal,
      'kategori': kategoriId,
      'id_dana': dompetAsalObj.idDana,
      'id_dana_tujuan': dompetTujuanObj?.idDana, // Bisa null jika bukan transfer
      'nama_dompet': dompetAsalObj.namaAset,
      'nama_dompet_tujuan': dompetTujuanObj?.namaAset,
      'keterangan': capitalizedText,
      'jenis': jenis,
      'tanggal': DateTime.now().toIso8601String(),
      'tts_message': ttsMessage,
    };
  }
}
