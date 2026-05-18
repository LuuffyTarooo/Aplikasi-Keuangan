// lib/screens/report/widgets/summary_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    // Sinkronisasi kalau parent ngerubah tanggal
    if (oldWidget.currentDate != widget.currentDate) {
      _selectedDate = widget.currentDate;
    }
  }

  String _formatAjaib(double n) {
    // Logika format ringkas kalau nyentuh jutaan
    if (n.abs() >= 1000000) {
      return "Rp ${Formatters.formatUangCompact(n).replaceAll(RegExp(r'^Rp\s?'), '')}";
    } else {
      return "Rp ${Formatters.formatCurrency(n).replaceAll(RegExp(r'^Rp\s?'), '')}";
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hitung Masuk & Keluar di bulan ini
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
            const Text(
              "Ringkasan",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            
            // Navigasi Bulan (Glassmorphism)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() => _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1, 1));
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.chevron_left_rounded, color: Colors.white54, size: 16),
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(minWidth: 80),
                    alignment: Alignment.center,
                    child: Text(
                      labelWaktu.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
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
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 16),
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
                label: "Masuk",
                nominal: _formatAjaib(masuk),
                icon: Icons.arrow_circle_down_rounded,
                color: Colors.greenAccent,
              ),
            ),
            const SizedBox(width: 12),

            // 2. KARTU PENGELUARAN
            Expanded(
              child: _buildSummaryCard(
                label: "Keluar",
                nominal: _formatAjaib(keluar),
                icon: Icons.arrow_circle_up_rounded,
                color: Colors.pinkAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Helper bikin kotak biar kodenya gak panjang
  Widget _buildSummaryCard({
    required String label,
    required String nominal,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha:0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
          )
        ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: color,
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
                color: color,
                fontSize: 20, // 🟢 Diperbesar karena space makin lega
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