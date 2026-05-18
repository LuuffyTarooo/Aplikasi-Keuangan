// lib/screens/report/dialogs/export_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/shared/widgets/custom_button.dart';

class ExportDialog extends StatefulWidget {
  final DateTime currentDate;

  const ExportDialog({super.key, required this.currentDate});

  static void show(BuildContext context, DateTime currentDate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ExportDialog(currentDate: currentDate),
    );
  }

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  String _exportFormat = 'PDF';
  String _exportPeriod = 'BULAN_INI';
  String _exportType = 'SEMUA';
  String _selectedCategory = 'SEMUA';
  String _selectedWallet = 'SEMUA';

  bool _isExporting = false;

  void _executeExport() async {
    HapticFeedback.heavyImpact();
    setState(() => _isExporting = true);

    // Simulasi proses export yang panjang
    await Future.delayed(const Duration(seconds: 1)); 

    setState(() => _isExporting = false);
    
    if (!mounted) return;
    
    // Custom SnackBar biar gak pake bawaan Flutter yang kotak kaku
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sabar Jar! Modul PDF & Excel lagi dirakit. Segera hadir!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF9333EA),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        duration: const Duration(seconds: 3),
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);

    // Ambil daftar kategori unik 
    Set<String> catSet = {'SEMUA'};
    for (var t in finance.myTransaksi) {
      if (t.kategori.isNotEmpty && t.jenis != 'Transfer') catSet.add(t.kategori);
    }
    List<String> uniqueCategories = catSet.toList()..sort();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF161B22).withValues(alpha:0.95),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white10),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.5), blurRadius: 40, offset: const Offset(0, 10))],
      ),
      padding: EdgeInsets.only(
        top: 24, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24, // Aman dari keyboard
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Export Laporan", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text("DOWNLOAD DATA KEUANGAN", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                ],
              ),
              GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, color: Colors.white54, size: 20),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 1. Pilih Format File
          const Text("1. PILIH FORMAT FILE", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildFormatOption('PDF', Icons.picture_as_pdf_rounded, 'Dokumen PDF', Colors.pinkAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFormatOption('EXCEL', Icons.table_view_rounded, 'Microsoft Excel', Colors.greenAccent),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Periode Laporan
          const Text("2. PERIODE LAPORAN", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
            child: Row(
              children: [
                Expanded(child: _buildTabOption('BULAN_INI', 'Bulan Ini', _exportPeriod, (v) => setState(() => _exportPeriod = v))),
                Expanded(child: _buildTabOption('SEMUA', 'Semua Waktu', _exportPeriod, (v) => setState(() => _exportPeriod = v))),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Tipe Transaksi
          const Text("3. TIPE TRANSAKSI", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: ['SEMUA', 'Pengeluaran', 'Pemasukan'].map((type) {
              bool isActive = _exportType == type;
              return GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); setState(() => _exportType = type); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF9333EA) : Colors.white.withValues(alpha:0.05), 
                    borderRadius: BorderRadius.circular(12), 
                    border: Border.all(color: isActive ? const Color(0xFFA855F7).withValues(alpha:0.5) : Colors.white10)
                  ),
                  child: Text(type == 'SEMUA' ? 'Semua Tipe' : type, style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // 4. Kategori & Sumber Dana
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("KATEGORI", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _selectedCategory,
                      items: uniqueCategories.map((c) => DropdownMenuItem(value: c, child: Text(c == 'SEMUA' ? 'Semua Kategori' : c))).toList(),
                      onChanged: (v) { HapticFeedback.lightImpact(); setState(() => _selectedCategory = v!); },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("SUMBER DANA", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _selectedWallet,
                      items: [
                        const DropdownMenuItem(value: 'SEMUA', child: Text('Semua Dompet')),
                        ...finance.mySumberDana.map((d) => DropdownMenuItem(value: d.idDana, child: Text(d.namaAset))),
                      ],
                      onChanged: (v) { HapticFeedback.lightImpact(); setState(() => _selectedWallet = v!); },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // 5. Tombol Export
          CustomButton(
            text: _isExporting ? "Menyiapkan File..." : "Download Data",
            variant: ButtonVariant.primary,
            icon: Icons.download_rounded,
            fullWidth: true,
            isLoading: _isExporting,
            onPressed: _executeExport,
          ),
        ],
      ),
    );
  }

  Widget _buildFormatOption(String value, IconData icon, String label, Color activeColor) {
    bool isActive = _exportFormat == value;
    return GestureDetector(
      onTap: () { HapticFeedback.mediumImpact(); setState(() => _exportFormat = value); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha:0.1) : Colors.white.withValues(alpha:0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? activeColor.withValues(alpha:0.5) : Colors.white10),
          boxShadow: isActive ? [BoxShadow(color: activeColor.withValues(alpha:0.2), blurRadius: 15)] : null,
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? activeColor : Colors.white54, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isActive ? activeColor : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabOption(String value, String label, String currentVal, Function(String) onTap) {
    bool isActive = currentVal == value;
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(value); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withValues(alpha:0.1) : Colors.transparent, 
          borderRadius: BorderRadius.circular(12), 
          border: Border.all(color: isActive ? Colors.white.withValues(alpha:0.05) : Colors.transparent)
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDropdown({required String value, required List<DropdownMenuItem<String>> items, required void Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha:0.05), 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: Colors.white10)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF1E1B38), // 🟢 Warna background dropdown digelapin dikit
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white54),
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}