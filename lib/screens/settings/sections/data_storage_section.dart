// lib/screens/settings/sheets/data_storage_sheet.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/shared/widgets/custom_button.dart';
import 'package:aplikasi_keuangan/models/user_model.dart';
import 'package:aplikasi_keuangan/models/wallet_model.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';

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
  bool _isLoading = false;

  
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
  // ⚡ FUNGSI: BACKUP DATA (JSON FILE)
  // ==========================================
  Future<void> _handleBackupData(FinanceProvider finance) async {
    if (_isLoading) return;
    HapticFeedback.heavyImpact();
    setState(() => _isLoading = true);
    
    try {
      final backupData = {
        'user_profile': finance.currentUser!.toJson(),
        'wallets': finance.mySumberDana.map((w) => w.toJson()).toList(),
        'transactions': finance.myTransaksi.map((t) => t.toJson()).toList(),
        'metadata': {
          'backup_date': DateTime.now().toIso8601String(),
          'app_version': '1.0.0',
        }
      };

      String jsonString = jsonEncode(backupData);
      
      final tempDir = await getTemporaryDirectory();
      final now = DateTime.now();
      final dateStr = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}";
      final filePath = '${tempDir.path}/walkmeal_backup_$dateStr.json';
      
      final file = File(filePath);
      await file.writeAsString(jsonString);

      if (!mounted) return;
      setState(() => _isLoading = false);
      
      final result = await Share.shareXFiles([XFile(filePath)], text: 'Backup Data Aplikasi Keuangan');
      
      if (!mounted) return;
      if (result.status == ShareResultStatus.success) {
        _showToast("✅ Backup berhasil tersimpan ke cloud");
      } else if (result.status == ShareResultStatus.dismissed) {
        _showToast("❌ Backup dibatalkan. Data belum tersimpan.", isError: true);
      }
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showToast("❌ Gagal melakukan backup data.", isError: true);
    }
  }

  // ==========================================
  // ⚡ FUNGSI: RESTORE DATA (JSON FILE)
  // ==========================================
  Future<void> _handleRestoreData(FinanceProvider finance) async {
    if (_isLoading) return;
    HapticFeedback.mediumImpact();
    
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (!data.containsKey('user_profile') || 
          !data.containsKey('wallets') || 
          !data.containsKey('transactions')) {
        _showToast("Format File Tidak Valid", isError: true);
        return;
      }

      final userProfile = UserModel.fromJson(data['user_profile']);
      final wallets = (data['wallets'] as List).map((e) => WalletModel.fromJson(e)).toList();
      final transactions = (data['transactions'] as List).map((e) => TransactionModel.fromJson(e)).toList();

      if (!mounted) return;

      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: finance.themeBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: finance.themeBorder)),
            title: Row(
              children: [
                const Icon(Icons.warning_rounded, color: Colors.orangeAccent),
                const SizedBox(width: 8),
                Text("Konfirmasi Restore", style: TextStyle(color: finance.themeText, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            content: Text(
              "Data saat ini akan dihapus dan diganti dengan data backup. Lanjutkan?",
              style: TextStyle(color: finance.themeTextSub, fontSize: 14),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text("Batal", style: TextStyle(color: finance.themeTextSub)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: finance.themeAccent, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                ),
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text("Lanjutkan", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        setState(() => _isLoading = true);
        
        await finance.restoreFromBackup(
          userProfile: userProfile,
          wallets: wallets,
          transactions: transactions,
        );
        
        if (mounted) {
          _showToast("Restore Berhasil");
          Navigator.pop(context); // Close the bottom sheet
        }
      }

    } catch (e) {
      if (mounted) _showToast("Format File Tidak Valid", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                        _isLoading ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: finance.themeAccent)) : Icon(Icons.chevron_right_rounded, color: finance.themeTextSub),
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
                        _isLoading ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: finance.themeAccent)) : Icon(Icons.chevron_right_rounded, color: finance.themeTextSub),
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