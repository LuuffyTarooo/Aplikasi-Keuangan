// lib/screens/dashboard/budget/budget_tracker_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/shared/widgets/glass_card.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';
import 'package:aplikasi_keuangan/models/category_model.dart'; 

class BudgetTrackerScreen extends StatefulWidget {
  const BudgetTrackerScreen({super.key});

  @override
  State<BudgetTrackerScreen> createState() => _BudgetTrackerScreenState();
}

class _BudgetTrackerScreenState extends State<BudgetTrackerScreen> {
  DateTime _currentDate = DateTime.now();
  final List<String> _monthNames = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('makan') || name.contains('minum') || name.contains('jajan') || name.contains('kopi')) return Icons.coffee_rounded;
    if (name.contains('transport') || name.contains('bensin') || name.contains('ojek') || name.contains('mobil')) return Icons.directions_car_rounded;
    if (name.contains('belanja') || name.contains('baju') || name.contains('skincare')) return Icons.shopping_bag_rounded;
    if (name.contains('olahraga') || name.contains('gym')) return Icons.fitness_center_rounded;
    if (name.contains('sehat') || name.contains('obat') || name.contains('dokter')) return Icons.local_hospital_rounded;
    if (name.contains('hiburan') || name.contains('game') || name.contains('nonton')) return Icons.sports_esports_rounded;
    if (name.contains('tagihan') || name.contains('listrik') || name.contains('air')) return Icons.electric_bolt_rounded;
    if (name.contains('donasi') || name.contains('sedekah') || name.contains('amal')) return Icons.favorite_rounded;
    return Icons.track_changes_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final year = _currentDate.year;
    final month = _currentDate.month;

    final currentMonthExpenses = finance.myTransaksi.where((t) {
      final txDate = DateTime.parse(t.tanggal);
      return txDate.month == month && txDate.year == year && t.jenis == 'Pengeluaran';
    }).toList();

    final double globalBudgetLimit = finance.myBudget?.limitBulanan ?? 0; 
    final Map<String, double> catLimits = finance.myBudget?.categoryLimits ?? {};

    final double totalTerpakai = currentMonthExpenses.fold(0, (sum, item) => sum + item.nominal);
    final double sisaAnggaran = globalBudgetLimit - totalTerpakai;
    final double globalPercentage = globalBudgetLimit > 0 ? (totalTerpakai / globalBudgetLimit * 100).clamp(0, 100) : 0;

    final now = DateTime.now();
    final isCurrentMonth = now.month == month && now.year == year;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final currentDay = isCurrentMonth ? now.day : daysInMonth;
    final sisaHari = isCurrentMonth ? daysInMonth - currentDay + 1 : 0;
    final double dailySafeLimit = (sisaHari > 0 && sisaAnggaran > 0) ? ((sisaAnggaran / sisaHari) / 100).floor() * 100 : 0;

    List<String> alerts = [];
    if (globalBudgetLimit > 0 && isCurrentMonth && currentDay > 3 && totalTerpakai > 0) {
      final timeElapsedPercent = (currentDay / daysInMonth) * 100;
      if (globalPercentage > timeElapsedPercent + 15) {
        final avgDailySpend = totalTerpakai / currentDay;
        final estimatedDaysLeft = (sisaAnggaran / avgDailySpend).floor();
        if (estimatedDaysLeft < sisaHari && estimatedDaysLeft > 0) {
          alerts.add("⚠️ Jar, lu boros banget! Anggaran sebulan lu diprediksi abis dalam $estimatedDaysLeft hari lagi kalau gaya jajan lu begini terus.");
        }
      }
    }
    if (sisaAnggaran < 0 && globalBudgetLimit > 0) {
      alerts.add("URGENT: Total pengeluaran bulan ini overbudget ${Formatters.formatCurrency(sisaAnggaran.abs())}!");
    }

    return Scaffold(
      backgroundColor: finance.themeBg, // 🟢 AUTO-SYNC: Solid warna ala GoPay
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120, top: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Anggaran", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: finance.themeText)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(30), border: Border.all(color: finance.themeBorder)),
                      child: Row(
                        children: [
                          IconButton(icon: Icon(Icons.chevron_left, size: 18, color: finance.themeTextSub), onPressed: () { HapticFeedback.lightImpact(); setState(() => _currentDate = DateTime(year, month - 1, 1)); }),
                          Text("${_monthNames[month - 1].substring(0, 3).toUpperCase()} $year", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: finance.themeText, letterSpacing: 1.5)),
                          IconButton(icon: Icon(Icons.chevron_right, size: 18, color: finance.themeTextSub), onPressed: () { HapticFeedback.lightImpact(); setState(() => _currentDate = DateTime(year, month + 1, 1)); }),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (globalBudgetLimit == 0)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(32), border: Border.all(color: finance.themeBorder)),
                    child: Column(
                      children: [
                        Container(width: 70, height: 70, decoration: BoxDecoration(color: finance.themeBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: finance.themeBorder)), child: Icon(Icons.track_changes_rounded, size: 36, color: finance.themeAccent)),
                        const SizedBox(height: 20),
                        Text("Mulai Perjalanan\nFinansialmu!", textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: finance.themeText, height: 1.2)),
                        const SizedBox(height: 12),
                        Text("Atur batas uang yang boleh kamu habiskan bulan ini biar keuanganmu nggak boncos.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: finance.themeTextSub, height: 1.5)),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: finance.themeAccent, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                          icon: const Icon(Icons.account_balance_wallet_rounded), label: const Text("Atur Budget Bulanan", style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => _showGlobalBudgetSheet(context, finance, globalBudgetLimit),
                        ),
                      ],
                    ),
                  )
                else ...[
                  GlassCard( // Otomatis sync dari glass_card lu
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("SISA ANGGARAN GLOBAL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: finance.themeTextSub, letterSpacing: 2)),
                            if (isCurrentMonth)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), 
                                decoration: BoxDecoration(color: finance.themeAccent.withValues(alpha: 0.1), border: Border.all(color: finance.themeAccent.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(20)), 
                                child: Text("$sisaHari HARI LAGI", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: finance.themeAccent))
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: Text(Formatters.formatCurrency(sisaAnggaran), style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: sisaAnggaran < 0 ? Colors.redAccent : finance.themeText))),
                            IconButton(icon: Icon(Icons.edit_note_rounded, color: finance.themeTextSub), onPressed: () => _showGlobalBudgetSheet(context, finance, globalBudgetLimit))
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Terpakai ${Formatters.formatCurrency(totalTerpakai)}", style: TextStyle(fontSize: 11, color: finance.themeTextSub)),
                            Text("Dari ${Formatters.formatCurrency(globalBudgetLimit)}", style: TextStyle(fontSize: 11, color: finance.themeTextSub)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(value: globalPercentage / 100, minHeight: 8, backgroundColor: finance.themeBorder, valueColor: AlwaysStoppedAnimation<Color>(globalPercentage >= 90 ? Colors.red : (globalPercentage >= 75 ? Colors.orange : finance.themeAccent))),
                        ),
                        const SizedBox(height: 20),
                        if (isCurrentMonth)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: finance.themeBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: finance.themeBorder)),
                            child: Row(
                              children: [
                                Icon(Icons.trending_down_rounded, color: sisaAnggaran > 0 ? Colors.greenAccent : Colors.redAccent),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("BATAS AMAN HARIAN", style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: finance.themeTextSub, letterSpacing: 1)),
                                    Text(sisaAnggaran > 0 ? "${Formatters.formatCurrency(dailySafeLimit)} / hari" : "Udah minus bos, ngerem!", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: finance.themeText)),
                                  ],
                                )
                              ],
                            ),
                          )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (alerts.isNotEmpty)
                    ...alerts.map((msg) => Container(
                          margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: msg.contains('URGENT') ? Colors.red.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: msg.contains('URGENT') ? Colors.red.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3))),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(msg.contains('URGENT') ? Icons.error_outline : Icons.warning_amber_rounded, color: msg.contains('URGENT') ? Colors.redAccent : Colors.orangeAccent, size: 18),
                              const SizedBox(width: 10),
                              Expanded(child: Text(msg.replaceAll('URGENT: ', ''), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: msg.contains('URGENT') ? Colors.redAccent : Colors.orangeAccent, height: 1.4))),
                            ],
                          ),
                        )),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Anggaran Kategori", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: finance.themeText)),
                      TextButton.icon(
                        icon: Icon(Icons.add, size: 16, color: finance.themeAccent),
                        label: Text("Tambah", style: TextStyle(color: finance.themeAccent, fontWeight: FontWeight.bold)),
                        onPressed: () => _showCategoryBudgetSheet(context, finance, catLimits, null),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (catLimits.isEmpty)
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: finance.themeBorder, style: BorderStyle.solid)),
                      child: Column(
                        children: [
                          Text("Belum Ada Budget Kategori", style: TextStyle(fontWeight: FontWeight.bold, color: finance.themeTextSub)),
                          const SizedBox(height: 4),
                          Text("Pisahin budget buat Jajan, Transport, dll biar terarah.", style: TextStyle(fontSize: 11, color: finance.themeTextSub)),
                          const SizedBox(height: 16),
                          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: finance.themeBg, foregroundColor: finance.themeText), onPressed: () => _showCategoryBudgetSheet(context, finance, catLimits, null), child: const Text("Buat Anggaran Kategori"))
                        ],
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: finance.themeBorder)),
                      child: ListView.separated(
                        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: catLimits.length,
                        separatorBuilder: (context, index) => Divider(color: finance.themeBorder, height: 1), 
                        itemBuilder: (context, index) {
                          final category = catLimits.keys.elementAt(index);
                          final limit = catLimits[category] ?? 0;

                          final terpakai = currentMonthExpenses.where((t) => t.kategori == category).fold(0.0, (sum, t) => sum + t.nominal);
                          final percentage = limit > 0 ? (terpakai / limit * 100).clamp(0, 100) : 100.0;

                          Color progressColor = Colors.green;
                          if (percentage >= 100) { progressColor = Colors.red; } else if (percentage >= 75) { progressColor = Colors.orange; }

                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(width: 40, height: 40, decoration: BoxDecoration(color: progressColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: progressColor.withValues(alpha: 0.2))), child: Icon(_getCategoryIcon(category), color: progressColor, size: 20)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(category, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: finance.themeText)),
                                          Text("Sisa ${Formatters.formatCurrency(limit - terpakai > 0 ? limit - terpakai : 0)}", style: TextStyle(fontSize: 11, color: progressColor, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(icon: Icon(Icons.edit, size: 16, color: finance.themeTextSub), onPressed: () => _showCategoryBudgetSheet(context, finance, catLimits, category)),
                                        IconButton(icon: const Icon(Icons.delete, size: 16, color: Colors.redAccent), onPressed: () { HapticFeedback.heavyImpact(); final newLimits = Map<String, double>.from(catLimits); newLimits.remove(category); finance.updateCategoryLimits(newLimits); }),
                                      ],
                                    )
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Terpakai ${Formatters.formatCurrency(terpakai)}", style: TextStyle(fontSize: 10, color: finance.themeTextSub)),
                                    Text("${percentage.toStringAsFixed(1)}% / ${Formatters.formatCurrency(limit)}", style: TextStyle(fontSize: 10, color: progressColor, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: percentage / 100, minHeight: 6, backgroundColor: finance.themeBorder, valueColor: AlwaysStoppedAnimation<Color>(progressColor)))
                              ],
                            ),
                          );
                        },
                      ),
                    )
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 🚀 BOTTOM SHEET BUAT NGUBAH BUDGET GLOBAL
  // =========================================================================
  void _showGlobalBudgetSheet(BuildContext context, FinanceProvider finance, double currentLimit) {
    final controller = TextEditingController(text: currentLimit > 0 ? currentLimit.toInt().toString() : "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: finance.themeBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Total Anggaran Bulanan", style: TextStyle(color: finance.themeText, fontSize: 18, fontWeight: FontWeight.w900)),
                  GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: finance.themeCard, shape: BoxShape.circle), child: Icon(Icons.close, color: finance.themeTextSub, size: 20)))
                ],
              ),
              const SizedBox(height: 8),
              Text("Batas aman pengeluaran keseluruhanmu bulan ini.", style: TextStyle(color: finance.themeTextSub, fontSize: 12)),
              const SizedBox(height: 24),
              
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: TextStyle(color: finance.themeText, fontSize: 32, fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: finance.themeCard,
                  hintText: "0",
                  hintStyle: TextStyle(color: finance.themeTextSub.withValues(alpha:0.5)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  prefixIconConstraints: const BoxConstraints(minWidth: 60),
                  prefixIcon: Center(
                    widthFactor: 1.0,
                    child: Text("Rp", style: TextStyle(color: finance.themeTextSub, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: finance.themeBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: finance.themeBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: finance.themeAccent, width: 2)),
                ),
              ),

              const SizedBox(height: 32),
              GestureDetector(
                onTap: () {
                  final val = double.tryParse(controller.text) ?? 0;
                  finance.updateGlobalBudget(val); 
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(color: finance.themeAccent, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: finance.themeAccent.withValues(alpha:0.4), blurRadius: 20)]),
                  alignment: Alignment.center,
                  child: const Text("Simpan Total Anggaran", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 🚀 BOTTOM SHEET BUAT NAMBAHIN BUDGET KATEGORI
  // =========================================================================
  void _showCategoryBudgetSheet(BuildContext context, FinanceProvider finance, Map<String, double> currentLimits, String? editCategory) {
    List<String> allCatNames = [
      'Makan & Minuman', 'Transportasi', 'Belanja', 'Tagihan', 
      'Rumah Tangga', 'Hiburan', 'Kesehatan', 'Pendidikan', 'Peliharaan'
    ];
    allCatNames.addAll(finance.myKategori.where((k) => k.jenis == 'Pengeluaran').map((k) => k.name));
    allCatNames = allCatNames.toSet().toList(); 

    if (editCategory == null) {
      allCatNames.removeWhere((cat) => currentLimits.containsKey(cat));
    }

    String selectedCategory = editCategory ?? (allCatNames.isNotEmpty ? allCatNames.first : "");
    final controller = TextEditingController(text: editCategory != null ? currentLimits[editCategory]?.toInt().toString() : "");
    final customCatController = TextEditingController();
    bool isCustomCategory = false; 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: finance.themeBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(editCategory != null ? "Edit Limit Kategori" : "Tambah Limit Kategori", style: TextStyle(color: finance.themeText, fontSize: 18, fontWeight: FontWeight.w900)),
                      GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: finance.themeCard, shape: BoxShape.circle), child: Icon(Icons.close, color: finance.themeTextSub, size: 20)))
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (editCategory == null) ...[
                    Text("PILIH KATEGORI", style: TextStyle(color: finance.themeTextSub, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                    const SizedBox(height: 12),
                    
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: [
                        ...allCatNames.map((cat) {
                          final isSelected = selectedCategory == cat && !isCustomCategory;
                          return GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              setSheetState(() { selectedCategory = cat; isCustomCategory = false; });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(color: isSelected ? finance.themeAccent.withValues(alpha:0.2) : finance.themeCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? finance.themeAccent : finance.themeBorder)),
                              child: Text(cat, style: TextStyle(color: isSelected ? finance.themeAccent : finance.themeTextSub, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          );
                        }),

                        // 🟢 TOMBOL + KATEGORI CUSTOM
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setSheetState(() { isCustomCategory = true; selectedCategory = ""; });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(color: isCustomCategory ? finance.themeAccent.withValues(alpha:0.2) : Colors.transparent, borderRadius: BorderRadius.circular(20), border: Border.all(color: isCustomCategory ? finance.themeAccent : finance.themeBorder, style: BorderStyle.solid)),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add, size: 14, color: isCustomCategory ? finance.themeAccent : finance.themeTextSub),
                                const SizedBox(width: 4),
                                Text("Buat Custom", style: TextStyle(color: isCustomCategory ? finance.themeAccent : finance.themeTextSub, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (isCustomCategory) ...[
                      TextField(
                        controller: customCatController,
                        autofocus: true,
                        style: TextStyle(color: finance.themeText, fontSize: 14, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: finance.themeCard,
                          hintText: "Ketik nama kategori baru...",
                          hintStyle: TextStyle(color: finance.themeTextSub.withValues(alpha:0.5)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: finance.themeBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: finance.themeBorder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: finance.themeAccent)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ] else ...[
                    Text("KATEGORI", style: TextStyle(color: finance.themeTextSub, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(_getCategoryIcon(selectedCategory), color: finance.themeAccent, size: 24),
                        const SizedBox(width: 12),
                        Text(selectedCategory, style: TextStyle(color: finance.themeText, fontSize: 20, fontWeight: FontWeight.w900)),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  Text("BATAS MAKSIMAL (Rp)", style: TextStyle(color: finance.themeTextSub, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: controller,
                    autofocus: editCategory != null,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: finance.themeText, fontSize: 32, fontWeight: FontWeight.w900),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: finance.themeCard,
                      hintText: "0",
                      hintStyle: TextStyle(color: finance.themeTextSub.withValues(alpha:0.5)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      prefixIconConstraints: const BoxConstraints(minWidth: 60),
                      prefixIcon: Center(
                        widthFactor: 1.0,
                        child: Text("Rp", style: TextStyle(color: finance.themeTextSub, fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: finance.themeBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: finance.themeBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: finance.themeAccent, width: 2)),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  GestureDetector(
                    onTap: () {
                      String finalCat = isCustomCategory ? customCatController.text.trim() : selectedCategory;
                      if (finalCat.isEmpty) return; 

                      final val = double.tryParse(controller.text) ?? 0;

                      bool catExists = finance.allKategori.any((k) => k.name.toLowerCase() == finalCat.toLowerCase() && k.jenis == 'Pengeluaran');
                      if (!catExists) {
                        finance.allKategori.add(CategoryModel(
                          id: 'k_${DateTime.now().millisecondsSinceEpoch}',
                          name: finalCat,
                          jenis: 'Pengeluaran',
                          userId: finance.currentUser?.id ?? '',
                        ));
                        finance.switchUser(finance.currentUser!.id); 
                      }

                      final newLimits = Map<String, double>.from(currentLimits);
                      newLimits[finalCat] = val;
                      finance.updateCategoryLimits(newLimits); 
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        color: finance.themeAccent, 
                        borderRadius: BorderRadius.circular(24), 
                        boxShadow: [BoxShadow(color: finance.themeAccent.withValues(alpha:0.4), blurRadius: 20)]
                      ),
                      alignment: Alignment.center,
                      child: const Text("Simpan Anggaran", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          );
        }
      ),
    );
  }
}