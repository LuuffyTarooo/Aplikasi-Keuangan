// lib/shared/sheets/manage_wallets_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/models/wallet_model.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';
import 'package:aplikasi_keuangan/core/utils/wallet_helper.dart';
import 'package:aplikasi_keuangan/shared/widgets/custom_button.dart';

class ManageWalletsSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _ManageWalletsContent(),
    );
  }
}

class _ManageWalletsContent extends StatefulWidget {
  const _ManageWalletsContent();

  @override
  State<_ManageWalletsContent> createState() => _ManageWalletsContentState();
}

class _ManageWalletsContentState extends State<_ManageWalletsContent> {
  // Fungsi Helper Menghitung Jumlah Transaksi di suatu Dompet
  int _getTransactionCount(String idDana, FinanceProvider finance) {
    return finance.myTransaksi.where((t) => t.idDana == idDana).length;
  }

  void _handleAction(WalletModel wallet, String actionType, FinanceProvider finance) {
    HapticFeedback.heavyImpact();
    
    if (actionType == 'delete') {
      finance.deleteSumberDana(wallet.idDana); 
    } else if (actionType == 'archive' || actionType == 'unarchive') {
      finance.toggleArsipSumberDana(wallet.idDana);
    }
  }

  // MODAL KONFIRMASI (Tumpuk di atas BottomSheet)
  void _showConfirmDialog(WalletModel wallet, String type, int txCount, FinanceProvider finance) {
    HapticFeedback.mediumImpact();
    int step = 1;
    String deleteInput = "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            
            // --- Tampilan Dialog Arsip / Unarchive ---
            if (type == 'archive' || type == 'unarchive') {
              return AlertDialog(
                backgroundColor: finance.themeBg, // 🟢 AUTO-SYNC
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: finance.themeBorder)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: type == 'archive' ? Colors.blueAccent.withValues(alpha:0.1) : Colors.green.withValues(alpha:0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: type == 'archive' ? Colors.blueAccent.withValues(alpha:0.3) : Colors.green.withValues(alpha:0.3)),
                      ),
                      child: Icon(type == 'archive' ? Icons.archive_rounded : Icons.unarchive_rounded, size: 40, color: type == 'archive' ? Colors.blueAccent : Colors.green),
                    ),
                    const SizedBox(height: 24),
                    Text(type == 'archive' ? 'Arsipkan Dompet?' : 'Aktifkan Dompet?', style: TextStyle(color: finance.themeText, fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(
                      type == 'archive' ? 'Dompet "${wallet.namaAset}" akan disembunyikan dari dashboard.' : 'Dompet "${wallet.namaAset}" akan muncul lagi di dashboard.',
                      textAlign: TextAlign.center, style: TextStyle(color: finance.themeTextSub, fontSize: 12),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: type == 'archive' ? "Ya, Arsipkan" : "Ya, Aktifkan",
                      variant: ButtonVariant.primary,
                      fullWidth: true,
                      onPressed: () {
                        _handleAction(wallet, type, finance);
                        Navigator.pop(context); // Tutup dialog
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomButton(text: "Batal", variant: ButtonVariant.secondary, fullWidth: true, onPressed: () => Navigator.pop(context)),
                  ],
                ),
              );
            }

