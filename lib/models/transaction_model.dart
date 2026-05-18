// lib/models/transaction_model.dart
class TransactionModel {
  final String idTransaksi;
  final String jenis; // Pemasukan, Pengeluaran, Transfer
  final double nominal;
  final String idDana;
  final String? idDanaTujuan; // Buat Transfer (Bisa null)
  final String kategori;
  final String keterangan;
  final String tanggal; // ISO String (contoh: 2026-05-16T12:00:00Z)
  final String userId;

  TransactionModel({
    required this.idTransaksi,
    required this.jenis,
    required this.nominal,
    required this.idDana,
    this.idDanaTujuan,
    required this.kategori,
    required this.keterangan,
    required this.tanggal,
    required this.userId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      idTransaksi: json['id_transaksi'] ?? '',
      jenis: json['jenis'] ?? 'Pengeluaran',
      nominal: (json['nominal'] ?? 0).toDouble(),
      idDana: json['id_dana'] ?? '',
      idDanaTujuan: json['id_dana_tujuan'], // Bisa null
      kategori: json['kategori'] ?? 'Lain-lain',
      keterangan: json['keterangan'] ?? '',
      tanggal: json['tanggal'] ?? DateTime.now().toIso8601String(),
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_transaksi': idTransaksi,
      'jenis': jenis,
      'nominal': nominal,
      'id_dana': idDana,
      'id_dana_tujuan': idDanaTujuan,
      'kategori': kategori,
      'keterangan': keterangan,
      'tanggal': tanggal,
      'userId': userId,
    };
  }
}