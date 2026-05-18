// lib/models/wallet_model.dart
class WalletModel {
  final String idDana;
  final String namaAset;
  final double saldoAwal;
  final double saldoTerkini;
  final String userId;
  bool isActive; // 🟢 Tambahan baru: sengaja nggak pakai 'final' biar bisa diarsip/diubah

  WalletModel({
    required this.idDana,
    required this.namaAset,
    required this.saldoAwal,
    required this.saldoTerkini,
    required this.userId,
    this.isActive = true, // 🟢 Default-nya dompet selalu aktif pas baru dibikin
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      idDana: json['id_dana'] ?? '',
      namaAset: json['nama_aset'] ?? 'Dompet',
      // Karena JSON bisa nyimpen angka sbg int atau double, pake .toDouble()
      saldoAwal: (json['saldo_awal'] ?? 0).toDouble(),
      saldoTerkini: (json['saldo_terkini'] ?? 0).toDouble(),
      userId: json['userId'] ?? '',
      isActive: json['is_active'] ?? true, // 🟢 Ambil data arsip dari JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_dana': idDana,
      'nama_aset': namaAset,
      'saldo_awal': saldoAwal,
      'saldo_terkini': saldoTerkini,
      'userId': userId,
      'is_active': isActive, // 🟢 Simpan status arsip ke JSON
    };
  }
}