// lib/screens/report/report_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/finance_provider.dart';
import 'widgets/summary_bar.dart';
import 'widgets/analytics_section.dart';
import 'widgets/calendar_pnl.dart';
import 'widgets/history_section.dart';
import 'dialogs/export_dialog.dart';

class ReportHubScreen extends StatefulWidget {
  const ReportHubScreen({super.key});

  @override
  State<ReportHubScreen> createState() => _ReportHubScreenState();
}

class _ReportHubScreenState extends State<ReportHubScreen> {
  DateTime _currentDate = DateTime.now();

  void _handleDateChange(DateTime newDate) {
    HapticFeedback.lightImpact();
    setState(() {
      _currentDate = newDate;
    });
  }

  void _openExportModal() {
    HapticFeedback.mediumImpact();
    ExportDialog.show(context, _currentDate);
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // Background diurus MainLayout
      body: SafeArea(
        bottom: false, 
        child: Column(
          children: [
            // --- HEADER & TOMBOL EXPORT (FIXED/PINNED DI ATAS) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Laporan",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          shadows: [Shadow(color: Color(0xFFA855F7), blurRadius: 10)],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "ANALISIS KEUANGANMU",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withValues(alpha:0.5),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  
                  // Tombol Export Glassmorphism
                  GestureDetector(
                    onTap: _openExportModal,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9333EA).withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA855F7).withValues(alpha:0.3)),
                        boxShadow: [
                          BoxShadow(color: const Color(0xFFA855F7).withValues(alpha:0.2), blurRadius: 15)
                        ],
                      ),
                      child: const Icon(
                        Icons.download_rounded,
                        color: Color(0xFFA855F7),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- KONTEN UTAMA (Scrollable) ---
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 120, left: 20, right: 20, top: 8),
                child: Column(
                  children: [
                    // 1. Ringkasan Saldo (Pemasukan & Pengeluaran)
                    SummaryBar(
                      transaksi: finance.myTransaksi,
                      currentDate: _currentDate,
                    ),
                    const SizedBox(height: 32),

                    // 2. Grafik Tren & Donut
                    AnalyticsSection(
                      transaksi: finance.myTransaksi,
                      currentDate: _currentDate,
                      onDateChange: _handleDateChange,
                    ),
                    const SizedBox(height: 32),

                    // 3. Kalender Arus Kas
                    CalendarPnlSection(
                      transaksi: finance.myTransaksi,
                      currentDate: _currentDate,
                      onDateChange: _handleDateChange,
                    ),
                    const SizedBox(height: 32),

                    // 4. Daftar Riwayat Transaksi (Search & Filter ada di dalam sini)
                    HistorySection(
                      transaksi: finance.myTransaksi,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}