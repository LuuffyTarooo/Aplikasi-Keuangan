// lib/core/utils/vibrate.dart
import 'package:flutter/services.dart';

class Vibrate {
  /// ==========================================
  /// 📳 HAPTIC FEEDBACK (EFEK GETARAN)
  /// ==========================================
  /// Fungsi ini ngasih "rasa" fisik (haptic) setiap kali user mencet tombol penting.
  /// 
  /// Di Flutter, kita pakai HapticFeedback bawaan sistem yang lebih presisi
  /// dan aman dibanding mengatur milisecond manual.
  
  static void light() {
    HapticFeedback.lightImpact();
  }

  static void medium() {
    HapticFeedback.mediumImpact();
  }

  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  static void selection() {
    HapticFeedback.selectionClick();
  }

  /// Khusus untuk simulasi pola error/sukses (bergetar beberapa kali)
  static Future<void> error() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();
  }

  static Future<void> success() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 150));
    HapticFeedback.heavyImpact();
  }

  /// Fungsi fallback biar kompatibel sama kode React lama lu (vibrate(50) atau vibrate([30,50]))
  static void custom(dynamic pattern) {
    if (pattern is int) {
      if (pattern < 30) {
        light();
      } else if (pattern < 60) {
        medium();
      } else {
        heavy();
      }
    } else if (pattern is List<int>) {
      // Simulasi array pattern
      _playPattern(pattern);
    }
  }

  static Future<void> _playPattern(List<int> pattern) async {
    for (int duration in pattern) {
      if (duration > 0) {
        HapticFeedback.mediumImpact(); // Getar
      }
      await Future.delayed(Duration(milliseconds: duration)); // Jeda
    }
  }
}