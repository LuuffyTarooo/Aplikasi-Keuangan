// lib/models/transaction_model.dart
class TransactionModel {
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0.0;
    return 0.0;
  }

  final String idTransaksi;
  final String jenis; // Pemasukan, Pengeluaran, Transfer
  final double nominal;
  final String walletId;
  final String? targetWalletId; // Buat Transfer (Bisa null)
  final String kategori;
  final String keterangan;
  final String tanggal; // ISO String (contoh: 2026-05-16T12:00:00Z)
  final String userId;

  TransactionModel({
    required this.idTransaksi,
    required this.jenis,
    required this.nominal,
    required this.walletId,
    this.targetWalletId,
    required this.kategori,
    required this.keterangan,
    required this.tanggal,
    required this.userId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      idTransaksi: json['id_transaksi'] ?? '',
      jenis: json['jenis'] ?? 'Pengeluaran',
      nominal: _parseDouble(json['nominal']),
      walletId: json['id_dana'] ?? '',
      targetWalletId: json['id_dana_tujuan'], // Bisa null
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
      'id_dana': walletId,
      'id_dana_tujuan': targetWalletId,
      'kategori': kategori,
      'keterangan': keterangan,
      'tanggal': tanggal,
      'userId': userId,
    };
  }
}