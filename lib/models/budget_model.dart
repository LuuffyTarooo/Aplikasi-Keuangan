// lib/models/budget_model.dart
class BudgetModel {
  final String userId;
  final double limitBulanan;
  final Map<String, double> categoryLimits; 

  BudgetModel({
    required this.userId,
    required this.limitBulanan,
    required this.categoryLimits,
  });

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    // Ubah data JSON yang berbentuk { "Makanan": 50000 } jadi Map di Dart
    Map<String, double> parsedLimits = {};
    if (json['category_limits'] != null) {
      json['category_limits'].forEach((key, value) {
        parsedLimits[key] = (value as num).toDouble();
      });
    }

    return BudgetModel(
      userId: json['userId'] ?? '',
      limitBulanan: (json['limit_bulanan'] ?? 0).toDouble(),
      categoryLimits: parsedLimits,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'limit_bulanan': limitBulanan,
      'category_limits': categoryLimits,
    };
  }
}