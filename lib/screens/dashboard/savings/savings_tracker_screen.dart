// lib/screens/dashboard/savings/savings_tracker_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';
import 'package:aplikasi_keuangan/shared/widgets/glass_card.dart';
import 'package:aplikasi_keuangan/shared/widgets/custom_button.dart';
import 'package:aplikasi_keuangan/shared/widgets/custom_numpad.dart';
import 'package:aplikasi_keuangan/models/saving_model.dart'; 

class SavingsScreen extends StatefulWidget {
  const SavingsScreen({super.key});

  @override
  State<SavingsScreen> createState() => _SavingsScreenState();
}

class _SavingsScreenState extends State<SavingsScreen> {

  void _showToast(String message, {bool isError = false, bool isWarning = false}) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.gpp_bad_rounded : isWarning ? Icons.warning_amber_rounded : Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: isError ? Colors.pinkAccent : isWarning ? Colors.amber : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _openAddModal(FinanceProvider finance) {
    HapticFeedback.mediumImpact();
    String formName = '';
    double formTarget = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Color(0xFF161B22), borderRadius: BorderRadius.vertical(top: Radius.circular(32)), border: Border(top: BorderSide(color: Colors.white10))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Bikin Target Baru", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 24),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("NAMA IMPIAN/TARGET", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          const SizedBox(height: 8),
                          TextField(
                            onChanged: (val) => formName = val,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                              hintText: "Misal: Beli Knalpot Beat", hintStyle: const TextStyle(color: Colors.white30),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF9333EA))),
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Center(child: Text("TARGET NOMINAL", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              CalculatorNumpad.show(
                                context, initialCatatan: formName, initialTanggal: DateTime.now().toIso8601String(),
                                onSubmit: (nom, cat, tgl) { setModalState(() { formTarget = nom; formName = cat; }); }
                              );
                            },
                            child: Container(
                              width: double.infinity, padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(color: const Color(0xFF9333EA).withValues(alpha:0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF9333EA).withValues(alpha:0.3))),
                              child: Text(
                                formTarget == 0 ? "Rp 0" : Formatters.formatCurrency(formTarget),
                                textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFD946EF), fontSize: 32, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Center(child: Text("Ketuk kotak di atas untuk mengisi angka", style: TextStyle(color: Colors.white30, fontSize: 10))),
                        ],
                      ),
                    ),
                  ),

                  CustomButton(
                    text: "Simpan Target", fullWidth: true,
                    onPressed: () {
                      if (formName.isEmpty) return _showToast("Nama tabungannya diisi dulu dong!", isWarning: true);
                      if (formTarget <= 0) return _showToast("Target tabungannya berapa?", isWarning: true);

                      // 🟢 AKSI GLOBAL: Simpan ke provider biar permanen
                      finance.addSavingGoal(formName, formTarget); 
                      Navigator.pop(context);
                      _showToast("Target tabungan berhasil dibuat!");
                    },
                    variant: ButtonVariant.primary,
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openTransactionModal(SavingGoalModel goal, bool isNabung, FinanceProvider finance) {
    HapticFeedback.mediumImpact();
    double txNominal = 0;
    String txCatatan = '';
    String txTanggal = DateTime.now().toIso8601String();
    String selectedDompet = '';

    Color themeColor = isNabung ? Colors.greenAccent : Colors.amberAccent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(color: Color(0xFF161B22), borderRadius: BorderRadius.vertical(top: Radius.circular(32)), border: Border(top: BorderSide(color: Colors.white10))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isNabung ? "Isi Tabungan" : "Tarik Tabungan", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  Text(goal.name.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 32),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const Text("NOMINAL & CATATAN", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              CalculatorNumpad.show(
                                context, initialCatatan: txCatatan, initialTanggal: txTanggal, 
                                onSubmit: (nom, cat, tgl) { setModalState(() { txNominal = nom; txCatatan = cat; txTanggal = tgl; }); }
                              );
                            },
                            child: Container(
                              width: double.infinity, padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(color: themeColor.withValues(alpha:0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: themeColor.withValues(alpha:0.3))),
                              child: Column(
                                children: [
                                  Text(txNominal == 0 ? "Rp 0" : Formatters.formatCurrency(txNominal), style: TextStyle(color: themeColor, fontSize: 32, fontWeight: FontWeight.w900)),
                                  if (txCatatan.isNotEmpty) ...[const SizedBox(height: 8), Text("📝 $txCatatan", style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold))],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Text(isNabung ? "AMBIL DARI DOMPET MANA?" : "PINDAHKAN KE DOMPET MANA?", style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: selectedDompet.isEmpty ? null : selectedDompet,
                                hint: const Text("Pilih dompet...", style: TextStyle(color: Colors.white30, fontSize: 14, fontWeight: FontWeight.bold)),
                                isExpanded: true, dropdownColor: const Color(0xFF161B22), icon: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white54), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                items: finance.mySumberDana.map((d) => DropdownMenuItem(value: d.idDana, child: Text("${d.namaAset} (Sisa: ${Formatters.formatCurrency(d.saldoTerkini)})"))).toList(),
                                onChanged: (v) { HapticFeedback.lightImpact(); setModalState(() => selectedDompet = v!); },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  CustomButton(
                    text: isNabung ? "Konfirmasi Simpan" : "Konfirmasi Tarik", fullWidth: true,
                    onPressed: () {
                      if (selectedDompet.isEmpty) return _showToast("Pilih dompetnya dulu Jar!", isWarning: true);
                      if (txNominal <= 0) return _showToast("Nominalnya yang bener dong.", isWarning: true);

                      final dompet = finance.mySumberDana.firstWhere((d) => d.idDana == selectedDompet);
                      String fallbackCatatan = isNabung ? "Nabung: ${goal.name}" : "Tarik Tabungan: ${goal.name}";

                      if (isNabung) {
                        if (dompet.saldoTerkini < txNominal) return _showToast("Saldo ${dompet.namaAset} lu nggak cukup!", isError: true);
                        
                        finance.handleSaveTransaksi(TransactionModel(
                          idTransaksi: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                          jenis: 'Pengeluaran', nominal: txNominal, idDana: selectedDompet, kategori: 'Tabungan',
                          keterangan: txCatatan.isNotEmpty ? txCatatan : fallbackCatatan, tanggal: txTanggal, userId: finance.currentUser!.id,
                        ));

                        // 🟢 AKSI GLOBAL: Update progress tabungan di provider
                        finance.updateSavingProgress(goal.id, txNominal, true);
                        _showToast("Uang berhasil ditabung!");
                      } else {
                        if (txNominal > goal.current) return _showToast("Lu cuma punya ${Formatters.formatCurrency(goal.current)} di tabungan ini.", isError: true);

                        finance.handleSaveTransaksi(TransactionModel(
                          idTransaksi: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                          jenis: 'Pemasukan', nominal: txNominal, idDana: selectedDompet, kategori: 'Tabungan',
                          keterangan: txCatatan.isNotEmpty ? txCatatan : fallbackCatatan, tanggal: txTanggal, userId: finance.currentUser!.id,
                        ));

                        // 🟢 AKSI GLOBAL: Kurangi progress tabungan di provider
                        finance.updateSavingProgress(goal.id, txNominal, false);
                        _showToast("Uang berhasil ditarik!");
                      }

                      Navigator.pop(context);
                    },
                    variant: isNabung ? ButtonVariant.primary : ButtonVariant.secondary,
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(String goalId, FinanceProvider finance) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.white10)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.pinkAccent.withValues(alpha:0.1), shape: BoxShape.circle), child: const Icon(Icons.delete_outline_rounded, color: Colors.pinkAccent, size: 32)),
            const SizedBox(height: 16),
            const Text("Hapus Target?", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text("Yakin mau hapus target tabungan ini?", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 24),
            CustomButton(text: "Ya, Hapus", variant: ButtonVariant.danger, fullWidth: true, onPressed: () {
              // 🟢 AKSI GLOBAL: Hapus dari provider global
              finance.deleteSavingGoal(goalId); 
              Navigator.pop(context);
              _showToast("Target tabungan dihapus.");
            }),
            const SizedBox(height: 8),
            CustomButton(text: "Batal", variant: ButtonVariant.secondary, fullWidth: true, onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final mySavingsData = finance.mySavings; // 🟢 Baca data tabungan dari provider global

    // Kalkulasi Total
    double totalTerkumpul = mySavingsData.fold(0, (sum, g) => sum + g.current);
    double totalTarget = mySavingsData.fold(0, (sum, g) => sum + g.target);
    double overallProgress = totalTarget > 0 ? (totalTerkumpul / totalTarget) * 100 : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF05010D),
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                    child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), shape: BoxShape.circle), child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
                  ),
                  const SizedBox(width: 16),
                  const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("Tabungan", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    Text("PINDAH KANTONG ASET", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ]),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // --- KARTU DASHBOARD UTAMA ---
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha:0.1), borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.greenAccent.withValues(alpha:0.2)),
                        boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha:0.1), blurRadius: 30)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha:0.2), shape: BoxShape.circle), child: const Icon(Icons.savings_rounded, color: Colors.greenAccent, size: 16)),
                              const SizedBox(width: 12),
                              const Text("TOTAL TERSIMPAN", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(Formatters.formatCurrency(totalTerkumpul), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.greenAccent, blurRadius: 15)])),
                          const SizedBox(height: 24),
                          
                          Container(
                            padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.black.withValues(alpha:0.3), borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text("Progress Keseluruhan", style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                    Text("${overallProgress.round()}% dari ${Formatters.formatCurrency(totalTarget)}", style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                LinearProgressIndicator(value: (overallProgress / 100).clamp(0.0, 1.0), backgroundColor: Colors.white10, color: Colors.greenAccent, minHeight: 8, borderRadius: BorderRadius.circular(4)),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- PESAN INSIGHT ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.lightBlueAccent.withValues(alpha:0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.lightBlueAccent.withValues(alpha:0.3))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: Colors.lightBlueAccent, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
                                children: [
                                  TextSpan(text: "Insight: ", style: TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold)),
                                  TextSpan(text: "Uang di tabungan ini adalah kantong virtual. Saat lu nabung, saldo dompet utama bakal berkurang biar lu nggak ngerasa kebanyakan duit, dan bakal kecatat di riwayat sebagai "),
                                  TextSpan(text: "Pengeluaran/Transfer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  TextSpan(text: "."),
                                ],
                              ),
                            ),
                          )
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- LIST TARGET TABUNGAN ---
                    if (mySavingsData.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10, style: BorderStyle.solid)),
                        child: const Center(
                          child: Column(
                            children: [
                              Icon(Icons.track_changes_rounded, color: Colors.white30, size: 40),
                              SizedBox(height: 16),
                              Text("Belum Ada Target", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                              SizedBox(height: 8),
                              Text("Mulai pisahin duit dan bikin target lu di bawah!", style: TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...mySavingsData.map((goal) {
                        double progress = (goal.current / goal.target) * 100;
                        bool isFull = progress >= 100;
                        Color accentColor = isFull ? Colors.greenAccent : Colors.tealAccent;

                        return GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              if (isFull)
                                Container(height: 4, decoration: const BoxDecoration(color: Colors.greenAccent, borderRadius: BorderRadius.vertical(top: Radius.circular(16)))),
                              
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(child: Text(goal.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                            if (isFull) const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 16),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Text("TARGET: ${Formatters.formatCurrency(goal.target)}", style: const TextStyle(color: Colors.white54, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                                            if (isFull) ...[
                                              const SizedBox(width: 8),
                                              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha:0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.greenAccent.withValues(alpha:0.5))), child: const Text("TERCAPAI 🎉", style: TextStyle(color: Colors.greenAccent, fontSize: 8, fontWeight: FontWeight.w900))),
                                            ]
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                  Text(Formatters.formatCurrency(goal.current), style: TextStyle(color: isFull ? Colors.greenAccent : Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              LinearProgressIndicator(value: (progress / 100).clamp(0.0, 1.0), backgroundColor: Colors.black26, color: accentColor, minHeight: 8, borderRadius: BorderRadius.circular(4)),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _confirmDelete(goal.id, finance),
                                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.pinkAccent.withValues(alpha:0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.pinkAccent.withValues(alpha:0.3))), child: const Icon(Icons.delete_outline_rounded, color: Colors.pinkAccent, size: 20)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomButton(
                                      text: "Tarik", icon: Icons.arrow_upward_rounded, variant: ButtonVariant.secondary,
                                      onPressed: goal.current == 0 ? null : () => _openTransactionModal(goal, false, finance),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomButton(
                                      text: "Nabung", icon: Icons.arrow_downward_rounded, variant: ButtonVariant.primary,
                                      onPressed: isFull ? null : () => _openTransactionModal(goal, true, finance),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 24),
                    
                    CustomButton(
                      text: "Bikin Target Baru", icon: Icons.add_rounded, variant: ButtonVariant.primary, 
                      fullWidth: true, onPressed: () => _openAddModal(finance),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}