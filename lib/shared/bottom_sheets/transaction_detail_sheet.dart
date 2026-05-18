// lib/shared/bottom_sheets/transaction_detail_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart'; // Tetep import intl karena masih butuh buat Formatters.formatCurrency sama jam ('HH:mm')

import '../../models/transaction_model.dart';
import '../../models/wallet_model.dart';
import '../../core/utils/formatters.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_badge.dart';

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

  // 🟢 LOGIKA MANUAL PENGGANTI DATEFORMAT INTL BIAR ANTI-EROR
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
    final dateObj = DateTime.parse(transaction.tanggal);
    
    // 🟢 PAKAI FUNGSI CUSTOM BUATAN KITA!
    final tanggal = _getCustomDate(transaction.tanggal); 
    
    // Jam masih aman pake DateFormat soalnya gak pake id_ID
    final jam = DateFormat('HH:mm').format(dateObj); 

    final isPemasukan = transaction.jenis == 'Pemasukan';
    final isTransfer = transaction.jenis == 'Transfer';
    final dompet = sumberDana.firstWhere((d) => d.idDana == transaction.idDana, orElse: () => sumberDana.first).namaAset;

    // Tema dinamis
    Color glowColor = Colors.pinkAccent;
    Color textColor = Colors.pinkAccent;
    BadgeVariant badgeType = BadgeVariant.danger;
    IconData iconData = Icons.trending_up_rounded;
    String prefix = '-';

    if (isPemasukan) {
      glowColor = Colors.greenAccent;
      textColor = Colors.greenAccent;
      badgeType = BadgeVariant.success;
      iconData = Icons.trending_down_rounded;
      prefix = '+';
    } else if (isTransfer) {
      glowColor = const Color(0xFF3B82F6);
      textColor = const Color(0xFF3B82F6);
      badgeType = BadgeVariant.info;
      iconData = Icons.sync_alt_rounded;
      prefix = '-';
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withValues(alpha:0.95),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: Colors.white10),
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
                colors: [glowColor.withValues(alpha:0.2), Colors.transparent],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
              border: const Border(bottom: BorderSide(color: Colors.white10)),
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
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), shape: BoxShape.circle),
                      child: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    ),
                  ),
                ),
                Column(
                  children: [
                    CustomBadge(text: transaction.jenis, icon: iconData, variant: badgeType),
                    const SizedBox(height: 12),
                    Text(
                      "$prefix${Formatters.formatCurrency(transaction.nominal)}",
                      style: TextStyle(
                        fontSize: transaction.nominal.toString().length > 7 ? 28 : 36,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        shadows: [Shadow(color: textColor, blurRadius: 15)],
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
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.kategori.toUpperCase(),
                  style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                ),
                const SizedBox(height: 24),

                // Kotak Detail Kaca
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha:0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      _DetailRow(icon: Icons.account_balance_wallet_rounded, label: "Metode Pembayaran", value: dompet),
                      const SizedBox(height: 16),
                      _DetailRow(icon: Icons.calendar_month_rounded, label: "Tanggal", value: tanggal),
                      const SizedBox(height: 16),
                      _DetailRow(icon: Icons.access_time_rounded, label: "Waktu", value: "$jam WIB"),
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
                        Navigator.pop(context);
                        onDelete(transaction);
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
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: Colors.white54, size: 16),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(), style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }
}