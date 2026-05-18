// lib/models/debt_model.dart
class DebtModel {
  final String id;
  final String name;
  final String type; // 'PIUTANG' | 'HUTANG'
  final double amount;
  double paid;
  bool isCompleted;
  final String catatan;
  List<String> txDates;
  final String userId; // 🟢 Mengunci data biar gak tertukar antar akun

  DebtModel({
    required this.id, 
    required this.name, 
    required this.type, 
    required this.amount,
    this.paid = 0, 
    this.isCompleted = false, 
    this.catatan = '', 
    this.txDates = const [], 
    required this.userId,
  });

  factory DebtModel.fromJson(Map<String, dynamic> json) => DebtModel(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    type: json['type'] ?? 'HUTANG',
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    paid: (json['paid'] as num?)?.toDouble() ?? 0.0,
    isCompleted: json['isCompleted'] ?? false,
    catatan: json['catatan'] ?? '',
    txDates: List<String>.from(json['txDates'] ?? []),
    userId: json['userId'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id, 
    'name': name, 
    'type': type, 
    'amount': amount,
    'paid': paid, 
    'isCompleted': isCompleted, 
    'catatan': catatan,
    'txDates': txDates, 
    'userId': userId,
  };
}