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

  void _executeExport(FinanceProvider finance) async {
    HapticFeedback.heavyImpact();
    setState(() => _isExporting = true);

    // Simulasi proses export yang panjang
    await Future.delayed(const Duration(seconds: 1)); 

    setState(() => _isExporting = false);
    
    if (!mounted) return;
    
    // Custom SnackBar biar gak pake bawaan Flutter yang kotak kaku
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.rocket_launch_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sabar Jar! Modul PDF & Excel lagi dirakit. Segera hadir!',
                style: TextStyle(color: finance.themeText, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: finance.themeAccent, // 🟢 AUTO-SYNC Aksen
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
        color: finance.themeBg, // 🟢 AUTO-SYNC: Latar solid
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: finance.themeBorder),
        // Shadow kotak modal tetep ada dikit biar misah dari background belakangnya
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.3), blurRadius: 30, offset: const Offset(0, 10))],
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Export Laporan", style: TextStyle(color: finance.themeText, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text("DOWNLOAD DATA KEUANGAN", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
          const SizedBox(height: 32),

          // 1. Pilih Format File
          Text("1. PILIH FORMAT FILE", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                // 🟢 FIX: Tombol PDF pakai warna Aksen
                child: _buildFormatOption('PDF', Icons.picture_as_pdf_rounded, 'Dokumen PDF', finance.themeAccent, finance),
              ),
              const SizedBox(width: 12),
              Expanded(
                // 🟢 FIX: Tombol EXCEL pakai warna Aksen
                child: _buildFormatOption('EXCEL', Icons.table_view_rounded, 'Microsoft Excel', finance.themeAccent, finance),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Periode Laporan
          Text("2. PERIODE LAPORAN", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: finance.themeBorder)),
            child: Row(
              children: [
                Expanded(child: _buildTabOption('BULAN_INI', 'Bulan Ini', _exportPeriod, finance, (v) => setState(() => _exportPeriod = v))),
                Expanded(child: _buildTabOption('SEMUA', 'Semua Waktu', _exportPeriod, finance, (v) => setState(() => _exportPeriod = v))),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 3. Tipe Transaksi
          Text("3. TIPE TRANSAKSI", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
                    color: isActive ? finance.themeAccent : finance.themeCard, 
                    borderRadius: BorderRadius.circular(12), 
                    border: Border.all(color: isActive ? finance.themeAccent : finance.themeBorder)
                  ),
                  child: Text(type == 'SEMUA' ? 'Semua Tipe' : type, style: TextStyle(color: isActive ? finance.themeBg : finance.themeTextSub, fontSize: 12, fontWeight: FontWeight.bold)),
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
                    Text("KATEGORI", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      finance: finance,
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
                    Text("SUMBER DANA", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      finance: finance,
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
            onPressed: () => _executeExport(finance),
          ),
        ],
      ),
    );
  }

  // 🟢 FIX: Logika tombol format murni flat & ngikut Aksen
  Widget _buildFormatOption(String value, IconData icon, String label, Color activeColor, FinanceProvider finance) {
    bool isActive = _exportFormat == value;
    return GestureDetector(
      onTap: () { HapticFeedback.mediumImpact(); setState(() => _exportFormat = value); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha:0.1) : finance.themeCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? activeColor : finance.themeBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? activeColor : finance.themeTextSub, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isActive ? activeColor : finance.themeTextSub, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabOption(String value, String label, String currentVal, FinanceProvider finance, Function(String) onTap) {
    bool isActive = currentVal == value;
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(value); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? finance.themeAccent.withValues(alpha:0.15) : Colors.transparent, 
          borderRadius: BorderRadius.circular(12), 
        ),
        alignment: Alignment.center,
        child: Text(label, style: TextStyle(color: isActive ? finance.themeAccent : finance.themeTextSub, fontSize: 12, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDropdown({required FinanceProvider finance, required String value, required List<DropdownMenuItem<String>> items, required void Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: finance.themeCard, 
        borderRadius: BorderRadius.circular(16), 
        border: Border.all(color: finance.themeBorder)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: finance.themeCard, 
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: finance.themeTextSub),
          style: TextStyle(color: finance.themeText, fontSize: 12, fontWeight: FontWeight.bold),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}