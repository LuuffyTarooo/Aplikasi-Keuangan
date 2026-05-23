// lib/providers/mixins/saving_mixin.dart
import 'package:flutter/foundation.dart';
import 'package:aplikasi_keuangan/models/saving_model.dart';
import 'package:aplikasi_keuangan/models/user_model.dart';

/// Mixin untuk mengelola fitur tabungan (saving goals).
mixin SavingMixin on ChangeNotifier {
  List<SavingGoalModel> get allSavings;
  set allSavings(List<SavingGoalModel> val);
  UserModel? get currentUser;
  Future<void> syncToStorage();

  /// Membuat target tabungan baru dengan nama dan nominal target.
  void addSavingGoal(String name, double target) {
    try {
      final user = currentUser;
      if (user == null) return;

      allSavings.insert(0, SavingGoalModel(
        id: 'sav_${DateTime.now().millisecondsSinceEpoch}',
        name: name, target: target, userId: user.id,
      ));
      syncToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Gagal menambah tabungan: $e');
    }
  }

  /// Menambah atau mengurangi progress tabungan.
  /// [isNabung] = true berarti menambah, false berarti menarik.
  void updateSavingProgress(String id, double amount, bool isNabung) {
    try {
      final index = allSavings.indexWhere((s) => s.id == id);
      if (index != -1) {
        isNabung
            ? allSavings[index].current += amount
            : allSavings[index].current -= amount;
        syncToStorage();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Gagal memperbarui progress tabungan: $e');
    }
  }

  /// Menghapus target tabungan berdasarkan ID.
  void deleteSavingGoal(String id) {
    try {
      allSavings.removeWhere((s) => s.id == id);
      syncToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Gagal menghapus tabungan: $e');
    }
  }
}
