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
import 'package:aplikasi_keuangan/core/constants/app_constants.dart';
import 'package:aplikasi_keuangan/models/currency_model.dart';
import 'package:aplikasi_keuangan/utils/currency_manager.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';

// Mixin imports
import 'package:aplikasi_keuangan/providers/mixins/theme_mixin.dart';
import 'package:aplikasi_keuangan/providers/mixins/pin_mixin.dart';
import 'package:aplikasi_keuangan/providers/mixins/transaction_mixin.dart';
import 'package:aplikasi_keuangan/providers/mixins/wallet_mixin.dart';
import 'package:aplikasi_keuangan/providers/mixins/budget_mixin.dart';
import 'package:aplikasi_keuangan/providers/mixins/saving_mixin.dart';
import 'package:aplikasi_keuangan/providers/mixins/debt_mixin.dart';
import 'package:aplikasi_keuangan/providers/mixins/reminder_mixin.dart';
import 'package:aplikasi_keuangan/providers/mixins/user_mixin.dart';
import 'package:aplikasi_keuangan/providers/mixins/voice_mixin.dart';
import 'package:aplikasi_keuangan/providers/mixins/report_mixin.dart';
import 'package:aplikasi_keuangan/providers/mixins/category_mixin.dart';

/// Provider utama aplikasi keuangan.
///
/// Bertanggung jawab sebagai orchestrator: menyimpan state global
/// dan mendelegasikan logika bisnis ke mixin yang sesuai.
/// Setiap domain (transaksi, tabungan, hutang, dll.) dikelola oleh mixin tersendiri.
class FinanceProvider extends ChangeNotifier
    with
        ThemeMixin,
        PinMixin,
        TransactionMixin,
        WalletMixin,
        BudgetMixin,
        SavingMixin,
        DebtMixin,
        ReminderMixin,
        UserMixin,
        VoiceMixin,
        ReportMixin,
        CategoryMixin {

  // =========================================
  // 📦 STATE FIELDS
  // =========================================
  bool isSecurityMounted = false;
  bool isDataMounted = false;

  @override
  List<UserModel> users = [];

  @override
  UserModel? currentUser;

  @override
  List<WalletModel> allSumberDana = [];

  @override
  List<TransactionModel> allTransaksi = [];

  @override
  List<CategoryModel> allKategori = [];

  @override
  List<BudgetModel> allBudgets = [];

  @override
  List<SavingGoalModel> allSavings = [];

  @override
  List<DebtModel> allDebts = [];

  @override
  List<ReminderModel> allReminders = [];

  CurrencyModel currentCurrency = CurrencyManager.defaultCurrencies[0];

  // =========================================
  // 🔍 FILTERED GETTERS (per-user)
  // =========================================

  /// Dompet milik user aktif.
  @override
  List<WalletModel> get mySumberDana =>
      currentUser == null ? [] : allSumberDana.where((d) => d.userId == currentUser!.id).toList();

  /// Transaksi milik user aktif.
  List<TransactionModel> get myTransaksi =>
      currentUser == null ? [] : allTransaksi.where((t) => t.userId == currentUser!.id).toList();

  /// Kategori (global, tidak per-user).
  @override
  List<CategoryModel> get myKategori => allKategori;

  /// Tabungan milik user aktif.
  List<SavingGoalModel> get mySavings =>
      currentUser == null ? [] : allSavings.where((s) => s.userId == currentUser!.id).toList();

  /// Hutang/piutang milik user aktif.
  List<DebtModel> get myDebts =>
      currentUser == null ? [] : allDebts.where((d) => d.userId == currentUser!.id).toList();

  /// Pengingat milik user aktif.
  List<ReminderModel> get myReminders =>
      currentUser == null ? [] : allReminders.where((r) => r.userId == currentUser!.id).toList();

  // =========================================
  // 🚀 LIFECYCLE
  // =========================================

  /// Implementasi kontrak `syncToStorage()` yang digunakan oleh semua mixin.
  /// Menyimpan seluruh state ke penyimpanan lokal.
  @override
  void syncToStorage() {
    try {
      LocalStorageService.saveData(StorageKeys.isDarkMode, isDarkMode);
      LocalStorageService.saveData(StorageKeys.themeAccentColor, themeAccent.toARGB32());
      LocalStorageService.saveData(StorageKeys.users, users.map((e) => e.toJson()).toList());
      LocalStorageService.saveData(StorageKeys.wallets, allSumberDana.map((e) => e.toJson()).toList());
      LocalStorageService.saveData(StorageKeys.transactions, allTransaksi.map((e) => e.toJson()).toList());
      LocalStorageService.saveData(StorageKeys.categories, allKategori.map((e) => e.toJson()).toList());
      LocalStorageService.saveData(StorageKeys.budgets, allBudgets.map((e) => e.toJson()).toList());
      LocalStorageService.saveData(StorageKeys.savings, allSavings.map((e) => e.toJson()).toList());
      LocalStorageService.saveData(StorageKeys.debts, allDebts.map((e) => e.toJson()).toList());
      LocalStorageService.saveData(StorageKeys.reminders, allReminders.map((e) => e.toJson()).toList());
    } catch (e) {
      debugPrint('❌ Sync ke storage gagal: $e');
    }
  }

  /// Inisialisasi semua data dari penyimpanan lokal.
  /// Dipanggil sekali saat app startup via `FinanceProvider()..initData()`.
  Future<void> initData() async {
    try {
      // 1. Load preferensi security & UI tercepat (Kurang dari 50ms)
      await loadThemePreferences(); // ThemeMixin
      await loadPin();              // PinMixin
      await loadLockout();          // PinMixin
      
      // Kasih tau UI kalau layar PIN udah bisa digambar tanpa nunggu SQLite selesai!
      isSecurityMounted = true;
      notifyListeners();

      // 2. Load data berat di background
      await loadNotificationPreferences(); // ReminderMixin
      await _loadAllData();
      
      currentCurrency = await CurrencyManager.loadActiveCurrency();
      Formatters.activeCurrency = currentCurrency;
      
      checkAndScheduleNotifications();

      isDataMounted = true;
      notifyListeners();
    } catch (e) {
      debugPrint('❌ initData gagal: $e');
      isSecurityMounted = true;
      isDataMounted = true;
      notifyListeners();
    }
  }

  /// Memuat ulang data transaksi & dompet dari storage (dipanggil saat app resume dari background)
  Future<void> reloadDataFromStorage() async {
    try {
      // Wajib forceReload agar SharedPreferences mengambil data dari disk fisik,
      // karena Widget berjalan di memori (mesin) yang berbeda.
      await LocalStorageService.forceReload();
      await _loadAllData();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ reloadDataFromStorage gagal: $e');
    }
  }

  // =========================================
  // 🔧 PRIVATE HELPERS
  // =========================================
  
  void updateCurrency(CurrencyModel newCurrency, double customRate) {
    currentCurrency = CurrencyModel(
      name: newCurrency.name,
      code: newCurrency.code,
      symbol: newCurrency.symbol,
      exchangeRateToIdr: customRate,
    );
    Formatters.activeCurrency = currentCurrency;
    CurrencyManager.saveActiveCurrency(currentCurrency);
    notifyListeners();
  }

  /// Memuat semua data bisnis dari penyimpanan lokal.
  Future<void> _loadAllData() async {
    final usersJson = await LocalStorageService.loadData(StorageKeys.users);
    final danaJson = await LocalStorageService.loadData(StorageKeys.wallets);
    final txJson = await LocalStorageService.loadData(StorageKeys.transactions);
    final kategoriJson = await LocalStorageService.loadData(StorageKeys.categories);
    final budgetJson = await LocalStorageService.loadData(StorageKeys.budgets);
    final savingsJson = await LocalStorageService.loadData(StorageKeys.savings);
    final debtsJson = await LocalStorageService.loadData(StorageKeys.debts);
    final remJson = await LocalStorageService.loadData(StorageKeys.reminders);

    if (usersJson != null) {
      users = (usersJson as List).map((item) => UserModel.fromJson(item)).toList();
    }
    if (users.isEmpty) {
      final newUser = UserModel(id: 'user_utama_jar', name: 'User Utama');
      users = [newUser];
      syncToStorage();
    }
    currentUser = users[0];

    if (danaJson != null) allSumberDana = (danaJson as List).map((item) => WalletModel.fromJson(item)).toList();
    if (txJson != null) allTransaksi = (txJson as List).map((item) => TransactionModel.fromJson(item)).toList();
    if (kategoriJson != null) allKategori = (kategoriJson as List).map((item) => CategoryModel.fromJson(item)).toList();
    
    // Inisialisasi kategori default jika masih kosong (dari CategoryMixin)
    initDefaultCategories();

    if (budgetJson != null) allBudgets = (budgetJson as List).map((item) => BudgetModel.fromJson(item)).toList();
    if (savingsJson != null) allSavings = (savingsJson as List).map((item) => SavingGoalModel.fromJson(item)).toList();
    if (debtsJson != null) allDebts = (debtsJson as List).map((item) => DebtModel.fromJson(item)).toList();
    if (remJson != null) allReminders = (remJson as List).map((item) => ReminderModel.fromJson(item)).toList();
  }
}