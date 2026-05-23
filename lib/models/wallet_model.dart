// lib/models/wallet_model.dart
class WalletModel {
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0.0;
    return 0.0;
  }

  final String walletId;
  final String _namaAset;
  final double initialBalance;
  final double currentBalance;
  final String userId;
  bool isActive; // 🟢 Tambahan baru: sengaja nggak pakai 'final' biar bisa diarsip/diubah

  WalletModel({
    required this.walletId,
    required String walletName,
    required this.initialBalance,
    required this.currentBalance,
    required this.userId,
    this.isActive = true, // 🟢 Default-nya dompet selalu aktif pas baru dibikin
  }) : _namaAset = walletName;

  String get walletName => _namaAset;

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      walletId: json['id_dana'] ?? '',
      walletName: json['nama_aset'] ?? 'Dompet',
      // Karena JSON bisa nyimpen angka sbg int atau double, pake .toDouble()
      initialBalance: _parseDouble(json['saldo_awal']),
      currentBalance: _parseDouble(json['saldo_terkini']),
      userId: json['userId'] ?? '',
      isActive: json['is_active'] ?? true, // 🟢 Ambil data arsip dari JSON
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_dana': walletId,
      'nama_aset': walletName,
      'saldo_awal': initialBalance,
      'saldo_terkini': currentBalance,
      'userId': userId,
      'is_active': isActive, // 🟢 Simpan status arsip ke JSON
    };
  }
}