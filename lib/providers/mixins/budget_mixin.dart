// lib/providers/mixins/budget_mixin.dart
import 'package:flutter/foundation.dart';
import 'package:aplikasi_keuangan/models/budget_model.dart';
import 'package:aplikasi_keuangan/models/user_model.dart';

/// Mixin untuk mengelola anggaran bulanan dan limit per kategori.
mixin BudgetMixin on ChangeNotifier {
  List<BudgetModel> get allBudgets;
  set allBudgets(List<BudgetModel> val);
  UserModel? get currentUser;
  Future<void> syncToStorage();

  /// Mengambil budget milik user aktif. Buat baru jika belum ada.
  BudgetModel? get myBudget {
    final user = currentUser;
    if (user == null) return null;
    return allBudgets.firstWhere(
      (b) => b.userId == user.id,
      orElse: () {
        final newBudget = BudgetModel(userId: user.id, limitBulanan: 0, categoryLimits: {});
        allBudgets.add(newBudget);
        return newBudget;
      },
    );
  }

  /// Memperbarui limit anggaran global bulanan.
  void updateGlobalBudget(double limit) {
    try {
      final user = currentUser;
      if (user == null) return;

      final index = allBudgets.indexWhere((b) => b.userId == user.id);
      if (index != -1) {
        allBudgets[index] = BudgetModel(
          userId: user.id, limitBulanan: limit,
          categoryLimits: allBudgets[index].categoryLimits,
        );
      } else {
        allBudgets.add(BudgetModel(userId: user.id, limitBulanan: limit, categoryLimits: {}));
      }
      syncToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Gagal memperbarui anggaran global: $e');
    }
  }

  /// Memperbarui limit anggaran per kategori.
  void updateCategoryLimits(Map<String, double> newLimits) {
    try {
      final user = currentUser;
      if (user == null) return;

      final index = allBudgets.indexWhere((b) => b.userId == user.id);
      if (index != -1) {
        allBudgets[index] = BudgetModel(
          userId: user.id, limitBulanan: allBudgets[index].limitBulanan,
          categoryLimits: newLimits,
        );
      } else {
        allBudgets.add(BudgetModel(userId: user.id, limitBulanan: 0, categoryLimits: newLimits));
      }
      syncToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Gagal memperbarui limit kategori: $e');
    }
  }
}
