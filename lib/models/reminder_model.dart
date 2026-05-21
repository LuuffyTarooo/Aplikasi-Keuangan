// lib/models/reminder_model.dart
class ReminderModel {
  final String id;
  final String title;
  final String kategori;
  final String dueDate;
  final double nominal;
  bool isDone;
  final String userId;
  String? lastNotifiedPhase;

  ReminderModel({
    required this.id, required this.title, required this.kategori,
    required this.dueDate, required this.nominal, this.isDone = false,
    required this.userId, this.lastNotifiedPhase,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) => ReminderModel(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    kategori: json['kategori'] ?? '',
    dueDate: json['dueDate'] ?? '',
    nominal: (json['nominal'] as num?)?.toDouble() ?? 0.0,
    isDone: json['isDone'] ?? false,
    userId: json['userId'] ?? '',
    lastNotifiedPhase: json['lastNotifiedPhase'],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'title': title, 'kategori': kategori, 'dueDate': dueDate,
    'nominal': nominal, 'isDone': isDone, 'userId': userId,
    'lastNotifiedPhase': lastNotifiedPhase,
  };
}