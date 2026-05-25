// lib/shared/bottom_sheets/transaction_detail_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart';

import '../../providers/finance_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/wallet_model.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/wallet_logo_resolver.dart';
import '../widgets/wallet_logo_widget.dart';
import '../widgets/custom_button.dart';

class TransactionDetailSheet {
  static void show({
    required BuildContext context,
    required TransactionModel transaction,
    required List<WalletModel> sumberDana,
    required Function(TransactionModel) onEdit,
    required Function(TransactionModel) onDelete,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DetailContent(
        transaction: transaction,
        sumberDana: sumberDana,
        onEdit: onEdit,
        onDelete: onDelete,
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final TransactionModel transaction;
  final List<WalletModel> sumberDana;
  final Function(TransactionModel) onEdit;
  final Function(TransactionModel) onDelete;

  const _DetailContent({
    required this.transaction,
    required this.sumberDana,
    required this.onEdit,
    required this.onDelete,
  });

  String _getCustomDate(String isoString) {
    try {
      final parsedDate = DateTime.parse(isoString);
      final List<String> fullMonths = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni', 
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      String day = parsedDate.day.toString().padLeft(2, '0');
      String month = fullMonths[parsedDate.month - 1];
      return "$day $month ${parsedDate.year}";
    } catch (_) {
      return "Format Tanggal Salah";
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    final dateObj = DateTime.parse(transaction.tanggal);
    
    final tanggal = _getCustomDate(transaction.tanggal); 
    final jam = DateFormat('HH:mm').format(dateObj); 

    final isPemasukan = transaction.jenis == 'Pemasukan';
    final isTransfer = transaction.jenis == 'Transfer';
    final dompet = sumberDana.firstWhere((d) => d.walletId == transaction.walletId, orElse: () => sumberDana.first).walletName;
    
    String? targetDompet;
    if (isTransfer && transaction.targetWalletId != null) {
      targetDompet = sumberDana.firstWhere((d) => d.walletId == transaction.targetWalletId, orElse: () => sumberDana.first).walletName;
    }

    // 🟢 TEMA DINAMIS
    final katModel = finance.getCategoryByName(transaction.kategori);

    Color glowColor = katModel.accentColor;
    Color textColor = finance.themeText; 
    IconData iconData = katModel.icon;
    String prefix = '-';

    if (isPemasukan) {
      textColor = Colors.greenAccent;
      prefix = '+';
    } else if (isTransfer) {
      glowColor = finance.themeAccent;
      iconData = Icons.sync_alt_rounded;
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: finance.themeBg, // 🟢 Pakai Theme
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: finance.themeBorder), // 🟢 Pakai Theme
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- HEADER GLOW ---
          Container(
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [glowColor.withValues(alpha:0.15), Colors.transparent],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              border: Border(bottom: BorderSide(color: finance.themeBorder)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: finance.themeCard, shape: BoxShape.circle, border: Border.all(color: finance.themeBorder)),
                      child: Icon(Icons.close_rounded, color: finance.themeTextSub, size: 20),
                    ),
                  ),
                ),
                Column(
                  children: [
                    // Badge dihapus, diganti teks minimalis
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(iconData, size: 14, color: glowColor),
                        const SizedBox(width: 6),
                        Text(transaction.jenis.toUpperCase(), style: TextStyle(color: finance.themeTextSub, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.5)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "$prefix${Formatters.formatCurrency(transaction.nominal)}",
                      style: TextStyle(
                        fontSize: transaction.nominal.toString().length > 7 ? 28 : 36,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- KONTEN DETAIL ---
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  transaction.keterangan.isEmpty ? 'Tanpa Keterangan' : transaction.keterangan,
                  style: TextStyle(color: finance.themeText, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.kategori.toUpperCase(),
                  style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(height: 24),

                // Kotak Detail Kaca
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: finance.themeCard,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: finance.themeBorder),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(
                        finance: finance, 
                        icon: Icons.account_balance_wallet_rounded, 
                        label: "Metode Pembayaran", 
                        valueWidget: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            WalletLogoWidget(walletName: dompet, size: 'sm'),
                            if (!WalletLogoResolver.hasLogo(dompet)) const SizedBox(width: 4),
                            if (!WalletLogoResolver.hasLogo(dompet)) Text(dompet, style: TextStyle(color: finance.themeText, fontWeight: FontWeight.bold, fontSize: 14)),
                            if (isTransfer && targetDompet != null) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 14, color: finance.themeTextSub),
                              const SizedBox(width: 8),
                              WalletLogoWidget(walletName: targetDompet, size: 'sm'),
                              if (!WalletLogoResolver.hasLogo(targetDompet)) const SizedBox(width: 4),
                              if (!WalletLogoResolver.hasLogo(targetDompet)) Text(targetDompet, style: TextStyle(color: finance.themeText, fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _DetailRow(finance: finance, icon: Icons.calendar_month_rounded, label: "Tanggal", value: tanggal),
                      const SizedBox(height: 16),
                      _DetailRow(finance: finance, icon: Icons.access_time_rounded, label: "Waktu", value: "$jam WIB"),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Tombol Aksi
                Row(
                  children: [
                    CustomButton(
                      text: "",
                      icon: Icons.delete_outline_rounded,
                      variant: ButtonVariant.danger,
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: finance.themeBg,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: finance.themeBorder)),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha:0.1), shape: BoxShape.circle), child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 32)),
                                const SizedBox(height: 16),
                                Text("Hapus Transaksi?", style: TextStyle(color: finance.themeText, fontSize: 18, fontWeight: FontWeight.w900)),
                                const SizedBox(height: 8),
                                Text("Beneran mau dihapus nih transaksinya?", textAlign: TextAlign.center, style: TextStyle(color: finance.themeTextSub, fontSize: 12)),
                                const SizedBox(height: 24),
                                CustomButton(text: "Ya, Hapus", variant: ButtonVariant.danger, fullWidth: true, onPressed: () {
                                  Navigator.pop(context); // Tutup dialog
                                  Navigator.pop(context); // Tutup bottom sheet
                                  onDelete(transaction);
                                }),
                                const SizedBox(height: 8),
                                CustomButton(text: "Batal", variant: ButtonVariant.secondary, fullWidth: true, onPressed: () => Navigator.pop(context)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: "Ubah Catatan",
                        icon: Icons.edit_outlined,
                        variant: ButtonVariant.primary,
                        fullWidth: true,
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          Navigator.pop(context);
                          onEdit(transaction);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final FinanceProvider finance;
  final IconData icon;
  final String label;
  final String? value;
  final Widget? valueWidget;

  const _DetailRow({required this.finance, required this.icon, required this.label, this.value, this.valueWidget});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: finance.themeBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: finance.themeBorder)),
          child: Icon(icon, color: finance.themeTextSub, size: 16),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              if (valueWidget != null) valueWidget! else Text(value ?? '', style: TextStyle(color: finance.themeText, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}