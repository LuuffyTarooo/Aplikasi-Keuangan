// lib/screens/report/widgets/history_section.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';
import 'package:aplikasi_keuangan/core/utils/wallet_helper.dart';
import 'package:aplikasi_keuangan/shared/widgets/custom_button.dart';
import 'package:aplikasi_keuangan/shared/bottom_sheets/transaction_detail_sheet.dart';
import 'package:aplikasi_keuangan/screens/transaction/transaction_form_screen.dart';

class HistorySection extends StatefulWidget {
  final List<TransactionModel> transaksi;

  const HistorySection({super.key, required this.transaksi});

  @override
  State<HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<HistorySection> {
  String _searchQuery = '';
  
  // State Filter Utama
  String _filterJenis = 'Semua';
  String _filterDana = 'Semua';
  String _filterSort = 'Terbaru';
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  bool get _isFilterActive => _filterJenis != 'Semua' || _filterDana != 'Semua' || _filterSort != 'Terbaru' || _filterStartDate != null || _filterEndDate != null;

  // 🟢 LOGIKA MANUAL BIAR GA CRASH LOCALE DATA EXCEPTION
  String _getCustomLongDate(String dateKey) {
    try {
      final parsedDate = DateTime.parse(dateKey);
      final List<String> months = [
        'JANUARI', 'FEBRUARI', 'MARET', 'APRIL', 'MEI', 'JUNI',
        'JULI', 'AGUSTUS', 'SEPTEMBER', 'OKTOBER', 'NOVEMBER', 'DESEMBER'
      ];
      return "${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}";
    } catch (_) {
      return dateKey;
    }
  }

  // --- LOGIKA FILTER & PENCARIAN ---
  List<TransactionModel> get _filteredTransactions {
    List<TransactionModel> result = widget.transaksi;

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((t) => t.keterangan.toLowerCase().contains(query) || t.kategori.toLowerCase().contains(query)).toList();
    }

    if (_filterJenis != 'Semua') {
      result = result.where((t) => t.jenis == _filterJenis).toList();
    }

    if (_filterDana != 'Semua') {
      result = result.where((t) => t.idDana == _filterDana).toList();
    }

    if (_filterStartDate != null) {
      result = result.where((t) => DateTime.parse(t.tanggal).isAfter(_filterStartDate!.subtract(const Duration(days: 1)))).toList();
    }
    if (_filterEndDate != null) {
      result = result.where((t) => DateTime.parse(t.tanggal).isBefore(_filterEndDate!.add(const Duration(days: 1)))).toList();
    }

    return result;
  }

  // --- LOGIKA GROUPING (Pemisah Hari) ---
  List<MapEntry<String, List<TransactionModel>>> get _groupedHistory {
    Map<String, List<TransactionModel>> groups = {};
    for (var tx in _filteredTransactions) {
      String dateKey = DateFormat('yyyy-MM-dd').format(DateTime.parse(tx.tanggal));
      groups.putIfAbsent(dateKey, () => []).add(tx);
    }

    List<MapEntry<String, List<TransactionModel>>> sortedGroups = groups.entries.toList();
    
    if (_filterSort == 'Terlama') {
      sortedGroups.sort((a, b) => a.key.compareTo(b.key));
      for (var group in sortedGroups) {
        group.value.sort((a, b) => DateTime.parse(a.tanggal).compareTo(DateTime.parse(b.tanggal)));
      }
    } else {
      sortedGroups.sort((a, b) => b.key.compareTo(a.key));
      for (var group in sortedGroups) {
        group.value.sort((a, b) => DateTime.parse(b.tanggal).compareTo(DateTime.parse(a.tanggal)));
      }
    }

    return sortedGroups;
  }

