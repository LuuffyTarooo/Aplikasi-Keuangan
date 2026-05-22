// lib/models/category_model.dart
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:aplikasi_keuangan/utils/category_icons.dart';

class CategoryModel {
  final String id;
  final String name;
  final String jenis; // Pemasukan / Pengeluaran
  final String userId;
  final IconData icon;
  final Color accentColor;
  final Color bgColor;
  final bool isCustom;
  final int index;

  CategoryModel({
    required this.id,
    required this.name,
    required this.jenis,
    required this.userId,
    required this.icon,
    required this.accentColor,
    required this.bgColor,
    this.isCustom = false,
    this.index = 0,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    // Fallback logic for older json formats
    final int codePoint = json['iconCodePoint'] ?? TablerIcons.category.codePoint;
    final String fontFamily = json['iconFontFamily'] ?? 'TablerIcons';
    final String? fontPackage = json['iconFontPackage'] ?? 'flutter_tabler_icons';

    // Fallback colors if none exist
    final int accentVal = json['accentColor'] ?? Colors.blueAccent.value;
    final int bgVal = json['bgColor'] ?? Colors.blueAccent.withValues(alpha: 0.1).value;

    return CategoryModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      jenis: json['jenis'] ?? 'Pengeluaran',
      userId: json['userId'] ?? '',
      icon: _getIconFromCodePoint(codePoint),
      accentColor: Color(accentVal),
      bgColor: Color(bgVal),
      isCustom: json['isCustom'] ?? false,
      index: json['index'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'jenis': jenis,
      'userId': userId,
      'iconCodePoint': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'iconFontPackage': icon.fontPackage,
      'accentColor': accentColor.value,
      'bgColor': bgColor.value,
      'isCustom': isCustom,
      'index': index,
    };
  }

  // Helper function to bypass Tree Shaking compiler errors
  static IconData _getIconFromCodePoint(int codePoint) {
    try {
      return categoryIcons.firstWhere((icon) => icon.codePoint == codePoint);
    } catch (e) {
      return TablerIcons.category; // Fallback jika tidak ditemukan
    }
  }
}