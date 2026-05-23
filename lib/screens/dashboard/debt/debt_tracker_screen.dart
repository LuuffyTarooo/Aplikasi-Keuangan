// lib/screens/dashboard/debt/debt_tracker_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';
import 'package:aplikasi_keuangan/models/debt_model.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';
import 'package:aplikasi_keuangan/shared/widgets/custom_button.dart';
import 'package:aplikasi_keuangan/shared/widgets/custom_numpad.dart';

class DebtTrackerScreen extends StatefulWidget {
  const DebtTrackerScreen({super.key});

  @override
  State<DebtTrackerScreen> createState() => _DebtTrackerScreenState();
}

class _DebtTrackerScreenState extends State<DebtTrackerScreen> {
  String _filterTab = 'SEMUA';

  void _showToast(
    String message, {
    bool isError = false,
    bool isWarning = false,
  }) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.gpp_bad_rounded
                  : isWarning
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? Colors.pinkAccent
            : isWarning
            ? Colors.amber
            : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
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
        // 🟢 AUTO-SYNC: Pakai warna Background standar
        decoration: BoxDecoration(
          color: finance.themeBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: finance.themeBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Pilih Dompet",
              style: TextStyle(
                color: finance.themeText,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            ...finance.myWallets.map(
              (w) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () {
                    onSelect(w.walletId);
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: finance.themeCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: finance.themeBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: finance.themeAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.account_balance_wallet_rounded,
                            color: finance.themeAccent,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                w.walletName,
                                style: TextStyle(
                                  color: finance.themeText,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "Sisa: ${Formatters.formatCurrency(w.currentBalance)}",
                                style: TextStyle(
                                  color: finance.themeTextSub,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: finance.themeTextSub.withValues(alpha: 0.3),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletSelector(
    String selectedId,
    FinanceProvider finance,
    VoidCallback onTap,
  ) {
    final dompet = selectedId.isEmpty
        ? null
        : finance.myWallets.firstWhere(
            (d) => d.walletId == selectedId,
            orElse: () => finance.myWallets.first,
          );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: finance.themeCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: finance.themeBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: finance.themeAccent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet_rounded,
                color: finance.themeAccent,
                size: 16,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dompet == null ? "Pilih Dompet..." : dompet.walletName,
                    style: TextStyle(
                      color: dompet == null
                          ? finance.themeTextSub
                          : finance.themeText,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (dompet != null)
                    Text(
                      "Sisa: ${Formatters.formatCurrency(dompet.currentBalance)}",
                      style: TextStyle(
                        color: finance.themeTextSub,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: finance.themeTextSub,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ⚡ MODAL TAMBAH CATATAN
  // ==========================================
  void _openAddModal(String type, FinanceProvider finance) {
    HapticFeedback.mediumImpact();
    String formName = '';
    double formAmount = 0;
    String formCatatan = '';
    String formTanggal = DateTime.now().toIso8601String();
    String formWallet = '';

    bool isPiutang = type == 'PIUTANG';
    Color themeColor = isPiutang ? Colors.green : Colors.redAccent;

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
              decoration: BoxDecoration(
                color: finance.themeBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                border: Border(top: BorderSide(color: finance.themeBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPiutang ? "Pinjemin Temen" : "Gua Ngutang",
                    style: TextStyle(
                      color: finance.themeText,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    isPiutang
                        ? "UANG KELUAR (TAGIHAN KE ORANG)"
                        : "UANG MASUK (TAGIHAN PRIBADI)",
                    style: TextStyle(
                      color: finance.themeTextSub,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              "TOTAL NOMINAL",
                              style: TextStyle(
                                color: finance.themeTextSub,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              CalculatorNumpad.show(
                                context,
                                initialCatatan: formCatatan,
                                initialTanggal: formTanggal,
                                onSubmit: (nom, cat, tgl) {
                                  setModalState(() {
                                    formAmount = nom;
                                    formCatatan = cat;
                                    formTanggal = tgl;
                                  });
                                },
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: themeColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    Formatters.formatCurrency(formAmount),
                                    style: TextStyle(
                                      color: themeColor,
                                      fontSize: formAmount > 9999999 ? 24 : 32,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  if (formCatatan.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      "📝 $formCatatan",
                                      style: TextStyle(
                                        color: finance.themeTextSub,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              "Tgl Transaksi: ${DateFormat('dd MMM yyyy').format(DateTime.parse(formTanggal))}",
                              style: TextStyle(
                                color: finance.themeTextSub,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Text(
                            isPiutang
                                ? "SIAPA YANG PINJEM?"
                                : "PINJEM KE SIAPA?",
                            style: TextStyle(
                              color: finance.themeTextSub,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            onChanged: (val) => formName = val,
                            style: TextStyle(
                              color: finance.themeText,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: finance.themeCard,
                              prefixIcon: Icon(
                                Icons.person_rounded,
                                color: finance.themeTextSub,
                              ),
                              hintText: isPiutang
                                  ? "Misal: Ucup"
                                  : "Misal: Bank / Budi",
                              hintStyle: TextStyle(
                                color: finance.themeTextSub.withValues(
                                  alpha: 0.5,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: finance.themeBorder,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: finance.themeBorder,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: finance.themeAccent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Text(
                            isPiutang ? "AMBIL DARI DOMPET" : "MASUK KE DOMPET",
                            style: TextStyle(
                              color: finance.themeTextSub,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildWalletSelector(formWallet, finance, () {
                            _showWalletPicker(
                              finance,
                              (id) => setModalState(() => formWallet = id),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: CustomButton(
                      text: "Simpan Catatan",
                      fullWidth: true,
                      onPressed: () {
                        if (formName.isEmpty || formAmount <= 0)
                          return _showToast(
                            "Isi nama & nominal dengan benar!",
                            isWarning: true,
                          );
                        if (formWallet.isEmpty)
                          return _showToast(
                            "Pilih dompet dulu!",
                            isWarning: true,
                          );

                        final dompet = finance.myWallets.firstWhere(
                          (d) => d.walletId == formWallet,
                        );
                        if (isPiutang && dompet.currentBalance < formAmount)
                          return _showToast(
                            "Saldo ${dompet.walletName} nggak cukup buat minjemin!",
                            isError: true,
                          );

                        final newDebt = DebtModel(
                          id: 'debt_${DateTime.now().millisecondsSinceEpoch}',
                          name: formName,
                          type: type,
                          amount: formAmount,
                          catatan: formCatatan,
                          txDates: [formTanggal],
                          userId: finance.currentUser!.id,
                        );
                        finance.addDebt(newDebt);

                        finance.handleSaveTransaksi(
                          TransactionModel(
                            idTransaksi: '',
                            jenis: isPiutang ? 'Pengeluaran' : 'Pemasukan',
                            nominal: formAmount,
                            walletId: formWallet,
                            kategori: isPiutang ? 'Piutang' : 'Hutang',
                            keterangan: formCatatan.isNotEmpty
                                ? formCatatan
                                : (isPiutang
                                      ? "Pinjaman ke $formName"
                                      : "Pinjaman dari $formName"),
                            tanggal: formTanggal,
                            userId: finance.currentUser!.id,
                          ),
                        );

                        Navigator.pop(context);
                        _showToast("Catatan berhasil disimpan!");
                      },
                      variant: ButtonVariant.primary,
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

  // ==========================================
  // ⚡ MODAL PELUNASAN / BAYAR CICILAN
  // ==========================================
  void _openPayModal(DebtModel debt, FinanceProvider finance) {
    HapticFeedback.mediumImpact();
    double sisa = debt.amount - debt.paid;
    double payAmount = sisa;
    String payCatatan = '';
    String payTanggal = DateTime.now().toIso8601String();
    String payWallet = '';

    bool isPiutang = debt.type == 'PIUTANG';
    Color themeColor = isPiutang ? Colors.green : Colors.redAccent;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: finance.themeBg,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                border: Border(top: BorderSide(color: finance.themeBorder)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isPiutang
                        ? "Terima dari: ${debt.name}"
                        : "Bayar ke: ${debt.name}",
                    style: TextStyle(
                      color: finance.themeText,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    "SISA TAGIHAN: ${Formatters.formatCurrency(sisa)}",
                    style: TextStyle(
                      color: finance.themeTextSub,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              "NOMINAL PEMBAYARAN",
                              style: TextStyle(
                                color: finance.themeTextSub,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () {
                              CalculatorNumpad.show(
                                context,
                                initialCatatan: payCatatan,
                                initialTanggal: payTanggal,
                                onSubmit: (nom, cat, tgl) {
                                  setModalState(() {
                                    payAmount = nom;
                                    payCatatan = cat;
                                    payTanggal = tgl;
                                  });
                                },
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: themeColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    Formatters.formatCurrency(payAmount),
                                    style: TextStyle(
                                      color: themeColor,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  if (payCatatan.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      "📝 $payCatatan",
                                      style: TextStyle(
                                        color: finance.themeTextSub,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              "Bisa diisi sebagian untuk cicilan",
                              style: TextStyle(
                                color: finance.themeTextSub.withValues(
                                  alpha: 0.5,
                                ),
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          Text(
                            isPiutang
                                ? "UANGNYA MASUK KE DOMPET MANA?"
                                : "BAYAR PAKAI DOMPET MANA?",
                            style: TextStyle(
                              color: finance.themeTextSub,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildWalletSelector(payWallet, finance, () {
                            _showWalletPicker(
                              finance,
                              (id) => setModalState(() => payWallet = id),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),

                  CustomButton(
                    text: isPiutang
                        ? "Konfirmasi Terima Dana"
                        : "Konfirmasi Pembayaran",
                    fullWidth: true,
                    onPressed: () {
                      if (payWallet.isEmpty)
                        return _showToast(
                          "Pilih dompet dulu!",
                          isWarning: true,
                        );
                      if (payAmount <= 0 || payAmount > sisa)
                        return _showToast(
                          "Nominal tidak valid!",
                          isError: true,
                        );

                      final dompet = finance.myWallets.firstWhere(
                        (d) => d.walletId == payWallet,
                      );
                      if (!isPiutang && dompet.currentBalance < payAmount)
                        return _showToast(
                          "Saldo ${dompet.walletName} kurang!",
                          isError: true,
                        );

                      finance.handleSaveTransaksi(
                        TransactionModel(
                          idTransaksi: '',
                          jenis: isPiutang ? 'Pemasukan' : 'Pengeluaran',
                          nominal: payAmount,
                          walletId: payWallet,
                          kategori: isPiutang ? 'Piutang' : 'Hutang',
                          keterangan: payCatatan.isNotEmpty
                              ? payCatatan
                              : (isPiutang
                                    ? "Terima pembayaran dari ${debt.name}"
                                    : "Bayar tagihan ke ${debt.name}"),
                          tanggal: payTanggal,
                          userId: finance.currentUser!.id,
                        ),
                      );

                      finance.payDebt(debt.id, payAmount, payTanggal);

                      Navigator.pop(context);
                      _showToast("Pembayaran dicatat!");
                    },
                    variant: ButtonVariant.primary,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ==========================================
  // ⚡ MODAL KONFIRMASI HAPUS & REVERT DANA
  // ==========================================
  void _confirmDelete(DebtModel debt, FinanceProvider finance) {
    bool isPiutang = debt.type == 'PIUTANG';
    double sisa = debt.amount - debt.paid;
    String revertWallet = '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: finance.themeBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: finance.themeBorder),
              ),
              contentPadding: const EdgeInsets.all(24),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Hapus Catatan?",
                    style: TextStyle(
                      color: finance.themeText,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (debt.isCompleted)
                    Text(
                      "Catatan ini sudah lunas. Riwayat transaksinya tidak akan terhapus, aman bro.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: finance.themeTextSub,
                        fontSize: 12,
                      ),
                    )
                  else ...[
                    Text(
                      "Catatan ini belum lunas! Sisa dana ${Formatters.formatCurrency(sisa)} akan dikembalikan untuk menyesuaikan saldo.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isPiutang ? "KEMBALIKAN KE DOMPET" : "TARIK DARI DOMPET",
                      style: TextStyle(
                        color: finance.themeTextSub,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildWalletSelector(revertWallet, finance, () {
                      _showWalletPicker(
                        finance,
                        (id) => setDialogState(() => revertWallet = id),
                      );
                    }),
                  ],

                  const SizedBox(height: 24),
                  CustomButton(
                    text: "Ya, Hapus",
                    variant: ButtonVariant.danger,
                    fullWidth: true,
                    onPressed: () {
                      if (!debt.isCompleted) {
                        if (revertWallet.isEmpty)
                          return _showToast(
                            "Pilih dompet kembaliannya dulu Jar!",
                            isWarning: true,
                          );

                        final dompet = finance.myWallets.firstWhere(
                          (d) => d.walletId == revertWallet,
                        );
                        if (!isPiutang && dompet.currentBalance < sisa)
                          return _showToast(
                            "Saldo ${dompet.walletName} lu nggak cukup buat ngebatalin hutang ini!",
                            isError: true,
                          );

                        finance.handleSaveTransaksi(
                          TransactionModel(
                            idTransaksi: '',
                            jenis: isPiutang ? 'Pemasukan' : 'Pengeluaran',
                            nominal: sisa,
                            walletId: revertWallet,
                            kategori: 'Lainnya',
                            keterangan: "Pembatalan ${debt.type}: ${debt.name}",
                            tanggal: DateTime.now().toIso8601String(),
                            userId: finance.currentUser!.id,
                          ),
                        );
                      }

                      finance.deleteDebt(debt.id);
                      Navigator.pop(context);
                      _showToast("Catatan dihapus & saldo disesuaikan.");
                    },
                  ),
                  const SizedBox(height: 8),
                  CustomButton(
                    text: "Batal",
                    variant: ButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () => Navigator.pop(context),
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
    final myDebtsData = finance.myDebts;

    double totalPiutang = myDebtsData
        .where((d) => d.type == 'PIUTANG' && !d.isCompleted)
        .fold(0, (sum, d) => sum + (d.amount - d.paid));
    double totalHutang = myDebtsData
        .where((d) => d.type == 'HUTANG' && !d.isCompleted)
        .fold(0, (sum, d) => sum + (d.amount - d.paid));

    List<DebtModel> filteredDebts = myDebtsData
        .where((d) => _filterTab == 'SEMUA' || d.type == _filterTab)
        .toList();
    List<DebtModel> activeDebts = filteredDebts
        .where((d) => !d.isCompleted)
        .toList();
    List<DebtModel> completedDebts = filteredDebts
        .where((d) => d.isCompleted)
        .toList();

    return Scaffold(
      backgroundColor: finance.themeBg, // 🟢 AUTO-SYNC
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: finance.themeCard,
                        shape: BoxShape.circle,
                        border: Border.all(color: finance.themeBorder),
                      ),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: finance.themeText,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pengingat",
                        style: TextStyle(
                          color: finance.themeText,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        "UTANG & PIUTANG",
                        style: TextStyle(
                          color: finance.themeTextSub,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // --- KARTU RINGKASAN ---
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: finance.themeCard,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: finance.themeBorder),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.people_alt_rounded,
                                color: finance.themeText,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Rekap Global",
                                style: TextStyle(
                                  color: finance.themeText,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: finance.themeBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: finance.themeBorder,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "UANG GUA DI LUAR",
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        Formatters.formatCurrency(totalPiutang),
                                        style: TextStyle(
                                          color: finance.themeText,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: finance.themeBg,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: finance.themeBorder,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "GUA NGUTANG",
                                        style: TextStyle(
                                          color: Colors.redAccent,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        Formatters.formatCurrency(totalHutang),
                                        style: TextStyle(
                                          color: finance.themeText,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- TOMBOL TAMBAH ---
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _openAddModal('PIUTANG', finance),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: finance.themeCard,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: finance.themeBorder),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.15,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.arrow_outward_rounded,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Pinjemin Temen",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _openAddModal('HUTANG', finance),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: finance.themeCard,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: finance.themeBorder),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withValues(
                                        alpha: 0.15,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.call_received_rounded,
                                      color: Colors.redAccent,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Gua Ngutang",
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // --- TAB FILTER ---
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: finance.themeCard,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: finance.themeBorder),
                      ),
                      child: Row(
                        children: ['SEMUA', 'PIUTANG', 'HUTANG'].map((tab) {
                          bool isActive = _filterTab == tab;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() => _filterTab = tab);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? finance.themeAccent.withValues(
                                          alpha: 0.15,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  tab,
                                  style: TextStyle(
                                    color: isActive
                                        ? finance.themeAccent
                                        : finance.themeTextSub,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- LIST AKTIF ---
                    if (activeDebts.isEmpty && completedDebts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            "Nggak ada catatan di sini.",
                            style: TextStyle(
                              color: finance.themeTextSub,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    else
                      ...activeDebts.map((debt) {
                        bool isPiutang = debt.type == 'PIUTANG';
                        double sisa = debt.amount - debt.paid;
                        double progress = (debt.paid / debt.amount).clamp(
                          0.0,
                          1.0,
                        );
                        Color color = isPiutang
                            ? Colors.green
                            : Colors.redAccent;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: finance.themeCard,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: finance.themeBorder),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      isPiutang
                                          ? Icons.arrow_outward_rounded
                                          : Icons.call_received_rounded,
                                      color: color,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          isPiutang
                                              ? "YANG PINJEM:"
                                              : "PEMBERI PINJAMAN:",
                                          style: TextStyle(
                                            color: color,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                        Text(
                                          debt.name.toUpperCase(),
                                          style: TextStyle(
                                            color: finance.themeText,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        "SISA TAGIHAN",
                                        style: TextStyle(
                                          color: finance.themeTextSub,
                                          fontSize: 8,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.0,
                                        ),
                                      ),
                                      Text(
                                        Formatters.formatCurrency(sisa),
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Progress Bar
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: finance.themeBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: finance.themeBorder,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Telah dibayar: ${Formatters.formatCurrency(debt.paid)}",
                                          style: TextStyle(
                                            color: finance.themeTextSub,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "${(progress * 100).toInt()}%",
                                          style: TextStyle(
                                            color: finance.themeText,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: finance.themeBorder,
                                      color: color,
                                      minHeight: 6,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Tombol Aksi
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomButton(
                                      text: isPiutang
                                          ? "Terima Cicilan"
                                          : "Bayar Cicilan",
                                      icon: Icons.check_circle_outline_rounded,
                                      variant: ButtonVariant.primary,
                                      onPressed: () =>
                                          _openPayModal(debt, finance),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => _confirmDelete(debt, finance),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(24),
                                        border: Border.all(
                                          color: Colors.redAccent.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.redAccent,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),

                    // --- LIST LUNAS ---
                    if (completedDebts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Divider(color: finance.themeBorder),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                "RIWAYAT LUNAS",
                                style: TextStyle(
                                  color: finance.themeTextSub,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2.0,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Divider(color: finance.themeBorder),
                            ),
                          ],
                        ),
                      ),
                      ...completedDebts.map(
                        (debt) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: finance.themeCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: finance.themeBorder),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: finance.themeBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  debt.type == 'PIUTANG'
                                      ? Icons.arrow_outward_rounded
                                      : Icons.call_received_rounded,
                                  color: finance.themeTextSub,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      debt.name.toUpperCase(),
                                      style: TextStyle(
                                        color: finance.themeText,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    const Text(
                                      "Berhasil Dilunasi",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                Formatters.formatCurrency(debt.amount),
                                style: TextStyle(
                                  color: finance.themeTextSub,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(width: 12),
                              GestureDetector(
                                onTap: () => _confirmDelete(debt, finance),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  color: finance.themeTextSub.withValues(
                                    alpha: 0.5,
                                  ),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