  // --- MODAL SUPER FILTER ---
  void _openFilterModal(FinanceProvider finance) {
    HapticFeedback.mediumImpact();
    
    String tempJenis = _filterJenis;
    String tempDana = _filterDana;
    String tempSort = _filterSort;
    DateTime? tempStart = _filterStartDate;
    DateTime? tempEnd = _filterEndDate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Color(0xFF161B22), borderRadius: BorderRadius.vertical(top: Radius.circular(32)), border: Border(top: BorderSide(color: Colors.white10))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Filter Riwayat", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 24),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("JENIS TRANSAKSI", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: ['Semua', 'Pengeluaran', 'Pemasukan', 'Transfer'].map((j) {
                              bool isActive = tempJenis == j;
                              return GestureDetector(
                                onTap: () { HapticFeedback.lightImpact(); setModalState(() => tempJenis = j); },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(color: isActive ? const Color(0xFF9333EA) : Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: isActive ? const Color(0xFFA855F7).withValues(alpha:0.5) : Colors.white10), boxShadow: isActive ? [BoxShadow(color: const Color(0xFF9333EA).withValues(alpha:0.4), blurRadius: 10)] : null),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isActive) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.check_rounded, color: Colors.white, size: 14)),
                                      Text(j, style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          const Text("SUMBER DANA", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: [
                              GestureDetector(
                                onTap: () { HapticFeedback.lightImpact(); setModalState(() => tempDana = 'Semua'); },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(color: tempDana == 'Semua' ? const Color(0xFF9333EA) : Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: tempDana == 'Semua' ? const Color(0xFFA855F7).withValues(alpha:0.5) : Colors.white10)),
                                  child: Text("Semua", style: TextStyle(color: tempDana == 'Semua' ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              ...finance.mySumberDana.map((d) {
                                bool isActive = tempDana == d.idDana;
                                return GestureDetector(
                                  onTap: () { HapticFeedback.lightImpact(); setModalState(() => tempDana = d.idDana); },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(color: isActive ? const Color(0xFF9333EA) : Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: isActive ? const Color(0xFFA855F7).withValues(alpha:0.5) : Colors.white10)),
                                    child: Text(d.namaAset, style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 24),

                          const Text("URUTKAN TANGGAL", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                            child: Row(
                              children: ['Terbaru', 'Terlama'].map((s) {
                                bool isActive = tempSort == s;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () { HapticFeedback.lightImpact(); setModalState(() => tempSort = s); },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(color: isActive ? Colors.white.withValues(alpha:0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: isActive ? Colors.white.withValues(alpha:0.05) : Colors.transparent)),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isActive) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.check_rounded, color: Color(0xFFA855F7), size: 16)),
                                          Text(s, style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Text("RENTANG WAKTU", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final picked = await showDatePicker(context: context, initialDate: tempStart ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101));
                                    if (picked != null) setModalState(() => tempStart = picked);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Dari Tanggal", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(tempStart != null ? DateFormat('dd MMM yyyy').format(tempStart!) : "-", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final picked = await showDatePicker(context: context, initialDate: tempEnd ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101));
                                    if (picked != null) setModalState(() => tempEnd = picked);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text("Sampai Tanggal", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(tempEnd != null ? DateFormat('dd MMM yyyy').format(tempEnd!) : "-", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: CustomButton(
                            text: "Reset",
                            variant: ButtonVariant.secondary,
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              setModalState(() {
                                tempJenis = 'Semua'; tempDana = 'Semua'; tempSort = 'Terbaru'; tempStart = null; tempEnd = null;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: CustomButton(
                            text: "Terapkan Filter",
                            variant: ButtonVariant.primary,
                            onPressed: () {
                              HapticFeedback.heavyImpact();
                              setState(() {
                                _filterJenis = tempJenis; _filterDana = tempDana; _filterSort = tempSort; _filterStartDate = tempStart; _filterEndDate = tempEnd;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final groupedData = _groupedHistory;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF0A0514), 
                  hintText: "Cari jajan atau kategori...",
                  hintStyle: const TextStyle(color: Colors.white30),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF9333EA))),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _openFilterModal(finance),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isFilterActive ? const Color(0xFF9333EA).withValues(alpha:0.2) : const Color(0xFF0A0514),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _isFilterActive ? const Color(0xFFA855F7).withValues(alpha:0.5) : Colors.white10),
                  boxShadow: _isFilterActive ? [BoxShadow(color: const Color(0xFFA855F7).withValues(alpha:0.2), blurRadius: 15)] : null,
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.filter_list_rounded, color: _isFilterActive ? const Color(0xFFA855F7) : Colors.white54, size: 22),
                    if (_isFilterActive)
                      Positioned(top: -4, right: -4, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.pinkAccent, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF05010D), width: 2)))),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        if (groupedData.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10, style: BorderStyle.solid)),
            child: Column(
              children: [
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF9333EA).withValues(alpha:0.1), shape: BoxShape.circle), child: const Icon(Icons.receipt_long_rounded, color: Color(0xFFA855F7), size: 32)),
                const SizedBox(height: 16),
                const Text("Gak ada riwayat jajan", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text(
                  _searchQuery.isNotEmpty || _isFilterActive ? "Filter dan pencarian kamu nggak nemu hasil nih Jar. Coba ganti kata kuncinya." : "Belum ada transaksi di periode ini. Saldo aman!",
                  style: const TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Column(
            children: groupedData.map((group) {
              String dateStr = group.key;
              List<TransactionModel> items = group.value;

              double dailyExpense = items.where((t) => t.jenis == 'Pengeluaran').fold(0, (sum, t) => sum + t.nominal);
              bool isToday = dateStr == DateFormat('yyyy-MM-dd').format(DateTime.now());
              
              // 🟢 FIX UTAMA: Pake fungsi manual kustom _getCustomLongDate biar ga crash LocaleDataException!
              String displayDate = isToday ? 'HARI INI' : _getCustomLongDate(dateStr);

              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.only(bottom: 8),
                      margin: const EdgeInsets.only(bottom:12),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(displayDate, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Color(0xFFA855F7), letterSpacing: 1.5)),
                          if (dailyExpense > 0)
                            Text("-${Formatters.formatCurrency(dailyExpense)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.pinkAccent)),
                        ],
                      ),
                    ),

                    ...items.map((tx) {
                      final dompet = finance.mySumberDana.firstWhere((d) => d.idDana == tx.idDana, orElse: () => finance.mySumberDana.first);
                      
                      bool isIncome = tx.jenis == 'Pemasukan';
                      bool isTransfer = tx.jenis == 'Transfer';
                      Color iconColor = isIncome ? Colors.greenAccent : (isTransfer ? const Color(0xFFD946EF) : Colors.pinkAccent);
                      Color amountColor = isIncome ? Colors.greenAccent : Colors.white;
                      String prefix = isIncome ? '+' : '-';
                      String titleText = tx.kategori.isEmpty ? 'Lain-lain' : tx.kategori;
                      String subText = tx.keterangan.isEmpty ? 'Transaksi' : tx.keterangan;

                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          TransactionDetailSheet.show(
                            context: context,
                            transaction: tx,
                            sumberDana: finance.mySumberDana,
                            onEdit: (selectedTx) { Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionFormScreen(initialData: selectedTx))); },
                            onDelete: (selectedTx) { /* finance.handleDeleteTransaksi(selectedTx); */ },
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))), 
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  isIncome ? Icons.south_west_rounded : (isTransfer ? Icons.sync_alt_rounded : Icons.north_east_rounded),
                                  color: iconColor,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      titleText.toUpperCase(), 
                                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900), 
                                      maxLines: 1, overflow: TextOverflow.ellipsis
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      subText, 
                                      style: const TextStyle(color: Colors.white54, fontSize: 11),
                                      maxLines: 1, overflow: TextOverflow.ellipsis
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "$prefix${Formatters.formatCurrency(tx.nominal)}", 
                                    style: TextStyle(color: amountColor, fontSize: 13, fontWeight: FontWeight.w900)
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(width: 18, height: 18, child: WalletHelper.getWalletLogo(dompet.namaAset, size: 'sm')),
                                      const SizedBox(width: 6),
                                      Text(dompet.namaAset, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}