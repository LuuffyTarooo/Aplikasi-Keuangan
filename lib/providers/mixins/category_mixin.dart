// lib/providers/mixins/category_mixin.dart
import 'package:flutter/material.dart';
import 'package:aplikasi_keuangan/models/category_model.dart';
import 'package:aplikasi_keuangan/models/user_model.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';
import 'package:aplikasi_keuangan/utils/category_icons.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

mixin CategoryMixin on ChangeNotifier {
  List<CategoryModel> get allKategori;
  set allKategori(List<CategoryModel> value);
  
  UserModel? get currentUser;
  List<TransactionModel> get allTransaksi;
  void syncToStorage();

  // Inisialisasi kategori default jika kosong
  void initDefaultCategories() {
    if (currentUser == null) return;
    bool hasUserCategories = allKategori.any((c) => c.userId == currentUser!.id);
    if (hasUserCategories) return;

    final defaultExpenses = [
      {'name': 'Makanan & Minuman', 'icon': TablerIcons.pizza, 'colorIdx': 0},
      {'name': 'Transportasi', 'icon': TablerIcons.car, 'colorIdx': 1},
      {'name': 'Kesehatan', 'icon': TablerIcons.stethoscope, 'colorIdx': 2},
      {'name': 'Belanja', 'icon': TablerIcons.shopping_bag, 'colorIdx': 3},
      {'name': 'Tagihan', 'icon': TablerIcons.receipt, 'colorIdx': 4},
      {'name': 'Hiburan', 'icon': TablerIcons.movie, 'colorIdx': 5},
      {'name': 'Pendidikan', 'icon': TablerIcons.school, 'colorIdx': 6},
      {'name': 'Perawatan', 'icon': TablerIcons.cut, 'colorIdx': 7},
      {'name': 'Rumah Tangga', 'icon': TablerIcons.home, 'colorIdx': 8},
      {'name': 'Donasi / Amal', 'icon': TablerIcons.heart_handshake, 'colorIdx': 9},
      {'name': 'Lainnya', 'icon': TablerIcons.dots, 'colorIdx': 0},
    ];
    
    final defaultIncomes = [
      {'name': 'Gaji', 'icon': TablerIcons.cash, 'colorIdx': 6},
      {'name': 'Bonus', 'icon': TablerIcons.gift, 'colorIdx': 7},
      {'name': 'Hasil Usaha', 'icon': TablerIcons.building_store, 'colorIdx': 8},
      {'name': 'Hadiah', 'icon': TablerIcons.gift, 'colorIdx': 9},
      {'name': 'Lainnya', 'icon': TablerIcons.dots, 'colorIdx': 1},
    ];

    int index = 0;
    for (var cat in defaultExpenses) {
      final palette = categoryColorPalette[(cat['colorIdx'] as int) % categoryColorPalette.length];
      allKategori.add(CategoryModel(
        id: 'cat_${DateTime.now().millisecondsSinceEpoch}_${index++}',
        name: cat['name'] as String,
        jenis: 'Pengeluaran',
        userId: currentUser!.id,
        icon: cat['icon'] as IconData,
        accentColor: palette.accent,
        bgColor: palette.bg,
        isCustom: false,
        index: index,
      ));
    }

    index = 0;
    for (var cat in defaultIncomes) {
      final palette = categoryColorPalette[(cat['colorIdx'] as int) % categoryColorPalette.length];
      allKategori.add(CategoryModel(
        id: 'cat_${DateTime.now().millisecondsSinceEpoch}_${index++}',
        name: cat['name'] as String,
        jenis: 'Pemasukan',
        userId: currentUser!.id,
        icon: cat['icon'] as IconData,
        accentColor: palette.accent,
        bgColor: palette.bg,
        isCustom: false,
        index: index,
      ));
    }
    syncToStorage();
  }

  List<CategoryModel> get expenseCategories {
    if (currentUser == null) return [];
    var list = allKategori.where((c) => c.jenis == 'Pengeluaran' && c.userId == currentUser!.id).toList();
    list.sort((a, b) => a.index.compareTo(b.index));
    return list;
  }

  List<CategoryModel> get incomeCategories {
    if (currentUser == null) return [];
    var list = allKategori.where((c) => c.jenis == 'Pemasukan' && c.userId == currentUser!.id).toList();
    list.sort((a, b) => a.index.compareTo(b.index));
    return list;
  }

  CategoryModel getCategoryByName(String name) {
    try {
      return allKategori.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase() && c.userId == currentUser?.id,
      );
    } catch (_) {
      // Fallback category
      return CategoryModel(
        id: 'fallback_cat',
        name: name.isEmpty ? 'Lainnya' : name,
        jenis: 'Pengeluaran',
        userId: currentUser?.id ?? '',
        icon: TablerIcons.dots,
        accentColor: Colors.grey,
        bgColor: Colors.grey.withValues(alpha: 0.1),
      );
    }
  }

  void addCustomCategory(String name, String jenis, IconData icon, Color accentColor, Color bgColor) {
    if (currentUser == null) return;
    
    final list = jenis == 'Pengeluaran' ? expenseCategories : incomeCategories;
    int nextIndex = list.isEmpty ? 0 : list.map((e) => e.index).reduce((a, b) => a > b ? a : b) + 1;

    final newCat = CategoryModel(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      jenis: jenis,
      userId: currentUser!.id,
      icon: icon,
      accentColor: accentColor,
      bgColor: bgColor,
      isCustom: true,
      index: nextIndex,
    );

    allKategori.add(newCat);
    syncToStorage();
    notifyListeners();
  }

  bool deleteCategory(String categoryId) {
    try {
      final cat = allKategori.firstWhere((c) => c.id == categoryId);
      
      bool isUsed = allTransaksi.any((t) => t.kategori == cat.name);
      if (isUsed) {
        return false; // Gagal dihapus karena masih dipakai
      }

      allKategori.removeWhere((c) => c.id == categoryId);
      syncToStorage();
      notifyListeners();
      return true; // Berhasil
    } catch (e) {
      debugPrint('Error deleteCategory: $e');
      return false;
    }
  }

  void updateCategoryOrder(String jenis, int oldIndex, int newIndex) {
    try {
      final list = jenis == 'Pengeluaran' ? expenseCategories : incomeCategories;
      
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      
      final item = list.removeAt(oldIndex);
      list.insert(newIndex, item);
      
      for (int i = 0; i < list.length; i++) {
        final indexInAll = allKategori.indexWhere((c) => c.id == list[i].id);
        if (indexInAll != -1) {
          allKategori[indexInAll] = CategoryModel(
            id: list[i].id,
            name: list[i].name,
            jenis: list[i].jenis,
            userId: list[i].userId,
            icon: list[i].icon,
            accentColor: list[i].accentColor,
            bgColor: list[i].bgColor,
            isCustom: list[i].isCustom,
            index: i,
          );
        }
      }

      syncToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('Error updateCategoryOrder: $e');
    }
  }
}
