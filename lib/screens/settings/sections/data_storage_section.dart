// lib/screens/settings/sheets/data_storage_sheet.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/shared/widgets/custom_button.dart';

class DataStorageSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _DataStorageContent(),
    );
  }
}

class _DataStorageContent extends StatefulWidget {
  const _DataStorageContent();

  @override
  State<_DataStorageContent> createState() => _DataStorageContentState();
}

class _DataStorageContentState extends State<_DataStorageContent> {
  
  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return; 

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.gpp_bad_rounded : Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: isError ? Colors.pinkAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  // ==========================================
  // ⚡ FUNGSI: BACKUP DATA (COPY TO CLIPBOARD)
  // ==========================================
  void _handleBackupData(FinanceProvider finance) async {
    HapticFeedback.heavyImpact();
    
    try {
      Map<String, dynamic> allData = {
        'sumberDana': finance.mySumberDana.map((e) => e.namaAset).toList(), 
        'transaksi': finance.myTransaksi.map((e) => e.keterangan).toList(),
        'backupDate': DateTime.now().toIso8601String(),
        'versi': '1.0.0',
      };

      String jsonString = jsonEncode(allData);
      await Clipboard.setData(ClipboardData(text: jsonString));

      if (!mounted) return;

      _showToast("✅ Data berhasil di-backup! Teks JSON sudah disalin. Silakan tempel (Paste) di Notes/WhatsApp lu.");
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showToast("❌ Gagal melakukan backup data.", isError: true);
    }
  }

