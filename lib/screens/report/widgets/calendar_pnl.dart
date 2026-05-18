// lib/screens/report/widgets/calendar_pnl.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';
import 'package:aplikasi_keuangan/shared/widgets/glass_card.dart';
import 'package:aplikasi_keuangan/core/utils/wallet_helper.dart'; // 🟢 TAMBAHIN IMPORT INI BUAT LOGO BANK

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

  @override
  void didUpdateWidget(CalendarPnlSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDate != widget.currentDate) {
      _selectedDate = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final year = widget.currentDate.year;
    final month = widget.currentDate.month;

    // Filter transaksi untuk bulan yang dipilih
    final currentMonthTxs = widget.transaksi.where((t) {
      final txDate = DateTime.parse(t.tanggal);
      return txDate.month == month && txDate.year == year;
    }).toList();

    // Hitung Pemasukan & Pengeluaran harian
    Map<int, Map<String, double>> dailyStats = {};
    for (var tx in currentMonthTxs) {
      int day = DateTime.parse(tx.tanggal).day;
      dailyStats.putIfAbsent(day, () => {'masuk': 0.0, 'keluar': 0.0});
      if (tx.jenis == 'Pemasukan') dailyStats[day]!['masuk'] = dailyStats[day]!['masuk']! + tx.nominal;
      if (tx.jenis == 'Pengeluaran') dailyStats[day]!['keluar'] = dailyStats[day]!['keluar']! + tx.nominal;
    }

    // Logika Kalender
    int daysInMonth = DateTime(year, month + 1, 0).day;
    int firstDayOfMonth = DateTime(year, month, 1).weekday; // 1 = Senin, 7 = Minggu
    int startDayIndex = firstDayOfMonth - 1; // 0 = Senin, 6 = Minggu

    List<Widget> daysWidgets = [];

    for (int i = 0; i < startDayIndex; i++) {
      daysWidgets.add(const SizedBox.shrink());
    }

    final today = DateTime.now();
    final isCurrentMonth = today.month == month && today.year == year;
    final currentDay = today.day;

    for (int day = 1; day <= daysInMonth; day++) {
      final stats = dailyStats[day] ?? {'masuk': 0.0, 'keluar': 0.0};
      final bool isSelected = _selectedDate == day;
      final bool hasTx = stats['masuk']! > 0 || stats['keluar']! > 0;
      final bool isTodaySquare = isCurrentMonth && day == currentDay;

      daysWidgets.add(
        GestureDetector(
          onTap: hasTx
              ? () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedDate = day);
                  _showDailyDetailModal(day, currentMonthTxs, stats);
                }
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF9333EA).withValues(alpha:0.2)
                  : Colors.white.withValues(alpha:0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF9333EA).withValues(alpha:0.5)
                    : isTodaySquare
                        ? const Color(0xFFD946EF).withValues(alpha:0.5)
                        : Colors.white10,
              ),
              boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF9333EA).withValues(alpha:0.4), blurRadius: 10)] : null,
            ),
            child: Opacity(
              opacity: hasTx ? 1.0 : 0.3,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? const Color(0xFFD946EF) : (isTodaySquare ? const Color(0xFFA855F7) : Colors.white70),
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
                      style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.pinkAccent),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("ARUS HARIAN", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () { HapticFeedback.lightImpact(); widget.onDateChange(DateTime(year, month - 1, 1)); },
                      child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.chevron_left_rounded, color: Colors.white54, size: 16)),
                    ),
                    SizedBox(
                      width: 60,
                      child: Text(
                        "${Formatters.monthNames[month - 1].substring(0, 3).toUpperCase()} $year",
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    GestureDetector(
                      onTap: () { HapticFeedback.lightImpact(); widget.onDateChange(DateTime(year, month + 1, 1)); },
                      child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 16)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['SEN', 'SEL', 'RAB', 'KAM', 'JUM', 'SAB', 'MIN'].map((day) {
              return Expanded(child: Center(child: Text(day, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900))));
            }).toList(),
          ),
          const SizedBox(height: 12),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            crossAxisSpacing: 6,
            mainAxisSpacing: 6,
            childAspectRatio: 0.8,
            children: daysWidgets,
          ),
        ],
      ),
    );
  }

  // --- MODAL DETAIL HARIAN (REVISI LOGO & LAYOUT ANTI KOPONG) ---
  void _showDailyDetailModal(int day, List<TransactionModel> currentMonthTxs, Map<String, double> stats) {
    final year = widget.currentDate.year;
    final month = widget.currentDate.month;
    
    // Sortir transaksi dari yang terbaru
    final selectedDayTransactions = currentMonthTxs.where((t) => DateTime.parse(t.tanggal).day == day).toList()
      ..sort((a, b) => DateTime.parse(b.tanggal).compareTo(DateTime.parse(a.tanggal)));
      
    final finance = Provider.of<FinanceProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea( // 🟢 Dibungkus SafeArea biar gak nabrak notch/home bar bawah
          child: Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF161B22), 
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)), 
              border: Border(top: BorderSide(color: Colors.white10))
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // 🟢 Bikin tinggi compact menyesuaikan isi
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Detail Harian", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                        Text("$day ${Formatters.monthNames[month - 1]} $year", style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), shape: BoxShape.circle),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 24),

                // Kotak Rekap Masuk Keluar
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha:0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.greenAccent.withValues(alpha:0.2))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("MASUK", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                            const SizedBox(height: 4),
                            Text(Formatters.formatCurrency(stats['masuk']!), style: const TextStyle(color: Colors.greenAccent, fontSize: 14, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.pinkAccent.withValues(alpha:0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.pinkAccent.withValues(alpha:0.2))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("KELUAR", style: TextStyle(color: Colors.pinkAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                            const SizedBox(height: 4),
                            Text(Formatters.formatCurrency(stats['keluar']!), style: const TextStyle(color: Colors.pinkAccent, fontSize: 14, fontWeight: FontWeight.w900), overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 🟢 DAFTAR TRANSAKSI
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true, // 🟢 Bikin list memendek kalau isinya dikit
                    padding: EdgeInsets.zero, // 🟢 Hilangin padding default ListView yg bikin space kosong
                    physics: const BouncingScrollPhysics(),
                    itemCount: selectedDayTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = selectedDayTransactions[index];
                      final dompetName = finance.mySumberDana.firstWhere((d) => d.idDana == tx.idDana, orElse: () => finance.mySumberDana.first).namaAset;
                      
                      bool isIncome = tx.jenis == 'Pemasukan';
                      bool isTransfer = tx.jenis == 'Transfer';
                      Color iconColor = isIncome ? Colors.greenAccent : (isTransfer ? const Color(0xFFD946EF) : Colors.pinkAccent);
                      Color amountColor = isIncome ? Colors.greenAccent : Colors.white; // Pengeluaran nominalnya putih
                      String prefix = isIncome ? '+' : '-';
                      String titleText = tx.kategori.isEmpty ? 'Lain-lain' : tx.kategori;
                      String subText = tx.keterangan.isEmpty ? 'Transaksi' : tx.keterangan;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))), // Cuma garis bawah
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // 🟢 Kotak Icon Panah (Sesuai Foto)
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
                            // Kategori & Catatan
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
                            // Nominal & 🟢 LOGO BANK
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
                                    // 🟢 Panggil Logo Asli pakai WalletHelper
                                    SizedBox(
                                      width: 18, height: 18, 
                                      child: WalletHelper.getWalletLogo(dompetName, size: 'sm')
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      dompetName, 
                                      style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() => setState(() => _selectedDate = null));
  }
}