            // --- Tampilan Dialog Hapus (Step 1) ---
            if (type == 'delete' && step == 1) {
              return AlertDialog(
                backgroundColor: finance.themeBg, // 🟢 AUTO-SYNC
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: finance.themeBorder)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha:0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.redAccent.withValues(alpha:0.3))),
                      child: const Icon(Icons.delete_rounded, size: 40, color: Colors.redAccent),
                    ),
                    const SizedBox(height: 24),
                    Text('Hapus Dompet?', style: TextStyle(color: finance.themeText, fontSize: 20, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text(
                      txCount > 0 ? 'Ada $txCount transaksi di dompet "${wallet.namaAset}". Yakin mau hapus permanen?' : 'Dompet "${wallet.namaAset}" masih kosong. Yakin mau dihapus?',
                      textAlign: TextAlign.center, style: TextStyle(color: finance.themeTextSub, fontSize: 12),
                    ),
                    const SizedBox(height: 32),
                    CustomButton(text: "Ya, Lanjut Hapus", variant: ButtonVariant.danger, fullWidth: true, onPressed: () => setDialogState(() => step = 2)),
                    const SizedBox(height: 12),
                    CustomButton(text: "Batal", variant: ButtonVariant.secondary, fullWidth: true, onPressed: () => Navigator.pop(context)),
                  ],
                ),
              );
            }

            // --- Tampilan Dialog Hapus Lapis 2 (Ngetik HAPUS) ---
            return AlertDialog(
              backgroundColor: finance.themeBg, // 🟢 AUTO-SYNC
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: finance.themeBorder)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha:0.2), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.redAccent, width: 2)),
                    child: const Icon(Icons.gpp_bad_rounded, size: 40, color: Colors.redAccent),
                  ),
                  const SizedBox(height: 24),
                  const Text('Peringatan Terakhir!', style: TextStyle(color: Colors.redAccent, fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 8),
                  const Text('Semua kaitan transaksi dengan dompet ini akan hilang permanen.', textAlign: TextAlign.center, style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 24),
                  
                  Text('Ketik "HAPUS" untuk konfirmasi:', style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 8),
                  
                  TextField(
                    onChanged: (val) => setDialogState(() => deleteInput = val.toUpperCase()),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 4),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: finance.themeCard,
                      hintText: "HAPUS",
                      hintStyle: TextStyle(color: Colors.redAccent.withValues(alpha:0.3)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: finance.themeBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: finance.themeBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.redAccent, width: 2)),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: CustomButton(text: "Kembali", variant: ButtonVariant.secondary, onPressed: () => setDialogState(() => step = 1))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: "MUSNAHKAN",
                          variant: deleteInput == 'HAPUS' ? ButtonVariant.danger : ButtonVariant.secondary,
                          onPressed: deleteInput == 'HAPUS' ? () {
                            _handleAction(wallet, 'delete', finance);
                            Navigator.pop(context); // Tutup dialog
                          } : null,
                        ),
                      ),
                    ],
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

    // Pisahin dompet aktif & non-aktif
    List<WalletModel> activeWallets = finance.mySumberDana.where((w) => w.isActive).toList();
    List<WalletModel> archivedWallets = finance.mySumberDana.where((w) => !w.isActive).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: finance.themeBg, // 🟢 AUTO-SYNC Latar Solid
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        border: Border(top: BorderSide(color: finance.themeBorder)),
      ),
      child: Column(
        children: [
          // Header Modal
          Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: finance.themeBorder))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Kelola Dompet", style: TextStyle(color: finance.themeText, fontSize: 18, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text("Total ${activeWallets.length} Aktif", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ],
                ),
                GestureDetector(
                  onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: finance.themeCard, shape: BoxShape.circle, border: Border.all(color: finance.themeBorder)),
                    child: Icon(Icons.close_rounded, color: finance.themeTextSub, size: 20),
                  ),
                ),
              ],
            ),
          ),

          // Konten List Dompet
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("DOMPET UTAMA", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  const SizedBox(height: 12),
                  ...activeWallets.map((w) {
                    int txCount = _getTransactionCount(w.idDana, finance);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: finance.themeBorder)),
                        child: Row(
                          children: [
                            WalletHelper.getWalletLogo(w.namaAset, size: 'md'),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(w.namaAset, style: TextStyle(color: finance.themeText, fontSize: 14, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(Formatters.formatCurrency(w.saldoTerkini), style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                                ],
                              ),
                            ),
                            // Tombol Aksi Flat
                            if (txCount > 0)
                              GestureDetector(
                                onTap: () => _showConfirmDialog(w, 'archive', txCount, finance),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(color: finance.themeBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: finance.themeBorder)),
                                  child: Icon(Icons.archive_outlined, color: finance.themeTextSub, size: 18),
                                ),
                              ),
                            GestureDetector(
                              onTap: () => _showConfirmDialog(w, 'delete', txCount, finance),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: finance.themeBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: finance.themeBorder)),
                                child: Icon(Icons.delete_outline_rounded, color: finance.themeTextSub, size: 18),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  if (archivedWallets.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    Text("DOMPET DIARSIPKAN", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 12),
                    ...archivedWallets.map((w) {
                      int txCount = _getTransactionCount(w.idDana, finance);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Opacity(
                          opacity: 0.5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: finance.themeBorder)),
                            child: Row(
                              children: [
                                WalletHelper.getWalletLogo(w.namaAset, size: 'md'),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(w.namaAset, style: TextStyle(color: finance.themeText, fontSize: 14, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text("NON-AKTIF • $txCount Transaksi", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _showConfirmDialog(w, 'unarchive', txCount, finance),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(color: finance.themeBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: finance.themeBorder)),
                                    child: Icon(Icons.unarchive_outlined, color: finance.themeTextSub, size: 18),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _showConfirmDialog(w, 'delete', txCount, finance),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: finance.themeBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: finance.themeBorder)),
                                    child: Icon(Icons.delete_outline_rounded, color: finance.themeTextSub, size: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}