// lib/screens/report/widgets/calendar_pnl.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';
import 'package:aplikasi_keuangan/screens/report/widgets/history_section.dart';

class CalendarPnlSection extends StatefulWidget {
  final List<TransactionModel> transaksi;
  final DateTime currentDate;
  final Function(DateTime) onDateChange;

  const CalendarPnlSection({
    super.key,
    required this.transaksi,
    required this.currentDate,
    required this.onDateChange,
  });

  @override
  State<CalendarPnlSection> createState() => _CalendarPnlSectionState();
}

class _CalendarPnlSectionState extends State<CalendarPnlSection> {
  int? _selectedDate;
  String _activeToggle = 'Daily'; 

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().day; 
  }

  @override
  void didUpdateWidget(CalendarPnlSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDate != widget.currentDate) {
      _selectedDate = null;
    }
  }

  void _changeDate(DateTime newDate) {
    HapticFeedback.lightImpact();
    widget.onDateChange(newDate);
    setState(() {
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final year = widget.currentDate.year;
    final month = widget.currentDate.month;

    final currentMonthTxs = widget.transaksi.where((t) {
      final txDate = DateTime.parse(t.tanggal);
      return txDate.month == month && txDate.year == year;
    }).toList();

    final currentYearTxs = widget.transaksi.where((t) {
      return DateTime.parse(t.tanggal).year == year;
    }).toList();
    
    // 1. STATS HARIAN
    Map<int, Map<String, double>> dailyStats = {};
    for (var tx in currentMonthTxs) {
      int day = DateTime.parse(tx.tanggal).day;
      dailyStats.putIfAbsent(day, () => {'masuk': 0.0, 'keluar': 0.0});
      if (tx.jenis == 'Pemasukan') dailyStats[day]!['masuk'] = dailyStats[day]!['masuk']! + tx.nominal;
      if (tx.jenis == 'Pengeluaran') dailyStats[day]!['keluar'] = dailyStats[day]!['keluar']! + tx.nominal;
    }

    // 2. STATS MINGGUAN
    Map<int, Map<String, double>> weeklyStats = {};
    for (int w = 1; w <= 5; w++) {
      weeklyStats[w] = {'masuk': 0.0, 'keluar': 0.0};
      int startD = (w - 1) * 7 + 1;
      int endD = w * 7;
      var txs = currentMonthTxs.where((t) {
        int d = DateTime.parse(t.tanggal).day;
        return d >= startD && d <= endD;
      });
      for (var tx in txs) {
        if (tx.jenis == 'Pemasukan') weeklyStats[w]!['masuk'] = weeklyStats[w]!['masuk']! + tx.nominal;
        if (tx.jenis == 'Pengeluaran') weeklyStats[w]!['keluar'] = weeklyStats[w]!['keluar']! + tx.nominal;
      }
    }

    // 3. STATS BULANAN
    Map<int, Map<String, double>> monthlyStats = {};
    for (int m = 1; m <= 12; m++) {
      monthlyStats[m] = {'masuk': 0.0, 'keluar': 0.0};
      var txs = currentYearTxs.where((t) => DateTime.parse(t.tanggal).month == m);
      for (var tx in txs) {
        if (tx.jenis == 'Pemasukan') monthlyStats[m]!['masuk'] = monthlyStats[m]!['masuk']! + tx.nominal;
        if (tx.jenis == 'Pengeluaran') monthlyStats[m]!['keluar'] = monthlyStats[m]!['keluar']! + tx.nominal;
      }
    }

    // =======================================================
    // 📅 GRID KALENDER DINAMIS
    // =======================================================
    Widget gridContent = const SizedBox.shrink();
    Widget daysHeader = const SizedBox.shrink();
    final today = DateTime.now();

    // ---> MODE DAILY
    if (_activeToggle == 'Daily') {
      int daysInMonth = DateTime(year, month + 1, 0).day;
      int firstDayOfMonth = DateTime(year, month, 1).weekday; 
      int startDayIndex = firstDayOfMonth - 1; 

      List<Widget> daysWidgets = [];
      // 🟢 FIX INFO BIRU: Tambahin Kurung Kurawal { }
      for (int i = 0; i < startDayIndex; i++) {
        daysWidgets.add(const SizedBox.shrink());
      }

      for (int day = 1; day <= daysInMonth; day++) {
        final stats = dailyStats[day] ?? {'masuk': 0.0, 'keluar': 0.0};
        final bool isSelected = _selectedDate == day;
        final bool hasTx = stats['masuk']! > 0 || stats['keluar']! > 0;
        final bool isTodaySquare = today.month == month && today.year == year && day == today.day;

        daysWidgets.add(
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _selectedDate = day);
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => HistoryScreen(initialFilterDate: DateTime(year, month, day), initialMode: 'Harian')
              ));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected ? finance.themeAccent.withValues(alpha:0.15) : finance.themeCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? finance.themeAccent : (isTodaySquare ? finance.themeAccent.withValues(alpha:0.5) : finance.themeBorder),
                ),
              ),
              child: Opacity(
                opacity: hasTx || isTodaySquare ? 1.0 : 0.4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isSelected || isTodaySquare ? finance.themeAccent : finance.themeText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (stats['masuk']! > 0)
                      Text(
                        Formatters.formatUangCompact(stats['masuk']!).replaceAll(RegExp(r'^Rp\s?'), ''),
                        style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (stats['keluar']! > 0)
                      Text(
                        Formatters.formatUangCompact(stats['keluar']!).replaceAll(RegExp(r'^Rp\s?'), ''),
                        style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.redAccent),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      daysHeader = Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN'].map((day) {
            return Expanded(child: Center(child: Text(day, style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.w900))));
          }).toList(),
        ),
      );

      gridContent = GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 7, crossAxisSpacing: 6, mainAxisSpacing: 6, childAspectRatio: 0.85, children: daysWidgets,
      );
    } 
    // ---> MODE WEEKLY
    else if (_activeToggle == 'Weekly') {
      List<Widget> weeksWidgets = [];
      for (int w = 1; w <= 5; w++) {
        final stats = weeklyStats[w] ?? {'masuk': 0.0, 'keluar': 0.0};
        // 🟢 FIX WARNING KUNING: Variabel hasTx yang nganggur Dihapus
        int startD = (w - 1) * 7 + 1;

        weeksWidgets.add(
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => HistoryScreen(initialFilterDate: DateTime(year, month, startD), initialMode: 'Mingguan')
              ));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: finance.themeBorder)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Minggu $w", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: finance.themeText)),
                  const SizedBox(height: 4),
                  if (stats['masuk']! > 0)
                    Text(Formatters.formatUangCompact(stats['masuk']!).replaceAll(RegExp(r'^Rp\s?'), ''), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                  if (stats['keluar']! > 0)
                    Text(Formatters.formatUangCompact(stats['keluar']!).replaceAll(RegExp(r'^Rp\s?'), ''), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                ],
              ),
            ),
          ),
        );
      }
      gridContent = GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 5, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.9, children: weeksWidgets,
      );
    } 
    // ---> MODE MONTHLY
    else if (_activeToggle == 'Monthly') {
      List<Widget> monthsWidgets = [];
      for (int m = 1; m <= 12; m++) {
        final stats = monthlyStats[m] ?? {'masuk': 0.0, 'keluar': 0.0};
        // 🟢 FIX WARNING KUNING: Variabel hasTx yang nganggur Dihapus
        final bool isCurrentMonthBox = today.year == year && today.month == m;

        monthsWidgets.add(
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => HistoryScreen(initialFilterDate: DateTime(year, m, 1), initialMode: 'Bulanan')
              ));
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isCurrentMonthBox ? finance.themeAccent.withValues(alpha:0.1) : finance.themeCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isCurrentMonthBox ? finance.themeAccent : finance.themeBorder),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(Formatters.monthNames[m - 1].substring(0, 3).toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: isCurrentMonthBox ? finance.themeAccent : finance.themeText)),
                  const SizedBox(height: 4),
                  if (stats['masuk']! > 0)
                    Text(Formatters.formatUangCompact(stats['masuk']!).replaceAll(RegExp(r'^Rp\s?'), ''), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                  if (stats['keluar']! > 0)
                    Text(Formatters.formatUangCompact(stats['keluar']!).replaceAll(RegExp(r'^Rp\s?'), ''), style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                ],
              ),
            ),
          ),
        );
      }
      gridContent = GridView.count(
        shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.1, children: monthsWidgets,
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: finance.themeCard, 
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: finance.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: finance.themeBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: finance.themeBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: ['Daily', 'Weekly', 'Monthly'].map((tab) {
                    bool isActive = _activeToggle == tab;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          _activeToggle = tab;
                          _selectedDate = null;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? finance.themeAccent : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          tab,
                          style: TextStyle(
                            color: isActive ? Colors.white : finance.themeTextSub,
                            fontWeight: FontWeight.bold,
                            fontSize: 10
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(color: finance.themeBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: finance.themeBorder)),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _changeDate(DateTime(_activeToggle == 'Monthly' ? year - 1 : year, _activeToggle == 'Monthly' ? 1 : month - 1, 1)),
                      child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.chevron_left_rounded, color: finance.themeTextSub, size: 16)),
                    ),
                    SizedBox(
                      width: 65,
                      child: Text(
                        _activeToggle == 'Monthly' ? "TAHUN $year" : "${Formatters.monthNames[month - 1].substring(0, 3).toUpperCase()} $year",
                        style: TextStyle(color: finance.themeText, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _changeDate(DateTime(_activeToggle == 'Monthly' ? year + 1 : year, _activeToggle == 'Monthly' ? 1 : month + 1, 1)),
                      child: Padding(padding: const EdgeInsets.all(4), child: Icon(Icons.chevron_right_rounded, color: finance.themeTextSub, size: 16)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          daysHeader,
          gridContent,
        ],
      ),
    );
  }
}