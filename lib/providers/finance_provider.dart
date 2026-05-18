// lib/providers/finance_provider.dart
import 'package:flutter/material.dart';
import 'package:aplikasi_keuangan/models/user_model.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';
import 'package:aplikasi_keuangan/models/wallet_model.dart';
import 'package:aplikasi_keuangan/models/category_model.dart';
import 'package:aplikasi_keuangan/models/budget_model.dart';
import 'package:aplikasi_keuangan/models/saving_model.dart';
import 'package:aplikasi_keuangan/models/debt_model.dart';
import 'package:aplikasi_keuangan/models/reminder_model.dart';
import 'package:aplikasi_keuangan/services/local_storage_service.dart';

class FinanceProvider with ChangeNotifier {

  // =========================================
  // 🎨 TEMA: DARK/LIGHT MODE + CUSTOM AKSEN
  // =========================================
  bool _isDarkMode = true; // Default Gelap
  Color _themeAccentColor = const Color(0xFF00AA5B); // Default Hijau GoPay

  bool get isDarkMode => _isDarkMode;
  Color get themeAccent => _themeAccentColor;

  // Latar & Kartu Kunci Mati di Warna Solid/Flat
  Color get themeBg => _isDarkMode ? const Color(0xFF121212) : const Color(0xFFF5F6F8);
  Color get themeCard => _isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  Color get themeText => _isDarkMode ? Colors.white : const Color(0xFF1A1A1A);
  Color get themeTextSub => _isDarkMode ? Colors.white54 : const Color(0xFF757575);
  Color get themeBorder => _isDarkMode ? Colors.white10 : const Color(0xFFE0E0E0);

  // Fungsi Saklar Terang/Gelap
  void toggleTheme(bool value) {
    _isDarkMode = value;
    _syncToStorage();
    notifyListeners();
  }

  // Fungsi Ganti Warna Tombol/Logo
  void updateThemeAccent(Color color) {
    _themeAccentColor = color;
    _syncToStorage();
    notifyListeners();
  }

  // =========================================
  // 💼 STATE KEUANGAN & DATA (TETAP SAMA)
  // =========================================
  bool isDataMounted = false;
  List<UserModel> users = [];
  UserModel? currentUser;

  List<WalletModel> allSumberDana = [];
  List<TransactionModel> allTransaksi = [];
  List<CategoryModel> allKategori = [];
  List<BudgetModel> allBudgets = [];
  List<SavingGoalModel> allSavings = []; 
  List<DebtModel> allDebts = []; 
  List<ReminderModel> allReminders = []; 

  List<WalletModel> get mySumberDana => currentUser == null ? [] : allSumberDana.where((d) => d.userId == currentUser!.id).toList();
  List<TransactionModel> get myTransaksi => currentUser == null ? [] : allTransaksi.where((t) => t.userId == currentUser!.id).toList();
  List<CategoryModel> get myKategori => allKategori;
  List<SavingGoalModel> get mySavings => currentUser == null ? [] : allSavings.where((s) => s.userId == currentUser!.id).toList();
  List<DebtModel> get myDebts => currentUser == null ? [] : allDebts.where((d) => d.userId == currentUser!.id).toList();
  List<ReminderModel> get myReminders => currentUser == null ? [] : allReminders.where((r) => r.userId == currentUser!.id).toList();

  BudgetModel? get myBudget {
    if (currentUser == null) return null;
    return allBudgets.firstWhere(
      (b) => b.userId == currentUser!.id,
      orElse: () {
        final newBudget = BudgetModel(userId: currentUser!.id, limitBulanan: 0, categoryLimits: {});
        allBudgets.add(newBudget);
        return newBudget;
      },
    );
  }

