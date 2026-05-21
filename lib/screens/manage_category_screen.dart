// lib/screens/manage_category_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/models/category_model.dart';
import 'package:aplikasi_keuangan/utils/category_icons.dart';
import 'package:aplikasi_keuangan/shared/widgets/custom_button.dart';

class ManageCategoryScreen extends StatefulWidget {
  const ManageCategoryScreen({super.key});

  @override
  State<ManageCategoryScreen> createState() => _ManageCategoryScreenState();
}

class _ManageCategoryScreenState extends State<ManageCategoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showToast(String message, {bool isError = false}) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.gpp_bad_rounded : Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _confirmDelete(FinanceProvider finance, CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: finance.themeBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: finance.themeBorder)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha:0.1), shape: BoxShape.circle), child: const Icon(TablerIcons.trash, color: Colors.redAccent, size: 32)),
            const SizedBox(height: 16),
            Text("Hapus Kategori?", style: TextStyle(color: finance.themeText, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text("Kategori ${category.name} akan dihapus.", textAlign: TextAlign.center, style: TextStyle(color: finance.themeTextSub, fontSize: 12)),
            const SizedBox(height: 24),
            CustomButton(text: "Ya, Hapus", variant: ButtonVariant.danger, fullWidth: true, onPressed: () {
              bool success = finance.deleteCategory(category.id);
              Navigator.pop(context);
              if (success) {
                _showToast("Kategori berhasil dihapus.");
              } else {
                _showToast("Gagal! Kategori ini masih digunakan di transaksi.", isError: true);
              }
            }),
            const SizedBox(height: 8),
            CustomButton(text: "Batal", variant: ButtonVariant.secondary, fullWidth: true, onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryModal(FinanceProvider finance, String jenis) {
    HapticFeedback.mediumImpact();
    String categoryName = '';
    IconData selectedIcon = categoryIcons[0];
    CategoryColors selectedColor = categoryColorPalette[0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: finance.themeBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), border: Border(top: BorderSide(color: finance.themeBorder))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Kategori $jenis Baru", style: TextStyle(color: finance.themeText, fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 24),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("NAMA KATEGORI", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          const SizedBox(height: 8),
                          TextField(
                            onChanged: (val) => categoryName = val,
                            style: TextStyle(color: finance.themeText, fontSize: 14, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              filled: true, fillColor: finance.themeCard,
                              hintText: "Misal: Sedekah Rutin", hintStyle: TextStyle(color: finance.themeTextSub.withValues(alpha:0.5)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: finance.themeBorder)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: finance.themeBorder)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: finance.themeAccent)),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Text("WARNA KATEGORI", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 48,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              itemCount: categoryColorPalette.length,
                              itemBuilder: (context, index) {
                                final colorItem = categoryColorPalette[index];
                                final isSelected = selectedColor == colorItem;
                                return GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setModalState(() => selectedColor = colorItem);
                                  },
                                  child: Container(
                                    width: 48,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: colorItem.accent,
                                      shape: BoxShape.circle,
                                      border: isSelected ? Border.all(color: finance.themeText, width: 3) : null,
                                    ),
                                    child: isSelected ? const Icon(TablerIcons.check, color: Colors.white, size: 20) : null,
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),

                          Text("PILIH IKON", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          const SizedBox(height: 12),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: categoryIcons.length,
                            itemBuilder: (context, index) {
                              final icon = categoryIcons[index];
                              final isSelected = selectedIcon == icon;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setModalState(() => selectedIcon = icon);
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected ? selectedColor.accent : finance.themeCard,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: isSelected ? selectedColor.accent : finance.themeBorder, width: 2),
                                  ),
                                  child: Icon(
                                    icon,
                                    color: isSelected ? Colors.white : finance.themeTextSub,
                                    size: 24,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  CustomButton(
                    text: "Simpan Kategori", fullWidth: true,
                    onPressed: () {
                      if (categoryName.trim().isEmpty) {
                        _showToast("Nama kategori tidak boleh kosong!", isError: true);
                        return;
                      }
                      finance.addCustomCategory(categoryName.trim(), jenis, selectedIcon, selectedColor.accent, selectedColor.bg);
                      Navigator.pop(context);
                      _showToast("Kategori $categoryName berhasil ditambahkan!");
                    },
                    variant: ButtonVariant.primary,
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCategoryList(FinanceProvider finance, String jenis) {
    final list = jenis == 'Pengeluaran' ? finance.expenseCategories : finance.incomeCategories;
    
    if (list.isEmpty) {
      return Center(
        child: Text("Belum ada kategori.", style: TextStyle(color: finance.themeTextSub)),
      );
    }

    return ReorderableListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100), // extra bottom padding for FAB
      itemCount: list.length,
      onReorder: (oldIndex, newIndex) {
        HapticFeedback.mediumImpact();
        finance.updateCategoryOrder(jenis, oldIndex, newIndex);
      },
      proxyDecorator: (child, index, animation) {
        return Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [BoxShadow(color: finance.themeAccent.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 2)],
            ),
            child: child,
          ),
        );
      },
      itemBuilder: (context, index) {
        final cat = list[index];
        return Container(
          key: ValueKey(cat.id),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: finance.themeCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: finance.themeBorder),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cat.bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(cat.icon, color: cat.accentColor, size: 24),
            ),
            title: Text(cat.name, style: TextStyle(color: finance.themeText, fontWeight: FontWeight.bold, fontSize: 14)),
            subtitle: cat.isCustom ? Text("Kustom", style: TextStyle(color: finance.themeTextSub, fontSize: 10)) : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (cat.isCustom)
                  IconButton(
                    icon: Icon(TablerIcons.trash, color: Colors.redAccent.withValues(alpha: 0.7), size: 20),
                    onPressed: () => _confirmDelete(finance, cat),
                  ),
                Icon(TablerIcons.grid_dots, color: finance.themeTextSub.withValues(alpha: 0.5), size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);

    return Scaffold(
      backgroundColor: finance.themeBg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCategoryModal(finance, _tabController.index == 0 ? 'Pengeluaran' : 'Pemasukan'),
        backgroundColor: finance.themeAccent,
        icon: const Icon(TablerIcons.plus, color: Colors.white),
        label: const Text("New Category", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                    child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: finance.themeCard, shape: BoxShape.circle, border: Border.all(color: finance.themeBorder)), child: Icon(Icons.arrow_back_ios_new_rounded, color: finance.themeTextSub, size: 20)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Kategori", style: TextStyle(color: finance.themeText, fontSize: 24, fontWeight: FontWeight.w900)),
                      Text("ATUR DAFTAR KATEGORI", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ]),
                  ),
                ],
              ),
            ),

            // --- TAB BAR ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: finance.themeCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: finance.themeBorder),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: finance.themeAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: finance.themeAccent.withValues(alpha: 0.5)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: finance.themeAccent,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                unselectedLabelColor: finance.themeTextSub,
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                dividerColor: Colors.transparent,
                onTap: (index) {
                  HapticFeedback.lightImpact();
                  setState(() {});
                },
                tabs: const [
                  Tab(text: "PENGELUARAN"),
                  Tab(text: "PEMASUKAN"),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // --- TAB BAR VIEW ---
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoryList(finance, 'Pengeluaran'),
                  _buildCategoryList(finance, 'Pemasukan'),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
