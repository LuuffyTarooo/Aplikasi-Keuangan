// lib/screens/report/widgets/summary_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';

class SummaryBar extends StatefulWidget {
  final List<TransactionModel> transaksi;
  final DateTime currentDate;

  const SummaryBar({
    super.key,
    required this.transaksi,
    required this.currentDate,
  });

  @override
  State<SummaryBar> createState() => _SummaryBarState();
}

class _SummaryBarState extends State<SummaryBar> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.currentDate;
  }

  @override
  void didUpdateWidget(SummaryBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDate != widget.currentDate) {
      _selectedDate = widget.currentDate;
    }
  }

  String _formatAjaib(double n) {
    if (n.abs() >= 1000000) {
      return Formatters.formatUangCompact(n);
    } else {
      return Formatters.formatCurrency(n);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 AUTO-SYNC
    final finance = Provider.of<FinanceProvider>(context);

    double masuk = 0;
    double keluar = 0;

    for (var tx in widget.transaksi) {
      final d = DateTime.parse(tx.tanggal);
      if (d.year == _selectedDate.year && d.month == _selectedDate.month) {
        if (tx.jenis == 'Pemasukan') masuk += tx.nominal;
        if (tx.jenis == 'Pengeluaran') keluar += tx.nominal;
      }
    }

    String labelWaktu = "${Formatters.monthNames[_selectedDate.month - 1]} ${_selectedDate.year}";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- HEADER SUMMARY BAR ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Ringkasan",
              style: TextStyle(
                color: finance.themeText, // 🟢 AUTO-SYNC Text
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            
            // Navigasi Bulan (SOLID CARD)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: finance.themeCard, // 🟢 AUTO-SYNC Card
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: finance.themeBorder),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.chevron_left_rounded, color: finance.themeTextSub, size: 16),
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 80),
                    alignment: Alignment.center,
                    child: Text(
                      labelWaktu.toUpperCase(),
                      style: TextStyle(
                        color: finance.themeText, // 🟢 AUTO-SYNC Text
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1));
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.chevron_right_rounded, color: finance.themeTextSub, size: 16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // --- 2 KOTAK (MASUK & KELUAR AJA) ---
        Row(
          children: [
            // 1. KARTU PEMASUKAN
            Expanded(
              child: _buildSummaryCard(
                finance: finance,
                label: "Masuk",
                nominal: _formatAjaib(masuk),
                icon: Icons.arrow_circle_down_rounded,
                accentColor: Colors.greenAccent,
              ),
            ),
            const SizedBox(width: 12),

            // 2. KARTU PENGELUARAN
            Expanded(
              child: _buildSummaryCard(
                finance: finance,
                label: "Keluar",
                nominal: _formatAjaib(keluar),
                icon: Icons.arrow_circle_up_rounded,
                accentColor: Colors.pinkAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required FinanceProvider finance,
    required String label,
    required String nominal,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: finance.themeCard, // 🟢 AUTO-SYNC Card Solid
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: finance.themeBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accentColor, size: 16),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: accentColor, // Warna judul tetap (Ijo/Pink) biar jelas
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              nominal,
              style: TextStyle(
                color: finance.themeText, // 🟢 AUTO-SYNC Text (Hitam di Light Mode, Putih di Dark Mode)
                fontSize: 20, 
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}