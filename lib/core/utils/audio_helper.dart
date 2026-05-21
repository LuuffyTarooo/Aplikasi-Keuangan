// lib/core/utils/audio_helper.dart
import 'package:flutter/services.dart';

class AudioHelper {
  AudioHelper._();

  /// Memainkan suara sukses sederhana bawaan sistem operasi.
  static void playSuccessSound() {
    SystemSound.play(SystemSoundType.click);
  }
}