  Future<void> initData() async {
    // 🟢 LOAD TEMA & AKSEN
    final savedTheme = await LocalStorageService.loadData('is_dark_mode');
    if (savedTheme != null) _isDarkMode = savedTheme as bool;

    final savedAccent = await LocalStorageService.loadData('theme_accent_color');
    if (savedAccent != null) _themeAccentColor = Color(savedAccent as int);

    // LOAD DATA
    final usersJson = await LocalStorageService.loadData('duit_users');
    final danaJson = await LocalStorageService.loadData('all_sumberDana');
    final txJson = await LocalStorageService.loadData('all_transaksi');
    final kategoriJson = await LocalStorageService.loadData('all_kategori');
    final budgetJson = await LocalStorageService.loadData('all_budgets'); 
    final savingsJson = await LocalStorageService.loadData('all_savings'); 
    final debtsJson = await LocalStorageService.loadData('all_debts'); 
    final remJson = await LocalStorageService.loadData('all_reminders'); 

    if (usersJson != null) users = (usersJson as List).map((item) => UserModel.fromJson(item)).toList();
    if (users.isEmpty) {
      final newUser = UserModel(id: 'user_utama_jar', name: 'User Utama'); 
      users = [newUser];
      _syncToStorage();
    }
    currentUser = users[0];

    if (danaJson != null) allSumberDana = (danaJson as List).map((item) => WalletModel.fromJson(item)).toList();
    if (txJson != null) allTransaksi = (txJson as List).map((item) => TransactionModel.fromJson(item)).toList();
    if (kategoriJson != null) allKategori = (kategoriJson as List).map((item) => CategoryModel.fromJson(item)).toList();
    if (budgetJson != null) allBudgets = (budgetJson as List).map((item) => BudgetModel.fromJson(item)).toList();
    if (savingsJson != null) allSavings = (savingsJson as List).map((item) => SavingGoalModel.fromJson(item)).toList();
    if (debtsJson != null) allDebts = (debtsJson as List).map((item) => DebtModel.fromJson(item)).toList();
    if (remJson != null) allReminders = (remJson as List).map((i) => ReminderModel.fromJson(i)).toList();

    isDataMounted = true;
    notifyListeners(); 
  }

  void addSavingGoal(String name, double target) {
    if (currentUser == null) return;
    allSavings.insert(0, SavingGoalModel(id: 'sav_${DateTime.now().millisecondsSinceEpoch}', name: name, target: target, userId: currentUser!.id));
    _syncToStorage();
    notifyListeners();
  }

  void updateSavingProgress(String id, double amount, bool isNabung) {
    int index = allSavings.indexWhere((s) => s.id == id);
    if (index != -1) {
      isNabung ? allSavings[index].current += amount : allSavings[index].current -= amount;
      _syncToStorage();
      notifyListeners();
    }
  }

  void deleteSavingGoal(String id) {
    allSavings.removeWhere((s) => s.id == id);
    _syncToStorage();
    notifyListeners();
  }

  void addDebt(DebtModel debt) {
    allDebts.insert(0, debt);
    _syncToStorage();
    notifyListeners();
  }

  void payDebt(String id, double amount, String date) {
    int index = allDebts.indexWhere((d) => d.id == id);
    if (index != -1) {
      allDebts[index].paid += amount;
      if (allDebts[index].paid >= allDebts[index].amount) allDebts[index].isCompleted = true;
      allDebts[index].txDates.add(date);
      _syncToStorage();
      notifyListeners();
    }
  }

  void deleteDebt(String id) {
    allDebts.removeWhere((d) => d.id == id);
    _syncToStorage();
    notifyListeners();
  }

  void addReminder(ReminderModel r) {
    allReminders.add(r);
    allReminders.sort((a, b) => DateTime.parse(a.dueDate).compareTo(DateTime.parse(b.dueDate)));
    _syncToStorage();
    notifyListeners();
  }

