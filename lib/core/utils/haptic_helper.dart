// lib/core/utils/haptic_helper.dart
import 'package:flutter/services.dart';

class HapticHelper {
  HapticHelper._();

  /// Haptic feedback untuk aksi sukses.
  static void success() {
    HapticFeedback.mediumImpact();
  }
}
