// lib/utils/category_icons.dart
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

final List<IconData> categoryIcons = [
  TablerIcons.pizza, TablerIcons.coffee, TablerIcons.car, TablerIcons.train, TablerIcons.bus,
  TablerIcons.shopping_bag, TablerIcons.shopping_cart, TablerIcons.shirt, TablerIcons.device_mobile, TablerIcons.device_gamepad_2,
  TablerIcons.movie, TablerIcons.music, TablerIcons.book, TablerIcons.school, TablerIcons.heart,
  TablerIcons.vaccine, TablerIcons.stethoscope, TablerIcons.home, TablerIcons.building, TablerIcons.sofa,
  TablerIcons.bolt, TablerIcons.droplet, TablerIcons.wifi, TablerIcons.users, TablerIcons.gift,
  TablerIcons.wallet, TablerIcons.cash, TablerIcons.coin, TablerIcons.plane_tilt, TablerIcons.beach,
  TablerIcons.camera, TablerIcons.photo, TablerIcons.video, TablerIcons.microphone, TablerIcons.headphones,
  TablerIcons.ticket, TablerIcons.confetti, TablerIcons.balloon, TablerIcons.cake, TablerIcons.cup,
  TablerIcons.glass, TablerIcons.bottle, TablerIcons.apple, TablerIcons.carrot, TablerIcons.meat,
  TablerIcons.fish, TablerIcons.bread, TablerIcons.soup, TablerIcons.ice_cream, TablerIcons.cookie,
  TablerIcons.dog, TablerIcons.cat, TablerIcons.bone, TablerIcons.paw, TablerIcons.plant,
  TablerIcons.tree, TablerIcons.leaf, TablerIcons.flower, TablerIcons.sun, TablerIcons.moon,
  TablerIcons.star, TablerIcons.cloud, TablerIcons.snowflake, TablerIcons.flame, TablerIcons.umbrella,
  TablerIcons.tools, TablerIcons.hammer, TablerIcons.brush, TablerIcons.scissors, TablerIcons.pin,
  TablerIcons.map, TablerIcons.compass, TablerIcons.building_bank, TablerIcons.building_hospital, TablerIcons.building_store,
  TablerIcons.building_skyscraper, TablerIcons.tent, TablerIcons.bed, TablerIcons.bath, TablerIcons.chair_director,
  TablerIcons.desk, TablerIcons.armchair, TablerIcons.lamp, TablerIcons.key, TablerIcons.lock,
  TablerIcons.shield, TablerIcons.bell, TablerIcons.alarm, TablerIcons.clock, TablerIcons.calendar,
  TablerIcons.calculator, TablerIcons.chart_bar, TablerIcons.chart_pie, TablerIcons.chart_line, TablerIcons.report,
  TablerIcons.receipt, TablerIcons.file_invoice, TablerIcons.credit_card, TablerIcons.pig_money, TablerIcons.currency_dollar,
  TablerIcons.currency_euro, TablerIcons.currency_pound, TablerIcons.currency_yen, TablerIcons.briefcase, TablerIcons.tie,
  TablerIcons.device_desktop, TablerIcons.hanger, TablerIcons.shoe, TablerIcons.sock, TablerIcons.wash_machine,
  TablerIcons.ironing_1, TablerIcons.trash, TablerIcons.recycle, TablerIcons.box, TablerIcons.package,
  TablerIcons.truck, TablerIcons.ship, TablerIcons.device_tv, TablerIcons.caravan, TablerIcons.scooter,
  TablerIcons.bike, TablerIcons.device_laptop, TablerIcons.wheelchair, TablerIcons.ambulance, TablerIcons.device_watch,
  TablerIcons.fire_hydrant, TablerIcons.first_aid_kit, TablerIcons.pill, TablerIcons.bandage, TablerIcons.brain,
  TablerIcons.lungs, TablerIcons.letter_a, TablerIcons.eye, TablerIcons.hand_stop, TablerIcons.mood_smile,
  TablerIcons.mood_sad, TablerIcons.mood_happy, TablerIcons.mood_kid, TablerIcons.letter_b, TablerIcons.baby_carriage,
  TablerIcons.letter_c, TablerIcons.puzzle, TablerIcons.lego, TablerIcons.dice, TablerIcons.cards,
  TablerIcons.chess, TablerIcons.ball_football, TablerIcons.ball_basketball, TablerIcons.ball_tennis, TablerIcons.ball_volleyball,
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
