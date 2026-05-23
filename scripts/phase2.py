import os
import re

def modify_syncToStorage():
    # Update mixins
    mixin_dir = r'C:\Users\fajar\aplikasi_keuangan\lib\providers\mixins'
    for file in os.listdir(mixin_dir):
        if not file.endswith('.dart'): continue
        filepath = os.path.join(mixin_dir, file)
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Change void syncToStorage(); to Future<void> syncToStorage();
        new_content = content.replace('void syncToStorage();', 'Future<void> syncToStorage();')
        
        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Updated {file}")
            
    # Update finance_provider.dart
    fp_path = r'C:\Users\fajar\aplikasi_keuangan\lib\providers\finance_provider.dart'
    with open(fp_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Change void syncToStorage() to Future<void> syncToStorage() async { await Future.wait([...]) }
    old_sync = """  void syncToStorage() {
    try {
      LocalStorageService.saveData(StorageKeys.isDarkMode, isDarkMode);
      LocalStorageService.saveData(StorageKeys.themeAccentColor, themeAccent.toARGB32());
      LocalStorageService.saveData(StorageKeys.users, users.map((e) => e.toJson()).toList());
      LocalStorageService.saveData(StorageKeys.wallets, allWallets.map((e) => e.toJson()).toList());
      LocalStorageService.saveData(StorageKeys.transactions, allTransaksi.map((e) => e.toJson()).toList());
      LocalStorageService.saveData(StorageKeys.categories, allKategori.map((e) => e.toJson()).toList());
      LocalStorageService.saveData(StorageKeys.budgets, allBudgets.map((e) => e.toJson()).toList());
      LocalStorageService.saveData(StorageKeys.savings, allSavings.map((e) => e.toJson()).toList());
      LocalStorageService.saveData(StorageKeys.debts, allDebts.map((e) => e.toJson()).toList());
      LocalStorageService.saveData(StorageKeys.reminders, allReminders.map((e) => e.toJson()).toList());
    } catch (e) {
      debugPrint('❌ Sync ke storage gagal: $e');
    }
  }"""
    
    new_sync = """  Future<void> syncToStorage() async {
    try {
      await Future.wait([
        LocalStorageService.saveData(StorageKeys.isDarkMode, isDarkMode),
        LocalStorageService.saveData(StorageKeys.themeAccentColor, themeAccent.toARGB32()),
        LocalStorageService.saveData(StorageKeys.users, users.map((e) => e.toJson()).toList()),
        LocalStorageService.saveData(StorageKeys.wallets, allWallets.map((e) => e.toJson()).toList()),
        LocalStorageService.saveData(StorageKeys.transactions, allTransaksi.map((e) => e.toJson()).toList()),
        LocalStorageService.saveData(StorageKeys.categories, allKategori.map((e) => e.toJson()).toList()),
        LocalStorageService.saveData(StorageKeys.budgets, allBudgets.map((e) => e.toJson()).toList()),
        LocalStorageService.saveData(StorageKeys.savings, allSavings.map((e) => e.toJson()).toList()),
        LocalStorageService.saveData(StorageKeys.debts, allDebts.map((e) => e.toJson()).toList()),
        LocalStorageService.saveData(StorageKeys.reminders, allReminders.map((e) => e.toJson()).toList()),
      ]);
    } catch (e) {
      debugPrint('❌ Sync ke storage gagal: $e');
    }
  }"""
    
    if old_sync in content:
        content = content.replace(old_sync, new_sync)
        with open(fp_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print("Updated finance_provider.dart")
    else:
        print("Failed to find syncToStorage implementation in finance_provider.dart")

def modify_wallet_deletion():
    filepath = r'C:\Users\fajar\aplikasi_keuangan\lib\providers\mixins\wallet_mixin.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Add import for TransactionModel
    if "import 'package:aplikasi_keuangan/models/transaction_model.dart';" not in content:
        content = content.replace(
            "import 'package:aplikasi_keuangan/models/wallet_model.dart';",
            "import 'package:aplikasi_keuangan/models/wallet_model.dart';\nimport 'package:aplikasi_keuangan/models/transaction_model.dart';"
        )
    
    # 2. Add List<TransactionModel> get allTransaksi;
    if "List<TransactionModel> get allTransaksi;" not in content:
        content = content.replace(
            "set allWallets(List<WalletModel> val);",
            "set allWallets(List<WalletModel> val);\n  List<TransactionModel> get allTransaksi;"
        )
        
    # 3. Replace deleteWallet
    old_delete = """  void deleteWallet(String walletId) {
    try {
      allWallets.removeWhere((w) => w.walletId == walletId);
      syncToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Gagal menghapus dompet: $e');
    }
  }"""
    
    new_delete = """  void deleteWallet(String walletId) {
    try {
      final hasTransactions = allTransaksi.any((t) => t.walletId == walletId || t.targetWalletId == walletId);
      if (hasTransactions) {
        // Gabungan A & D: Jangan hapus permanen, ganti ke arsip
        toggleArchiveWallet(walletId);
        debugPrint('ℹ️ Dompet $walletId memiliki transaksi. Mengarsipkan dompet alih-alih menghapus permanen.');
      } else {
        // Hapus permanen karena kosong
        allWallets.removeWhere((w) => w.walletId == walletId);
        syncToStorage();
        notifyListeners();
        debugPrint('✅ Dompet $walletId dihapus permanen karena tidak ada riwayat transaksi.');
      }
    } catch (e) {
      debugPrint('⚠️ Gagal menghapus dompet: $e');
    }
  }"""
  
    if old_delete in content:
        content = content.replace(old_delete, new_delete)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print("Updated wallet deletion in wallet_mixin.dart")
    else:
        print("Failed to find old deleteWallet in wallet_mixin.dart")

if __name__ == '__main__':
    modify_syncToStorage()
    modify_wallet_deletion()
