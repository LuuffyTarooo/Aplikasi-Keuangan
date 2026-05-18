// lib/screens/report/report_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/finance_provider.dart';
import 'widgets/summary_bar.dart';
import 'widgets/analytics_section.dart';
import 'widgets/calendar_pnl.dart';
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
    // 🟢 AUTO-SYNC: Panggil provider tema
    final finance = Provider.of<FinanceProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // Background diurus MainLayout biar nyatu
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
                      Text(
                        "Laporan",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: finance.themeText, // 🟢 AUTO-SYNC
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "ANALISIS KEUANGANMU",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: finance.themeTextSub, // 🟢 AUTO-SYNC
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  
                  // 🟢 AUTO-SYNC: Tombol Export Flat Design
                  GestureDetector(
                    onTap: _openExportModal,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: finance.themeCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: finance.themeBorder),
                      ),
                      child: Icon(
                        Icons.download_rounded,
                        color: finance.themeAccent,
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
                    // 🟢 FIX: Diisi lagi parameternya biar nggak merah!
                    CalendarPnlSection(
                      transaksi: finance.myTransaksi,
                      currentDate: _currentDate,
                      onDateChange: _handleDateChange,
                    ),
                    const SizedBox(height: 32),

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