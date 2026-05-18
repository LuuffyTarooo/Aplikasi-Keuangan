// lib/screens/dashboard/reminder/reminder_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';
import 'package:aplikasi_keuangan/models/reminder_model.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';
import 'package:aplikasi_keuangan/shared/widgets/glass_card.dart';
import 'package:aplikasi_keuangan/shared/widgets/custom_button.dart';
import 'package:aplikasi_keuangan/shared/widgets/custom_numpad.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  String _activeTab = 'SEMUA';

  final List<Map<String, String>> _kategoriList = [
    {'id': 'def1', 'name': 'Tagihan'},
    {'id': 'def2', 'name': 'Langganan'},
    {'id': 'def3', 'name': 'Listrik & Air'},
    {'id': 'def4', 'name': 'Kosan / Rumah'},
  ];

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

  // 🟢 VAKSIN ANTI MERAH: FUNGSI TANGGAL MANUAL
  String _getBulanIndo(DateTime date) {
    const bulan = ['JAN', 'FEB', 'MAR', 'APR', 'MEI', 'JUN', 'JUL', 'AGU', 'SEP', 'OKT', 'NOV', 'DES'];
    return bulan[date.month - 1];
  }

  String _getTanggalLengkap(DateTime date) {
    const bulanLengkap = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    return "${date.day.toString().padLeft(2, '0')} ${bulanLengkap[date.month - 1]} ${date.year}";
  }

  Map<String, dynamic> _getTypeProps(String kategoriName) {
    String lower = kategoriName.toLowerCase();
    if (lower.contains('listrik') || lower.contains('air') || lower.contains('internet') || lower.contains('wifi')) {
      return {'icon': Icons.bolt_rounded, 'color': Colors.amber};
    }
    if (lower.contains('langgan') || lower.contains('spotify') || lower.contains('netflix') || lower.contains('game')) {
      return {'icon': Icons.repeat_rounded, 'color': Colors.purpleAccent};
    }
    if (lower.contains('cicil') || lower.contains('kredit') || lower.contains('paylater')) {
      return {'icon': Icons.credit_card_rounded, 'color': Colors.blueAccent};
    }
    if (lower.contains('rumah') || lower.contains('kos') || lower.contains('pendidikan')) {
      return {'icon': Icons.grid_view_rounded, 'color': Colors.tealAccent};
    }
    return {'icon': Icons.notifications_active_rounded, 'color': const Color(0xFFD946EF)};
  }

  // ==========================================
  // 💎 WIDGET UI: PILIH DOMPET PREMIUM
  // ==========================================
  void _showWalletPicker(FinanceProvider finance, Function(String) onSelect) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Color(0xFF161B22), borderRadius: BorderRadius.vertical(top: Radius.circular(32)), border: Border(top: BorderSide(color: Colors.white10))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pilih Dompet", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            ...finance.mySumberDana.map((w) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () { onSelect(w.idDana); Navigator.pop(ctx); },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF9333EA).withValues(alpha:0.2), shape: BoxShape.circle), child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFA855F7), size: 20)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(w.namaAset, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            Text("Sisa: ${Formatters.formatCurrency(w.saldoTerkini)}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle_outline_rounded, color: Colors.white30),
                    ],
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSelector(String selectedId, FinanceProvider finance, VoidCallback onTap) {
    final dompet = selectedId.isEmpty ? null : finance.mySumberDana.firstWhere((d) => d.idDana == selectedId, orElse: () => finance.mySumberDana.first);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha:0.2), shape: BoxShape.circle), child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF3B82F6), size: 16)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dompet == null ? "Pilih Dompet..." : dompet.namaAset, style: TextStyle(color: dompet == null ? Colors.white54 : Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  if (dompet != null) Text("Sisa: ${Formatters.formatCurrency(dompet.saldoTerkini)}", style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ⚡ MODAL TAMBAH JADWAL
  // ==========================================
  void _openAddModal(FinanceProvider finance) {
    HapticFeedback.mediumImpact();
    String formTitle = '';
    String formKategori = '';
    String formDate = DateTime.now().toIso8601String();
    double formNominal = 0;
    
    // 🟢 Controller buat sinkronisasi tombol Kategori dan Input Teks
    TextEditingController kategoriController = TextEditingController();

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
                  const Text("Jadwal Baru", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  const Text("RUTINITAS & LANGGANAN", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 24),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 🟢 KATEGORI (BISA KLIK ATAU KETIK CUSTOM)
                          const Text("KATEGORI RUTINITAS", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: _kategoriList.map((kat) {
                              bool isActive = formKategori == kat['name'];
                              return GestureDetector(
                                onTap: () { 
                                  HapticFeedback.lightImpact(); 
                                  setModalState(() {
                                    formKategori = kat['name']!;
                                    kategoriController.text = kat['name']!; // Sinkronisasi text field
                                  }); 
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isActive ? const Color(0xFF9333EA).withValues(alpha:0.2) : Colors.white.withValues(alpha:0.05),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: isActive ? const Color(0xFFA855F7).withValues(alpha:0.5) : Colors.white10),
                                  ),
                                  child: Text(kat['name']!, style: TextStyle(color: isActive ? const Color(0xFFD946EF) : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: kategoriController,
                            onChanged: (val) {
                              setModalState(() => formKategori = val);
                            },
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                              hintText: "Atau ketik kategori sendiri...", hintStyle: const TextStyle(color: Colors.white30),
                              prefixIcon: const Icon(Icons.style_rounded, color: Colors.white54),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF9333EA))),
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Center(child: Text("ESTIMASI NOMINAL", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              CalculatorNumpad.show(context, initialCatatan: formTitle, initialTanggal: formDate, onSubmit: (nom, cat, tgl) {
                                setModalState(() { formNominal = nom; formTitle = cat; formDate = tgl; });
                              });
                            },
                            child: Container(
                              width: double.infinity, padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
                              child: Text(
                                Formatters.formatCurrency(formNominal), textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFFD946EF), fontSize: 32, fontWeight: FontWeight.w900),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Text("NAMA RUTINITAS", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          const SizedBox(height: 8),
                          TextField(
                            onChanged: (val) => formTitle = val,
                            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              filled: true, fillColor: Colors.white.withValues(alpha: 0.05),
                              hintText: "Misal: Bayar Kosan", hintStyle: const TextStyle(color: Colors.white30),
                              prefixIcon: const Icon(Icons.edit_rounded, color: Colors.white54),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF9333EA))),
                            ),
                          ),
                          const SizedBox(height: 16),

                          const Text("TANGGAL JATUH TEMPO", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(context: context, initialDate: DateTime.parse(formDate), firstDate: DateTime(2000), lastDate: DateTime(2101));
                              if (picked != null) setModalState(() => formDate = picked.toIso8601String());
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded, color: Colors.white54, size: 20),
                                  const SizedBox(width: 12),
                                  Text(_getTanggalLengkap(DateTime.parse(formDate)), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: CustomButton(
                      text: "Simpan Jadwal", fullWidth: true,
                      onPressed: () {
                        if (formKategori.isEmpty) return _showToast("Pilih kategori rutinitasnya dulu ya!", isWarning: true);
                        if (formTitle.isEmpty) return _showToast("Nama rutinitas jangan dikosongin!", isWarning: true);
                        if (formNominal <= 0) return _showToast("Estimasi nominalnya berapa?", isWarning: true);

                        finance.addReminder(ReminderModel(
                          id: 'rem_${DateTime.now().millisecondsSinceEpoch}', title: formTitle, 
                          kategori: formKategori, dueDate: formDate, nominal: formNominal, userId: finance.currentUser!.id
                        ));
                        
                        Navigator.pop(context);
                        _showToast("Jadwal baru berhasil ditambahkan!");
                      },
                      variant: ButtonVariant.primary,
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // ⚡ MODAL BAYAR / SELESAIKAN JADWAL
  // ==========================================
  void _openPayModal(ReminderModel reminder, FinanceProvider finance) {
    HapticFeedback.mediumImpact();
    double payNominal = reminder.nominal;
    String payCatatan = '';
    String payTanggal = DateTime.now().toIso8601String();
    String payWallet = '';
    bool isRecurring = true;

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
                  const Text("Tandai Selesai", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  Text(reminder.title.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 32),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(child: Text("NOMINAL EKSEKUSI", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              CalculatorNumpad.show(context, initialCatatan: payCatatan, initialTanggal: payTanggal, onSubmit: (nom, cat, tgl) {
                                setModalState(() { payNominal = nom; payCatatan = cat; payTanggal = tgl; });
                              });
                            },
                            child: Container(
                              width: double.infinity, padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(color: const Color(0xFF9333EA).withValues(alpha:0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF9333EA).withValues(alpha:0.3))),
                              child: Column(
                                children: [
                                  Text(Formatters.formatCurrency(payNominal), style: const TextStyle(color: Color(0xFFD946EF), fontSize: 32, fontWeight: FontWeight.w900)),
                                  if (payCatatan.isNotEmpty) ...[const SizedBox(height: 8), Text("📝 $payCatatan", style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold))],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          const Text("BAYAR PAKAI DOMPET MANA?", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          const SizedBox(height: 8),
                          _buildWalletSelector(payWallet, finance, () {
                            _showWalletPicker(finance, (id) => setModalState(() => payWallet = id));
                          }),
                          const SizedBox(height: 24),

                          // Toggle Jadwalkan Ulang (Recurring)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                            child: Row(
                              children: [
                                Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF9333EA).withValues(alpha:0.2), shape: BoxShape.circle), child: const Icon(Icons.repeat_rounded, color: Color(0xFFD946EF), size: 16)),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Jadwalkan Ulang?", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                      Text("Otomatis buat tagihan bulan depan", style: TextStyle(color: Colors.white54, fontSize: 10)),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: isRecurring,
                                  onChanged: (val) { HapticFeedback.lightImpact(); setModalState(() => isRecurring = val); },
                                  activeThumbColor: const Color(0xFFD946EF), activeTrackColor: const Color(0xFF9333EA).withValues(alpha:0.5),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: CustomButton(
                      text: "Konfirmasi Selesai", fullWidth: true,
                      onPressed: () {
                        if (payWallet.isEmpty) return _showToast("Pilih dompet pembayarannya dulu!", isWarning: true);
                        if (payNominal <= 0) return _showToast("Nominal tidak valid!", isError: true);

                        final dompet = finance.mySumberDana.firstWhere((d) => d.idDana == payWallet);
                        if (dompet.saldoTerkini < payNominal) return _showToast("Saldo ${dompet.namaAset} nggak cukup!", isError: true);

                        finance.handleSaveTransaksi(TransactionModel(
                          idTransaksi: '', jenis: 'Pengeluaran', nominal: payNominal, idDana: payWallet,
                          idDanaTujuan: '', kategori: reminder.kategori,
                          keterangan: payCatatan.isNotEmpty ? payCatatan : "Bayar: ${reminder.title}",
                          tanggal: payTanggal, userId: finance.currentUser!.id,
                        ));

                        DateTime nextMonth = DateTime.parse(reminder.dueDate);
                        nextMonth = DateTime(nextMonth.year, nextMonth.month + 1, nextMonth.day);
                        
                        finance.payReminder(reminder.id, isRecurring, nextMonth);

                        Navigator.pop(context);
                        _showToast(isRecurring ? "Dibayar lunas! Jadwal bulan depan otomatis dibuat." : "Berhasil dibayar dan dicatat ke riwayat!");
                      },
                      variant: ButtonVariant.primary,
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(ReminderModel r, FinanceProvider finance) {
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
            const Text("Hapus Jadwal?", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text("Jadwal pengingat ini akan dihapus permanen. (Riwayat transaksi yang sudah terjadi tidak akan terhapus).", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 24),
            CustomButton(text: "Ya, Hapus", variant: ButtonVariant.danger, fullWidth: true, onPressed: () {
              finance.deleteReminder(r.id);
              Navigator.pop(context);
              _showToast("Jadwal berhasil dihapus.");
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
    final myRemindersData = finance.myReminders;

    // --- FILTER DATA ---
    List<ReminderModel> filteredReminders = myRemindersData.where((r) {
      if (_activeTab == 'SEMUA') return true;
      int days = Formatters.getDaysLeft(r.dueDate);
      if (_activeTab == 'MINGGU INI') return days >= 0 && days <= 7 && !r.isDone;
      if (_activeTab == 'LEWAT TENGGAT') return days < 0 && !r.isDone;
      return true;
    }).toList();

    List<ReminderModel> pending = filteredReminders.where((r) => !r.isDone).toList();
    List<ReminderModel> done = filteredReminders.where((r) => r.isDone).toList();
    double totalPendingNominal = pending.fold(0, (sum, r) => sum + r.nominal);
    ReminderModel? nextUrgent = pending.isNotEmpty ? pending.first : null;

    return Scaffold(
      backgroundColor: const Color(0xFF05010D),
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                    child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), shape: BoxShape.circle), child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
                  ),
                  const Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text("Pengingat", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                    Text("TAGIHAN & LANGGANAN", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF7C3AED), Color(0xFFD946EF)]),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: const Color(0xFFA855F7).withValues(alpha:0.3), blurRadius: 20)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: Colors.black.withValues(alpha:0.3), borderRadius: BorderRadius.circular(12)), child: const Row(children: [Icon(Icons.calendar_month_rounded, color: Color(0xFFD946EF), size: 14), SizedBox(width: 6), Text("BULAN INI", style: TextStyle(color: Color(0xFFD946EF), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.0))])),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text("ESTIMASI PENGELUARAN", style: TextStyle(color: Color(0xFFA855F7), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          Text(Formatters.formatCurrency(totalPendingNominal), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black45, blurRadius: 10)])),
                          const SizedBox(height: 24),
                          
                          if (nextUrgent != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.black.withValues(alpha:0.2), borderRadius: BorderRadius.circular(16)),
                              child: Row(
                                children: [
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    const Text("JADWAL TERDEKAT", style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                                    const SizedBox(height: 4),
                                    Text(nextUrgent.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                                  ])),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(color: Formatters.getDaysLeft(nextUrgent.dueDate) <= 3 ? Colors.amber.withValues(alpha:0.2) : Colors.white.withValues(alpha:0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Formatters.getDaysLeft(nextUrgent.dueDate) <= 3 ? Colors.amber.withValues(alpha:0.5) : Colors.white24)),
                                    child: Column(
                                      children: [
                                        Text(Formatters.getDaysLeft(nextUrgent.dueDate) < 0 ? '!' : '${Formatters.getDaysLeft(nextUrgent.dueDate)}', style: TextStyle(color: Formatters.getDaysLeft(nextUrgent.dueDate) <= 3 ? Colors.amber : Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                                        Text(Formatters.getDaysLeft(nextUrgent.dueDate) < 0 ? 'LEWAT' : Formatters.getDaysLeft(nextUrgent.dueDate) == 0 ? 'HARI INI' : 'HARI LAGI', style: TextStyle(color: Formatters.getDaysLeft(nextUrgent.dueDate) <= 3 ? Colors.amber : Colors.white54, fontSize: 8, fontWeight: FontWeight.w900)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            )
                          else
                            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.black.withValues(alpha:0.2), borderRadius: BorderRadius.circular(16)), child: const Row(children: [Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 24), SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Semua Beres!", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)), Text("Jadwal kamu bulan ini kosong.", style: TextStyle(color: Colors.white54, fontSize: 10))]))]))
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- TABS ---
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                      child: Row(
                        children: ['SEMUA', 'MINGGU INI', 'LEWAT TENGGAT'].map((tab) {
                          bool isActive = _activeTab == tab;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () { HapticFeedback.lightImpact(); setState(() => _activeTab = tab); },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(color: isActive ? Colors.white.withValues(alpha:0.1) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
                                alignment: Alignment.center,
                                child: Text(tab, style: TextStyle(color: isActive ? const Color(0xFFD946EF) : Colors.white54, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- LIST TERTUNDA ---
                    if (pending.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: Text(_activeTab == 'SEMUA' ? "Belum ada jadwal rutinitas." : "Aman! Nggak ada jadwal darurat.", style: TextStyle(color: Colors.white.withValues(alpha:0.3), fontWeight: FontWeight.bold))),
                      )
                    else
                      ...pending.map((r) {
                        int daysLeft = Formatters.getDaysLeft(r.dueDate);
                        bool isUrgent = daysLeft >= 0 && daysLeft <= 3;
                        bool isOverdue = daysLeft < 0;
                        var theme = _getTypeProps(r.kategori);

                        return GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 50, height: 50,
                                    decoration: BoxDecoration(color: isOverdue ? Colors.pinkAccent.withValues(alpha:0.1) : isUrgent ? Colors.amber.withValues(alpha:0.1) : const Color(0xFFA855F7).withValues(alpha:0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: isOverdue ? Colors.pinkAccent.withValues(alpha:0.3) : isUrgent ? Colors.amber.withValues(alpha:0.3) : const Color(0xFFA855F7).withValues(alpha:0.3))),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(_getBulanIndo(DateTime.parse(r.dueDate)), style: TextStyle(color: isOverdue ? Colors.pinkAccent : isUrgent ? Colors.amber : const Color(0xFFD946EF), fontSize: 10, fontWeight: FontWeight.w900)),
                                        Text(DateTime.parse(r.dueDate).day.toString().padLeft(2, '0'), style: TextStyle(color: isOverdue ? Colors.pinkAccent : isUrgent ? Colors.amber : const Color(0xFFA855F7), fontSize: 18, fontWeight: FontWeight.w900)),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(r.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(theme['icon'], color: theme['color'], size: 10),
                                            const SizedBox(width: 4),
                                            Text(r.kategori, style: TextStyle(color: theme['color'], fontSize: 10, fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 8),
                                            Text(isOverdue ? "LEWAT TENGGAT" : daysLeft == 0 ? "HARI INI" : "$daysLeft HARI LAGI", style: TextStyle(color: isOverdue ? Colors.pinkAccent : isUrgent ? Colors.amber : Colors.white54, fontSize: 10, fontWeight: FontWeight.w900)),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                  Text(Formatters.formatCurrency(r.nominal), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => _confirmDelete(r, finance),
                                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)), child: const Icon(Icons.delete_outline_rounded, color: Colors.white54, size: 20)),
                                  ),
                                  
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomButton(
                                      text: "Tandai Selesai / Bayar",
                                      variant: ButtonVariant.primary,
                                      onPressed: () => _openPayModal(r, finance),
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        );
                      }),

                    // --- LIST SELESAI ---
                    if (done.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Row(children: [Expanded(child: Divider(color: Colors.white10)), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text("RIWAYAT SELESAI", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0))), Expanded(child: Divider(color: Colors.white10))]),
                      ),
                      ...done.map((r) => GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha:0.1), shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: Colors.greenAccent, size: 16)),
                            const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(r.title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, decoration: TextDecoration.lineThrough)), const Text("Selesai Dibayar", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))])),
                            GestureDetector(onTap: () => _confirmDelete(r, finance), child: const Icon(Icons.delete_outline_rounded, color: Colors.white30, size: 18)),
                          ],
                        ),
                      )),
                    ],

                    const SizedBox(height: 24),
                    
                    // --- TOMBOL TAMBAH JADWAL BAWAH ---
                    CustomButton(
                      text: "Catat Jadwal Baru",
                      icon: Icons.add_rounded,
                      variant: ButtonVariant.secondary,
                      fullWidth: true,
                      onPressed: () => _openAddModal(finance),
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