  // ==========================================
  // ⚡ FUNGSI: RESTORE DATA (PASTE JSON DIALOG)
  // ==========================================
  void _handleRestoreData(FinanceProvider finance) {
    HapticFeedback.mediumImpact();
    String pastedJson = "";

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: finance.themeBg, // 🟢 AUTO-SYNC Latar Solid
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: finance.themeBorder)),
          title: Row(
            children: [
              const Icon(Icons.upload_file_rounded, color: Colors.orangeAccent),
              const SizedBox(width: 8),
              Text("Restore Data", style: TextStyle(color: finance.themeText, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Tempel (Paste) teks JSON backup lu di kotak bawah ini. Peringatan: Data lama akan tertimpa sepenuhnya!", style: TextStyle(color: finance.themeTextSub, fontSize: 12)),
              const SizedBox(height: 16),
              
              TextField(
                onChanged: (val) => pastedJson = val,
                maxLines: 4,
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  filled: true, 
                  fillColor: finance.themeCard, // 🟢 Kotak input ngikut tema
                  hintText: '{"sumberDana": [...], "transaksi": [...]}',
                  hintStyle: TextStyle(color: Colors.orangeAccent.withValues(alpha:0.3), fontSize: 11),
                  contentPadding: const EdgeInsets.all(16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: finance.themeBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: finance.themeBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.orangeAccent, width: 1.5)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text("Batal", style: TextStyle(color: finance.themeTextSub))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent, 
                foregroundColor: Colors.black, 
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              onPressed: () {
                try {
                  jsonDecode(pastedJson);
                  
                  HapticFeedback.heavyImpact();
                  
                  if (!mounted) return;
                  Navigator.pop(dialogContext); // Tutup dialog

                  if (!mounted) return;
                  Navigator.pop(context); // Tutup bottom sheet
                  
                  _showToast("🎉 Data berhasil dipulihkan!");
                } catch (e) {
                  HapticFeedback.heavyImpact();
                  if (!mounted) return;
                  _showToast("❌ Teks backup tidak valid atau korup!", isError: true);
                }
              },
              child: const Text("Pulihkan Data", style: TextStyle(fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  // ==========================================
  // ⚡ FUNGSI: KONFIRMASI RESET DATA
  // ==========================================
  void _handleResetConfirm(FinanceProvider finance) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: finance.themeBg, // 🟢 AUTO-SYNC Latar Solid
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: finance.themeBorder)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha:0.1), shape: BoxShape.circle), child: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 32)),
            const SizedBox(height: 16),
            Text("Hapus Semua Data?", style: TextStyle(color: finance.themeText, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text("PERINGATAN KERAS!\nApakah kamu yakin ingin MENGHAPUS SEMUA DATA?\n\nData yang dihapus tidak bisa dikembalikan kecuali kamu punya teks backup JSON!", textAlign: TextAlign.center, style: TextStyle(color: finance.themeTextSub, fontSize: 12)),
            const SizedBox(height: 24),
            CustomButton(text: "Ya, Musnahkan!", variant: ButtonVariant.danger, fullWidth: true, onPressed: () {
              HapticFeedback.heavyImpact();
              finance.deleteUser(finance.currentUser!.id); 
              
              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext); // Tutup Dialog

              if (!context.mounted) return;
              Navigator.pop(context); // Tutup Sheet
              _showToast("🗑️ Semua data akun ini berhasil dihapus!");
            }),
            const SizedBox(height: 8),
            CustomButton(text: "Batal", variant: ButtonVariant.secondary, fullWidth: true, onPressed: () => Navigator.pop(dialogContext)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);

    return Container(
      decoration: BoxDecoration(
        color: finance.themeBg, // 🟢 AUTO-SYNC Latar Solid
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        border: Border(top: BorderSide(color: finance.themeBorder)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Modal
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Data & Storage", style: TextStyle(color: finance.themeText, fontSize: 20, fontWeight: FontWeight.w900)),
                    Text("BACKUP & RESTORE DATA", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                  ],
                ),
                GestureDetector(
                  onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                  child: Container(
                    padding: const EdgeInsets.all(8), 
                    decoration: BoxDecoration(color: finance.themeCard, shape: BoxShape.circle, border: Border.all(color: finance.themeBorder)), 
                    child: Icon(Icons.close_rounded, color: finance.themeTextSub, size: 20)
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 1. INFO BOX LOCAL STORAGE (Flat Design)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha:0.5))),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.shield_rounded, color: Color(0xFF3B82F6), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Data Tersimpan Lokal", style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("Semua catatan kamu 100% aman di perangkat ini (Offline). Salin Data secara rutin agar tidak hilang jika berganti HP.", style: TextStyle(color: finance.themeTextSub, fontSize: 10, height: 1.5)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. BACKUP BUTTON
                GestureDetector(
                  onTap: () => _handleBackupData(finance),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: finance.themeBorder)),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.green.withValues(alpha:0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green.withValues(alpha:0.3))), child: const Icon(Icons.cloud_download_rounded, color: Colors.green)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Backup Data", style: TextStyle(color: finance.themeText, fontSize: 14, fontWeight: FontWeight.bold)),
                              Text("Salin data jadi teks (.json) ke Clipboard", style: TextStyle(color: finance.themeTextSub, fontSize: 10)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: finance.themeTextSub),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. RESTORE BUTTON
                GestureDetector(
                  onTap: () => _handleRestoreData(finance),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: finance.themeBorder)),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.orange.withValues(alpha:0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.withValues(alpha:0.3))), child: const Icon(Icons.cloud_upload_rounded, color: Colors.orange)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Restore Data", style: TextStyle(color: finance.themeText, fontSize: 14, fontWeight: FontWeight.bold)),
                              Text("Pulihkan dari teks backup", style: TextStyle(color: finance.themeTextSub, fontSize: 10)),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: finance.themeTextSub),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // 4. RESET DATA BUTTON (DANGER ZONE)
                GestureDetector(
                  onTap: () => _handleResetConfirm(finance),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.redAccent.withValues(alpha:0.5))),
                    child: Row(
                      children: [
                        Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha:0.1), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Hapus Semua Data", style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                              Text("Reset aplikasi seperti semula", style: TextStyle(color: finance.themeTextSub, fontSize: 10)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}