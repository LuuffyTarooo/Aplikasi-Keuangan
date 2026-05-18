// lib/models/saving_model.dart
class SavingGoalModel {
  final String id;
  final String name;
  final double target;
  double current;
  bool isCompleted;
  final String userId;

  SavingGoalModel({
    required this.id,
    required this.name,
    required this.target,
    this.current = 0,
    this.isCompleted = false,
    required this.userId,
  });

  factory SavingGoalModel.fromJson(Map<String, dynamic> json) => SavingGoalModel(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    target: (json['target'] as num?)?.toDouble() ?? 0.0,
    current: (json['current'] as num?)?.toDouble() ?? 0.0,
    isCompleted: json['isCompleted'] ?? false,
    userId: json['userId'] ?? '',
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'target': target,
    'current': current,
    'isCompleted': isCompleted,
    'userId': userId,
  };
}