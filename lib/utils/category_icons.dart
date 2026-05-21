// lib/utils/category_icons.dart
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

final List<IconData> categoryIcons = [
  TablerIcons.pizza,
  TablerIcons.coffee,
  TablerIcons.car,
  TablerIcons.train,
  TablerIcons.bus,
  TablerIcons.shopping_bag,
  TablerIcons.shopping_cart,
  TablerIcons.shirt,
  TablerIcons.device_mobile,
  TablerIcons.device_gamepad_2,
  TablerIcons.movie,
  TablerIcons.music,
  TablerIcons.book,
  TablerIcons.school,
  TablerIcons.heart,
  TablerIcons.vaccine,
  TablerIcons.stethoscope,
  TablerIcons.home,
  TablerIcons.building,
  TablerIcons.sofa,
  TablerIcons.bolt,
  TablerIcons.droplet,
  TablerIcons.wifi,
  TablerIcons.users,
  TablerIcons.gift,
  TablerIcons.wallet,
  TablerIcons.cash,
  TablerIcons.coin,
  TablerIcons.plane_tilt,
  TablerIcons.beach,
];

// Pastel color palette for categories
class CategoryColors {
  final Color accent;
  final Color bg;

  CategoryColors(this.accent, this.bg);
}

final List<CategoryColors> categoryColorPalette = [
  CategoryColors(const Color(0xFFFF8A65), const Color(0xFFFF8A65).withValues(alpha: 0.15)), // Orange/Red
  CategoryColors(const Color(0xFF4DB6AC), const Color(0xFF4DB6AC).withValues(alpha: 0.15)), // Teal
  CategoryColors(const Color(0xFF7986CB), const Color(0xFF7986CB).withValues(alpha: 0.15)), // Indigo
  CategoryColors(const Color(0xFFBA68C8), const Color(0xFFBA68C8).withValues(alpha: 0.15)), // Purple
  CategoryColors(const Color(0xFFF06292), const Color(0xFFF06292).withValues(alpha: 0.15)), // Pink
  CategoryColors(const Color(0xFF64B5F6), const Color(0xFF64B5F6).withValues(alpha: 0.15)), // Blue
  CategoryColors(const Color(0xFF81C784), const Color(0xFF81C784).withValues(alpha: 0.15)), // Green
  CategoryColors(const Color(0xFFFFD54F), const Color(0xFFFFD54F).withValues(alpha: 0.15)), // Yellow/Gold
  CategoryColors(const Color(0xFFE57373), const Color(0xFFE57373).withValues(alpha: 0.15)), // Soft Red
  CategoryColors(const Color(0xFF4DD0E1), const Color(0xFF4DD0E1).withValues(alpha: 0.15)), // Cyan
];
