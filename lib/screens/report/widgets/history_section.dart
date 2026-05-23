// lib/screens/history/history_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';
import 'package:aplikasi_keuangan/core/utils/wallet_logo_resolver.dart';
import 'package:aplikasi_keuangan/shared/widgets/wallet_logo_widget.dart';
import 'package:aplikasi_keuangan/shared/widgets/custom_button.dart';
import 'package:aplikasi_keuangan/shared/bottom_sheets/transaction_detail_sheet.dart';
import 'package:aplikasi_keuangan/screens/transaction/transaction_form_screen.dart';

class HistoryScreen extends StatefulWidget {
  final DateTime? initialFilterDate;
  final String? initialMode; 

  const HistoryScreen({super.key, this.initialFilterDate, this.initialMode});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _activeMode = 'Bulanan'; 
  late DateTime _currentDate;
  DateTimeRange? _selectedDateRange; 

  String _searchQuery = '';
  String _filterJenis = 'Semua';
  String _filterDana = 'Semua';
  String _filterKategori = 'Semua';
  String _filterSort = 'Terbaru';

  bool get _isFilterActive => _filterJenis != 'Semua' || _filterDana != 'Semua' || _filterKategori != 'Semua' || _filterSort != 'Terbaru';

  @override
  void initState() {
    super.initState();
    if (widget.initialFilterDate != null) {
      _activeMode = widget.initialMode ?? 'Harian';
      _currentDate = widget.initialFilterDate!;
    } else {
      _currentDate = DateTime.now();
    }
  }

