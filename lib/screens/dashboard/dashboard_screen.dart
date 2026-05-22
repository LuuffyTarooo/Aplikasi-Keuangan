// lib/screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';
import 'package:aplikasi_keuangan/core/utils/wallet_helper.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';
import 'package:aplikasi_keuangan/models/wallet_model.dart'; 
import 'package:aplikasi_keuangan/screens/report/widgets/history_section.dart';// 🟢 FIX: Import Layar History

import 'package:aplikasi_keuangan/shared/widgets/account_manager_sheet.dart';
import 'package:aplikasi_keuangan/shared/bottom_sheets/transaction_detail_sheet.dart';
import 'package:aplikasi_keuangan/screens/transaction/transaction_form_screen.dart';

class DashboardScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const DashboardScreen({super.key, required this.onNavigate});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _showBalance = true;

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    List<WalletModel> activeWallets = finance.mySumberDana.where((w) => w.isActive).toList();
    double totalSaldo = activeWallets.fold(0, (sum, item) => sum + item.saldoTerkini);

    return Scaffold(
      backgroundColor: finance.themeBg, // 🟢 AUTO-SYNC: Latar Belakang Solid
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),

            // ================= BAGIAN ATAS (Header & Saldo) =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleButton(
                    finance: finance, // 🟢 FIX PARAMETER
                    child: Text(finance.currentUser?.avatar ?? '😎', style: const TextStyle(fontSize: 18)),
                    onTap: () { HapticFeedback.lightImpact(); AccountManagerSheet.show(context); },
                  ),
                  Column(
                    children: [
                      Text("DOMPET", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: finance.themeAccent, letterSpacing: 2)),
                      Text(finance.currentUser?.name ?? "User Utama", style: TextStyle(color: finance.themeText, fontWeight: FontWeight.w900, fontSize: 16)),
                    ],
                  ),
                  _buildCircleButton(
                    finance: finance, // 🟢 FIX PARAMETER
                    child: Icon(Icons.receipt_long_rounded, color: finance.themeText, size: 22), 
                    onTap: () { 
                      HapticFeedback.lightImpact(); 
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
                    },
                    hasBadge: false, 
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Center(
              child: Column(
                children: [
                  Text("TOTAL KESELURUHAN", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: finance.themeTextSub, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        Formatters.formatCurrency(totalSaldo, isHidden: !_showBalance),
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: finance.themeText),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () { HapticFeedback.lightImpact(); setState(() => _showBalance = !_showBalance); },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: finance.themeCard, shape: BoxShape.circle, border: Border.all(color: finance.themeBorder)),
                          child: Icon(_showBalance ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: finance.themeTextSub, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ================= HORIZONTAL WALLET LIST =================
            SizedBox(
              height: 85, 
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: activeWallets.length, 
                itemBuilder: (context, index) {
                  final wallet = activeWallets[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () { HapticFeedback.lightImpact(); widget.onNavigate('wallets'); },
                      child: Container( // 🟢 FIX: GlassCard diubah jadi Container solid
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), 
                        width: 115, 
                        decoration: BoxDecoration(
                          color: finance.themeCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: finance.themeBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                WalletHelper.getWalletLogo(wallet.namaAset, size: 'sm'),
                                const SizedBox(width: 8),
                                Expanded(child: Text(wallet.namaAset.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: finance.themeTextSub, overflow: TextOverflow.ellipsis))),
                              ],
                            ),
                            FittedBox(
                              fit: BoxFit.scaleDown, alignment: Alignment.centerLeft,
                              child: Text(Formatters.formatCurrency(wallet.saldoTerkini, isHidden: !_showBalance), style: TextStyle(color: finance.themeText, fontWeight: FontWeight.w900, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // ================= BAGIAN BAWAH (Fitur Pilihan) =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Fitur Pilihan", style: TextStyle(color: finance.themeText, fontWeight: FontWeight.w900, fontSize: 16)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMenuIcon(Icons.savings_rounded, "Tabungan", finance, () { widget.onNavigate('savings'); }),
                      _buildMenuIcon(Icons.people_alt_rounded, "Hutang", finance, () { widget.onNavigate('debt'); }),
                      _buildMenuIcon(Icons.calculate_rounded, "Kalkulator", finance, () { widget.onNavigate('calculator'); }),
                      _buildMenuIcon(Icons.alarm_rounded, "Pengingat", finance, () { widget.onNavigate('reminders'); }),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ================= RIWAYAT TERAKHIR =================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Riwayat Terakhir", style: TextStyle(color: finance.themeText, fontWeight: FontWeight.w900, fontSize: 16)),
                      GestureDetector(
                        onTap: () { HapticFeedback.lightImpact(); Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())); },
                        child: Text("Lihat Semua", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: finance.themeAccent)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRecentTransactions(finance, context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGIKA & WIDGET TRANSAKSI HARIAN ---
  Widget _buildRecentTransactions(FinanceProvider finance, BuildContext context) {
    DateTime now = DateTime.now();
    String todayStr = DateFormat('yyyy-MM-dd').format(now);
    String yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    List<TransactionModel> recentTxs = finance.myTransaksi.where((tx) {
      DateTime txDate = DateTime.parse(tx.tanggal);
      String txDateStr = DateFormat('yyyy-MM-dd').format(txDate);
      return txDateStr == todayStr || txDateStr == yesterdayStr;
    }).toList();

    if (recentTxs.isEmpty) {
      return Container( // 🟢 FIX: GlassCard diubah jadi Container solid
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: finance.themeBorder)),
        child: Center(child: Text("Belum ada transaksi hari ini atau kemarin.", style: TextStyle(color: finance.themeTextSub, fontWeight: FontWeight.bold, fontSize: 14))),
      );
    }

    Map<String, List<TransactionModel>> groupedData = {};
    for (var tx in recentTxs) {
      String dStr = DateFormat('yyyy-MM-dd').format(DateTime.parse(tx.tanggal));
      if (!groupedData.containsKey(dStr)) groupedData[dStr] = [];
      groupedData[dStr]!.add(tx);
    }

    List<String> sortedDates = groupedData.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: sortedDates.map((dateStr) {
        List<TransactionModel> items = groupedData[dateStr]!;
        double dailyExpense = items.where((t) => t.jenis == 'Pengeluaran').fold(0, (sum, t) => sum + t.nominal);
        String displayDate = dateStr == todayStr ? 'HARI INI' : (dateStr == yesterdayStr ? 'KEMARIN' : dateStr);

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(bottom: 8),
                margin: const EdgeInsets.only(bottom:12),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: finance.themeBorder))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(displayDate, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: finance.themeAccent, letterSpacing: 1.5)),
                    if (dailyExpense > 0) Text("-${Formatters.formatCurrency(dailyExpense)}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.redAccent)),
                  ],
                ),
              ),

              ...items.map((tx) {
                final dompet = finance.mySumberDana.firstWhere((d) => d.idDana == tx.idDana, orElse: () => finance.mySumberDana.first);
                String dompetName = dompet.namaAset;

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
                        context: context, transaction: tx, sumberDana: finance.mySumberDana,
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
                    child: Container( // 🟢 FIX: GlassCard diubah jadi Container solid
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
                                children: [
                                  WalletHelper.getWalletLogo(dompetName, size: 'sm'),
                                  const SizedBox(width: 4),
                                  Text(dompetName, style: TextStyle(color: finance.themeTextSub, fontWeight: FontWeight.bold, fontSize: 10)),
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
      }).toList(),
    );
  }

  // --- WIDGET HELPERS ---
  // 🟢 FIX: Fungsi helper diperbarui
  Widget _buildCircleButton({required FinanceProvider finance, required Widget child, required VoidCallback onTap, bool hasBadge = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, color: finance.themeCard, border: Border.all(color: finance.themeBorder)),
        alignment: Alignment.center,
        child: Stack(
          alignment: Alignment.center,
          children: [
            child,
            if (hasBadge)
              Positioned(top: 10, right: 12, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle, border: Border.all(color: finance.themeBg, width: 1.5)))),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuIcon(IconData icon, String label, FinanceProvider finance, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Column(
        children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: finance.themeBorder)),
            child: Icon(icon, color: finance.themeAccent, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: finance.themeTextSub, fontSize: 11, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}