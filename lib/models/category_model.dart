// lib/models/category_model.dart
class CategoryModel {
  final String id;
  final String name;
  final String jenis; // Pemasukan / Pengeluaran
  final String userId;

  CategoryModel({
    required this.id,
    required this.name,
    required this.jenis,
    required this.userId,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      jenis: json['jenis'] ?? 'Pengeluaran',
      userId: json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'jenis': jenis,
      'userId': userId,
    };
  }
}