  Future<void> _pickDateRange(FinanceProvider finance) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: finance.themeAccent,
              onPrimary: Colors.white,
              surface: finance.themeCard,
              onSurface: finance.themeText,
            ),
            dialogTheme: DialogThemeData(backgroundColor: finance.themeBg),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _changeDate(int offset, FinanceProvider finance) {
    if (_activeMode == 'All Time') return;
    if (_activeMode == 'Rentang') {
      _pickDateRange(finance);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() {
      if (_activeMode == 'Harian') {
        _currentDate = _currentDate.add(Duration(days: offset));
      } else if (_activeMode == 'Mingguan') {
        int weekIdx = ((_currentDate.day - 1) / 7).floor();
        int year = _currentDate.year;
        int month = _currentDate.month;
        
        if (offset > 0) {
          weekIdx++;
          int daysInMonth = DateTime(year, month + 1, 0).day;
          if (weekIdx * 7 + 1 > daysInMonth) {
            month++;
            if (month > 12) { month = 1; year++; }
            weekIdx = 0;
          }
        } else if (offset < 0) {
          weekIdx--;
          if (weekIdx < 0) {
            month--;
            if (month < 1) { month = 12; year--; }
            int prevDays = DateTime(year, month + 1, 0).day;
            weekIdx = prevDays >= 29 ? 4 : 3;
          }
        }
        _currentDate = DateTime(year, month, weekIdx * 7 + 1);
      } else if (_activeMode == 'Bulanan') {
        _currentDate = DateTime(_currentDate.year, _currentDate.month + offset, _currentDate.day);
      }
    });
  }

  String get _navLabel {
    if (_activeMode == 'Harian') {
      return DateFormat('dd MMM yyyy').format(_currentDate);
    } else if (_activeMode == 'Mingguan') {
      int weekIdx = ((_currentDate.day - 1) / 7).floor();
      int startDay = weekIdx * 7 + 1;
      int endDay = startDay + 6;
      int daysInMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;
      if (endDay > daysInMonth) endDay = daysInMonth;
      
      DateTime start = DateTime(_currentDate.year, _currentDate.month, startDay);
      DateTime end = DateTime(_currentDate.year, _currentDate.month, endDay);
      return "${start.day} ${Formatters.monthNames[start.month - 1].substring(0,3)} - ${end.day} ${Formatters.monthNames[end.month - 1].substring(0,3)}";
    } else if (_activeMode == 'Bulanan') {
      return "${Formatters.monthNames[_currentDate.month - 1]} ${_currentDate.year}";
    } else if (_activeMode == 'All Time') {
      return "Semua Waktu"; 
    } else if (_activeMode == 'Rentang') {
      if (_selectedDateRange == null) return "Pilih Rentang";
      return "${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yy').format(_selectedDateRange!.end)}";
    }
    return "";
  }

  List<TransactionModel> _getFilteredTransactions(FinanceProvider finance) {
    List<TransactionModel> result = finance.myTransaksi;

    result = result.where((t) {
      DateTime dt = DateTime.parse(t.tanggal);
      if (_activeMode == 'Harian') {
        return dt.year == _currentDate.year && dt.month == _currentDate.month && dt.day == _currentDate.day;
      } else if (_activeMode == 'Mingguan') {
        int weekIdx = ((_currentDate.day - 1) / 7).floor();
        int startDay = weekIdx * 7 + 1;
        int endDay = startDay + 6;
        int daysInMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0).day;
        if (endDay > daysInMonth) endDay = daysInMonth;

        DateTime start = DateTime(_currentDate.year, _currentDate.month, startDay);
        DateTime end = DateTime(_currentDate.year, _currentDate.month, endDay, 23, 59, 59);
        return dt.isAfter(start.subtract(const Duration(seconds: 1))) && dt.isBefore(end);
      } else if (_activeMode == 'Bulanan') {
        return dt.year == _currentDate.year && dt.month == _currentDate.month;
      } else if (_activeMode == 'Rentang') {
        if (_selectedDateRange == null) return true;
        DateTime endOfPeriod = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day, 23, 59, 59);
        return dt.isAfter(_selectedDateRange!.start.subtract(const Duration(seconds: 1))) && dt.isBefore(endOfPeriod);
      }
      return true; 
    }).toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((t) => t.keterangan.toLowerCase().contains(query) || t.kategori.toLowerCase().contains(query)).toList();
    }

    if (_filterJenis != 'Semua') result = result.where((t) => t.jenis == _filterJenis).toList();
    if (_filterDana != 'Semua') result = result.where((t) => t.walletId == _filterDana).toList();
    if (_filterKategori != 'Semua') result = result.where((t) => t.kategori == _filterKategori).toList();

    return result;
  }

  List<MapEntry<String, List<TransactionModel>>> _getGroupedHistory(List<TransactionModel> filteredTxs) {
    Map<String, List<TransactionModel>> groups = {};
    for (var tx in filteredTxs) {
      String dateKey = DateFormat('yyyy-MM-dd').format(DateTime.parse(tx.tanggal));
      groups.putIfAbsent(dateKey, () => []).add(tx);
    }

    List<MapEntry<String, List<TransactionModel>>> sortedGroups = groups.entries.toList();
    
    if (_filterSort == 'Terlama') {
      sortedGroups.sort((a, b) => a.key.compareTo(b.key));
      for (var group in sortedGroups) { group.value.sort((a, b) => DateTime.parse(a.tanggal).compareTo(DateTime.parse(b.tanggal))); }
    } else {
      sortedGroups.sort((a, b) => b.key.compareTo(a.key));
      for (var group in sortedGroups) { group.value.sort((a, b) => DateTime.parse(b.tanggal).compareTo(DateTime.parse(a.tanggal))); }
    }

    return sortedGroups;
  }

  void _openFilterModal(FinanceProvider finance) {
    HapticFeedback.mediumImpact();
    String tempJenis = _filterJenis; String tempDana = _filterDana; String tempKategori = _filterKategori; String tempSort = _filterSort;

    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.6, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: finance.themeBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), border: Border(top: BorderSide(color: finance.themeBorder))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Filter Transaksi", style: TextStyle(color: finance.themeText, fontSize: 18, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 24),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("JENIS TRANSAKSI", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: ['Semua', 'Pengeluaran', 'Pemasukan', 'Transfer'].map((j) {
                              bool isActive = tempJenis == j;
                              return GestureDetector(
                                onTap: () { 
                                  HapticFeedback.lightImpact(); 
                                  setModalState(() {
                                    tempJenis = j; 
                                    if (j == 'Semua' || j == 'Transfer') {
                                      tempKategori = 'Semua';
                                    } else if (j == 'Pengeluaran') {
                                      if (!finance.expenseCategories.any((c) => c.name == tempKategori)) tempKategori = 'Semua';
                                    } else if (j == 'Pemasukan') {
                                      if (!finance.incomeCategories.any((c) => c.name == tempKategori)) tempKategori = 'Semua';
                                    }
                                  }); 
                                },
                                child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: isActive ? finance.themeAccent : finance.themeCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: isActive ? finance.themeAccent : finance.themeBorder)), child: Row(mainAxisSize: MainAxisSize.min, children: [if (isActive) const Padding(padding: EdgeInsets.only(right: 6), child: Icon(Icons.check_rounded, color: Colors.white, size: 14)), Text(j, style: TextStyle(color: isActive ? Colors.white : finance.themeTextSub, fontSize: 12, fontWeight: FontWeight.bold))])),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 24),

                          if (tempJenis == 'Pengeluaran' || tempJenis == 'Pemasukan') ...[
                            Text("KATEGORI", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: [
                                GestureDetector(
                                  onTap: () { HapticFeedback.lightImpact(); setModalState(() => tempKategori = 'Semua'); }, 
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
                                    decoration: BoxDecoration(color: tempKategori == 'Semua' ? finance.themeAccent : finance.themeCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: tempKategori == 'Semua' ? finance.themeAccent : finance.themeBorder)), 
                                    child: Text("Semua", style: TextStyle(color: tempKategori == 'Semua' ? Colors.white : finance.themeTextSub, fontSize: 12, fontWeight: FontWeight.bold))
                                  )
                                ),
                                ...(tempJenis == 'Pengeluaran' ? finance.expenseCategories : finance.incomeCategories).map((kat) {
                                  bool isActive = tempKategori == kat.name;
                                  return GestureDetector(
                                    onTap: () { HapticFeedback.lightImpact(); setModalState(() => tempKategori = kat.name); }, 
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), 
                                      decoration: BoxDecoration(color: isActive ? finance.themeAccent : finance.themeCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: isActive ? finance.themeAccent : finance.themeBorder)), 
                                      child: Text(kat.name, style: TextStyle(color: isActive ? Colors.white : finance.themeTextSub, fontSize: 12, fontWeight: FontWeight.bold))
                                    )
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 24),
                          ],

                          Text("SUMBER DANA", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: [
                              GestureDetector(onTap: () { HapticFeedback.lightImpact(); setModalState(() => tempDana = 'Semua'); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: tempDana == 'Semua' ? finance.themeAccent : finance.themeCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: tempDana == 'Semua' ? finance.themeAccent : finance.themeBorder)), child: Text("Semua", style: TextStyle(color: tempDana == 'Semua' ? Colors.white : finance.themeTextSub, fontSize: 12, fontWeight: FontWeight.bold)))),
                              ...finance.myWallets.map((d) {
                                bool isActive = tempDana == d.walletId;
                                return GestureDetector(onTap: () { HapticFeedback.lightImpact(); setModalState(() => tempDana = d.walletId); }, child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: isActive ? finance.themeAccent : finance.themeCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: isActive ? finance.themeAccent : finance.themeBorder)), child: Text(d.walletName, style: TextStyle(color: isActive ? Colors.white : finance.themeTextSub, fontSize: 12, fontWeight: FontWeight.bold))));
                              }),
                            ],
                          ),
                          const SizedBox(height: 24),

                          Text("URUTKAN", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: finance.themeBorder)),
                            child: Row(children: ['Terbaru', 'Terlama'].map((s) {
                              bool isActive = tempSort == s;
                              return Expanded(child: GestureDetector(onTap: () { HapticFeedback.lightImpact(); setModalState(() => tempSort = s); }, child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isActive ? finance.themeAccent.withValues(alpha:0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: isActive ? finance.themeAccent.withValues(alpha:0.05) : Colors.transparent)), alignment: Alignment.center, child: Row(mainAxisSize: MainAxisSize.min, children: [if (isActive) Padding(padding: const EdgeInsets.only(right: 6), child: Icon(Icons.check_rounded, color: finance.themeAccent, size: 16)), Text(s, style: TextStyle(color: isActive ? finance.themeText : finance.themeTextSub, fontSize: 12, fontWeight: FontWeight.bold))]))));
                            }).toList()),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Row(
                      children: [
                        Expanded(flex: 1, child: CustomButton(text: "Reset", variant: ButtonVariant.secondary, onPressed: () { HapticFeedback.lightImpact(); setModalState(() { tempJenis = 'Semua'; tempDana = 'Semua'; tempKategori = 'Semua'; tempSort = 'Terbaru'; }); })),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: CustomButton(text: "Terapkan", variant: ButtonVariant.primary, onPressed: () { HapticFeedback.heavyImpact(); setState(() { _filterJenis = tempJenis; _filterDana = tempDana; _filterKategori = tempKategori; _filterSort = tempSort; }); Navigator.pop(context); })),
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
    final filteredTxs = _getFilteredTransactions(finance);
    final groupedData = _getGroupedHistory(filteredTxs);

    double totalExp = filteredTxs.where((t) => t.jenis == 'Pengeluaran').fold(0, (s, t) => s + t.nominal);
    double totalInc = filteredTxs.where((t) => t.jenis == 'Pemasukan').fold(0, (s, t) => s + t.nominal);

    bool disableArrows = _activeMode == 'All Time';

    return Scaffold(
      backgroundColor: finance.themeBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                    child: Icon(Icons.arrow_back_rounded, color: finance.themeText, size: 28),
                  ),
                  const SizedBox(width: 16),
                  Text("Transaction", style: TextStyle(color: finance.themeText, fontSize: 22, fontWeight: FontWeight.w900)),
                ],
              ),
            ),

            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: finance.themeBorder)),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _activeMode,
                                      icon: Padding(padding: const EdgeInsets.only(left: 4), child: Icon(Icons.keyboard_arrow_down_rounded, color: finance.themeTextSub, size: 16)),
                                      dropdownColor: finance.themeCard,
                                      style: TextStyle(color: finance.themeText, fontSize: 13, fontWeight: FontWeight.bold),
                                      items: ['Harian', 'Mingguan', 'Bulanan', 'All Time', 'Rentang'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          HapticFeedback.lightImpact();
                                          setState(() {
                                            _activeMode = val;
                                          });
                                          if (val == 'Rentang') {
                                            _pickDateRange(finance);
                                          }
                                        }
                                      }
                                    ),
                                  ),
                                ),
                              ),
                              
                              const SizedBox(width: 12),

                              Expanded(
                                child: Container(
                                  height: 48, 
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: finance.themeBorder)),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      GestureDetector(
                                        onTap: disableArrows ? null : () => _changeDate(-1, finance), 
                                        child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.chevron_left_rounded, color: disableArrows ? finance.themeTextSub.withValues(alpha:0.3) : finance.themeText, size: 18))
                                      ),
                                      GestureDetector(
                                        onTap: _activeMode == 'Rentang' ? () => _pickDateRange(finance) : null,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(_navLabel, style: TextStyle(color: finance.themeText, fontSize: 12, fontWeight: FontWeight.bold)),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: disableArrows ? null : () => _changeDate(1, finance), 
                                        child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.chevron_right_rounded, color: disableArrows ? finance.themeTextSub.withValues(alpha:0.3) : finance.themeText, size: 18))
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: finance.themeBorder)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [Icon(Icons.arrow_upward_rounded, size: 12, color: Colors.redAccent), const SizedBox(width: 4), Text("Keluar", style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold))]),
                                      const SizedBox(height: 8),
                                      FittedBox(fit: BoxFit.scaleDown, child: Text(Formatters.formatCurrency(totalExp), style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w900))),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: finance.themeBorder)),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [Icon(Icons.arrow_downward_rounded, size: 12, color: Colors.greenAccent), const SizedBox(width: 4), Text("Masuk", style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold))]),
                                      const SizedBox(height: 8),
                                      FittedBox(fit: BoxFit.scaleDown, child: Text(Formatters.formatCurrency(totalInc), style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.w900))),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  onChanged: (val) => setState(() => _searchQuery = val),
                                  style: TextStyle(color: finance.themeText, fontSize: 14, fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    filled: true, fillColor: finance.themeCard, 
                                    hintText: "Cari transaksi...", hintStyle: TextStyle(color: finance.themeTextSub.withValues(alpha:0.5)),
                                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                    prefixIcon: Icon(Icons.search_rounded, color: finance.themeTextSub, size: 20),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => _openFilterModal(finance),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(color: _isFilterActive ? finance.themeAccent.withValues(alpha:0.1) : finance.themeCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: _isFilterActive ? finance.themeAccent : Colors.transparent)),
                                  child: Row(
                                    children: [
                                      Icon(Icons.filter_list_rounded, color: _isFilterActive ? finance.themeAccent : finance.themeTextSub, size: 20),
                                      const SizedBox(width: 6),
                                      Text("Filter", style: TextStyle(color: _isFilterActive ? finance.themeAccent : finance.themeTextSub, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          if (groupedData.isEmpty)
                            Container(
                              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                              decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: finance.themeBorder, style: BorderStyle.solid)),
                              child: Column(
                                children: [
                                  Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: finance.themeBg, shape: BoxShape.circle), child: Icon(Icons.receipt_long_rounded, color: finance.themeTextSub, size: 32)),
                                  const SizedBox(height: 16),
                                  Text("Gak ada riwayat jajan", style: TextStyle(color: finance.themeText, fontSize: 16, fontWeight: FontWeight.w900)),
                                  const SizedBox(height: 8),
                                  Text(_searchQuery.isNotEmpty || _isFilterActive ? "Filter kamu nggak nemu hasil." : "Belum ada transaksi di periode ini.", style: TextStyle(color: finance.themeTextSub, fontSize: 12), textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  if (groupedData.isNotEmpty)
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final group = groupedData[index];
                            String dateStr = group.key;
                            List<TransactionModel> items = group.value;

                            DateTime parsedDate = DateTime.parse(dateStr);
                            String displayDate = "${parsedDate.day} ${Formatters.monthNames[parsedDate.month - 1]} ${parsedDate.year}";

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: Text(displayDate.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: finance.themeTextSub, letterSpacing: 1.5)),
                                  ),

                                  // 🟢 FIX LIST ITEM: DISAMAIN SAMA DASHBOARD!
                                  ...items.map((tx) {
                                    final dompet = finance.myWallets.firstWhere((d) => d.walletId == tx.walletId, orElse: () => finance.myWallets.first);
                                    String dompetName = dompet.walletName;

                                    bool isIncome = tx.jenis == 'Pemasukan';
                                    bool isTransfer = tx.jenis == 'Transfer';

                                    final katModel = finance.getCategoryByName(tx.kategori);

                                    Color iconColor = katModel.accentColor;
                                    Color iconBg = katModel.bgColor;
                                    IconData iconData = katModel.icon;
                                    String prefix = isIncome ? '+' : '-';

                                    if (isTransfer) {
                                      iconColor = finance.themeAccent;
                                      iconBg = finance.themeAccent.withValues(alpha:0.2);
                                      iconData = Icons.sync_alt_rounded;
                                      prefix = '-';
                                    }

                                    String displayKet = tx.keterangan.isEmpty ? 'Tanpa Keterangan' : tx.keterangan;
                                    if (isTransfer && displayKet.toLowerCase() == 'pemasukan') displayKet = 'Pindah Saldo';

                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 12),
                                      child: GestureDetector(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          TransactionDetailSheet.show(
                                            context: context, transaction: tx, sumberDana: finance.myWallets,
                                            onEdit: (selectedTx) { Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionFormScreen(initialData: selectedTx))); },
                                            onDelete: (selectedTx) {
                                              finance.deleteTransaksi(selectedTx.idTransaksi);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Transaksi berhasil dihapus'),
                                                  backgroundColor: Colors.green,
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            },
                                          );
                                        },
                                        child: Container( 
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: finance.themeBorder)),
                                          child: Row(
                                            children: [
                                              Container(width: 48, height: 48, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: iconColor.withValues(alpha:0.2))), child: Icon(iconData, color: iconColor, size: 24)),
                                              const SizedBox(width: 16),
                                              
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text((tx.kategori.isEmpty ? tx.jenis : tx.kategori).toUpperCase(), style: TextStyle(color: finance.themeText, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                                                    const SizedBox(height: 4),
                                                    Text(displayKet, style: TextStyle(color: finance.themeTextSub, fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                                  ],
                                                ),
                                              ),
                                              
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  Text("$prefix${Formatters.formatCurrency(tx.nominal)}", style: TextStyle(color: isIncome ? Colors.greenAccent : (isTransfer ? finance.themeAccent : finance.themeText), fontWeight: FontWeight.w900, fontSize: 14)),
                                                  const SizedBox(height: 6),
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      WalletLogoWidget(walletName: dompetName, size: 'sm'),
                                                      if (!WalletLogoResolver.hasLogo(dompetName)) const SizedBox(width: 4),
                                                      if (!WalletLogoResolver.hasLogo(dompetName)) Text(dompetName, style: TextStyle(color: finance.themeTextSub, fontWeight: FontWeight.bold, fontSize: 10)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            );
                          },
                          childCount: groupedData.length,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionFormScreen()));
        },
        backgroundColor: finance.themeAccent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }
}