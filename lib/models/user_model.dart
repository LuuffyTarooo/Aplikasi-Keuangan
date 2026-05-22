// lib/models/user_model.dart
class UserModel {
  final String id;
  final String name;
  final String avatar;

  UserModel({
    required this.id, 
    required this.name,
    this.avatar = '😎',
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'User Tanpa Nama',
      avatar: json['avatar'] ?? '😎',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
    };
  }
}