  void payReminder(String id, bool isRecurring, DateTime nextMonth) {
    if (currentUser == null) return;
    int index = allReminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      allReminders[index].isDone = true;
      if (isRecurring) {
        allReminders.add(ReminderModel(id: 'rem_${DateTime.now().millisecondsSinceEpoch}', title: allReminders[index].title, kategori: allReminders[index].kategori, nominal: allReminders[index].nominal, dueDate: nextMonth.toIso8601String(), userId: currentUser!.id));
        allReminders.sort((a, b) => DateTime.parse(a.dueDate).compareTo(DateTime.parse(b.dueDate)));
      }
      _syncToStorage();
      notifyListeners();
    }
  }

  void deleteReminder(String id) {
    allReminders.removeWhere((r) => r.id == id);
    _syncToStorage();
    notifyListeners();
  }

  void updateGlobalBudget(double limit) {
    if (currentUser == null) return;
    int index = allBudgets.indexWhere((b) => b.userId == currentUser!.id);
    if (index != -1) {
      allBudgets[index] = BudgetModel(userId: currentUser!.id, limitBulanan: limit, categoryLimits: allBudgets[index].categoryLimits);
    } else {
      allBudgets.add(BudgetModel(userId: currentUser!.id, limitBulanan: limit, categoryLimits: {}));
    }
    _syncToStorage();
    notifyListeners();
  }

  void updateCategoryLimits(Map<String, double> newLimits) {
    if (currentUser == null) return;
    int index = allBudgets.indexWhere((b) => b.userId == currentUser!.id);
    if (index != -1) {
      allBudgets[index] = BudgetModel(userId: currentUser!.id, limitBulanan: allBudgets[index].limitBulanan, categoryLimits: newLimits);
    } else {
      allBudgets.add(BudgetModel(userId: currentUser!.id, limitBulanan: 0, categoryLimits: newLimits));
    }
    _syncToStorage();
    notifyListeners();
  }

  void handleSaveTransaksi(TransactionModel newTx) {
    if (currentUser == null) return;
    TransactionModel finalTx = newTx;
    if (finalTx.idTransaksi.isEmpty) {
      finalTx = TransactionModel(idTransaksi: 't_${DateTime.now().millisecondsSinceEpoch}', jenis: newTx.jenis, nominal: newTx.nominal, idDana: newTx.idDana, idDanaTujuan: newTx.idDanaTujuan, kategori: newTx.kategori, keterangan: newTx.keterangan, tanggal: newTx.tanggal, userId: currentUser!.id);
    }
    _applyBalanceImpact(finalTx, false);
    allTransaksi.insert(0, finalTx);
    allTransaksi.sort((a, b) => b.tanggal.compareTo(a.tanggal));
    _syncToStorage();
    notifyListeners();
  }

  void _applyBalanceImpact(TransactionModel tx, bool isRevert) {
    final multiplier = isRevert ? -1 : 1;
    for (var i = 0; i < allSumberDana.length; i++) {
      var dana = allSumberDana[i];
      double newSaldo = dana.saldoTerkini;
      if (tx.idDana == dana.idDana) {
        if (tx.jenis == 'Pengeluaran' || tx.jenis == 'Transfer') { newSaldo -= (tx.nominal * multiplier); }
        else if (tx.jenis == 'Pemasukan') { newSaldo += (tx.nominal * multiplier); }
        allSumberDana[i] = WalletModel(idDana: dana.idDana, namaAset: dana.namaAset, saldoAwal: dana.saldoAwal, saldoTerkini: newSaldo, userId: dana.userId, isActive: dana.isActive);
      }
      if (tx.jenis == 'Transfer' && tx.idDanaTujuan == dana.idDana) {
        newSaldo += (tx.nominal * multiplier);
        allSumberDana[i] = WalletModel(idDana: dana.idDana, namaAset: dana.namaAset, saldoAwal: dana.saldoAwal, saldoTerkini: newSaldo, userId: dana.userId, isActive: dana.isActive);
      }
    }
  }

  void deleteSumberDana(String idDana) {
    allSumberDana.removeWhere((w) => w.idDana == idDana);
    _syncToStorage();
    notifyListeners();
  }

  void toggleArsipSumberDana(String idDana, [dynamic extra]) {
    int index = allSumberDana.indexWhere((w) => w.idDana == idDana);
    if (index != -1) {
      allSumberDana[index].isActive = !allSumberDana[index].isActive;
      _syncToStorage();
      notifyListeners();
    }
  }

  void switchUser(String userId) {
    int index = users.indexWhere((u) => u.id == userId);
    if (index != -1) { currentUser = users[index]; notifyListeners(); }
  }

  void editUser(String userId, String newName) {
    int index = users.indexWhere((u) => u.id == userId);
    if (index != -1) {
      users[index] = UserModel(id: users[index].id, name: newName);
      if (currentUser?.id == userId) currentUser = users[index];
      _syncToStorage();
      notifyListeners();
    }
  }

  void registerUser(UserModel newUser) {
    users.add(newUser);
    currentUser = newUser; 
    _syncToStorage();
    notifyListeners();
  }

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
    _syncToStorage();
    notifyListeners();
  }

  void _syncToStorage() {
    LocalStorageService.saveData('is_dark_mode', _isDarkMode);
    LocalStorageService.saveData('theme_accent_color', _themeAccentColor.toARGB32()); // 🟢 Simpan warna Aksen
    LocalStorageService.saveData('duit_users', users.map((e) => e.toJson()).toList());
    LocalStorageService.saveData('all_sumberDana', allSumberDana.map((e) => e.toJson()).toList());
    LocalStorageService.saveData('all_transaksi', allTransaksi.map((e) => e.toJson()).toList());
    LocalStorageService.saveData('all_kategori', allKategori.map((e) => e.toJson()).toList());
    LocalStorageService.saveData('all_budgets', allBudgets.map((e) => e.toJson()).toList()); 
    LocalStorageService.saveData('all_savings', allSavings.map((e) => e.toJson()).toList()); 
    LocalStorageService.saveData('all_debts', allDebts.map((e) => e.toJson()).toList()); 
    LocalStorageService.saveData('all_reminders', allReminders.map((e) => e.toJson()).toList()); 
  }
}