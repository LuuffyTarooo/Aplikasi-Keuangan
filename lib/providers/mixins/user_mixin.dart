// lib/providers/mixins/user_mixin.dart
import 'package:flutter/foundation.dart';
import 'package:aplikasi_keuangan/models/user_model.dart';
import 'package:aplikasi_keuangan/models/wallet_model.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';
import 'package:aplikasi_keuangan/models/saving_model.dart';
import 'package:aplikasi_keuangan/models/debt_model.dart';
import 'package:aplikasi_keuangan/models/reminder_model.dart';
import 'package:aplikasi_keuangan/models/budget_model.dart';

/// Mixin untuk mengelola akun pengguna (switch, edit, register, delete).
mixin UserMixin on ChangeNotifier {
  List<UserModel> get users;
  set users(List<UserModel> val);
  UserModel? get currentUser;
  set currentUser(UserModel? val);

  List<WalletModel> get allSumberDana;
  set allSumberDana(List<WalletModel> val);
  List<TransactionModel> get allTransaksi;
  set allTransaksi(List<TransactionModel> val);
  List<SavingGoalModel> get allSavings;
  set allSavings(List<SavingGoalModel> val);
  List<DebtModel> get allDebts;
  set allDebts(List<DebtModel> val);
  List<ReminderModel> get allReminders;
  set allReminders(List<ReminderModel> val);
  List<BudgetModel> get allBudgets;
  set allBudgets(List<BudgetModel> val);

  void syncToStorage();

  /// Beralih ke akun pengguna lain berdasarkan ID.
  void switchUser(String userId) {
    final index = users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      currentUser = users[index];
      notifyListeners();
    }
  }

  /// Mengedit nama pengguna berdasarkan ID.
  void editUser(String userId, String newName) {
    final index = users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      users[index] = UserModel(id: users[index].id, name: newName);
      if (currentUser?.id == userId) currentUser = users[index];
      syncToStorage();
      notifyListeners();
    }
  }

  /// Mendaftarkan akun pengguna baru dan langsung mengaktifkannya.
  void registerUser(UserModel newUser) {
    users.add(newUser);
    currentUser = newUser;
    syncToStorage();
    notifyListeners();
  }

  /// Menghapus akun pengguna beserta seluruh data terkait (dompet, transaksi, dll.).
  void deleteUser(String userId) {
    allSumberDana.removeWhere((d) => d.userId == userId);
    allTransaksi.removeWhere((t) => t.userId == userId);
    allSavings.removeWhere((s) => s.userId == userId);
    allDebts.removeWhere((d) => d.userId == userId);
    allReminders.removeWhere((r) => r.userId == userId);
    allBudgets.removeWhere((b) => b.userId == userId);
    users.removeWhere((u) => u.id == userId);

    if (currentUser?.id == userId) {
      if (users.isNotEmpty) {
        currentUser = users.first;
      } else {
        final newUser = UserModel(id: 'u_${DateTime.now().millisecondsSinceEpoch}', name: 'User Utama');
        users.add(newUser);
        currentUser = newUser;
      }
    }
    syncToStorage();
    notifyListeners();
  }
}
