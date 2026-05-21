// lib/screens/report/dialogs/export_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/shared/widgets/custom_button.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';

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
  String _activeTab = 'EXPORT'; // EXPORT or IMPORT
  String _exportPeriod = 'BULAN_INI';
  String _exportType = 'SEMUA';
  String _selectedCategory = 'SEMUA';
  String _selectedWallet = 'SEMUA';

  bool _isLoading = false;

  void _executeExport(FinanceProvider finance) async {
    HapticFeedback.heavyImpact();
    setState(() => _isLoading = true);

    try {
      List<TransactionModel> txs = List.from(finance.allTransaksi);
      
      if (_exportPeriod == 'BULAN_INI') {
        txs = txs.where((t) {
          final d = DateTime.parse(t.tanggal);
          return d.year == widget.currentDate.year && d.month == widget.currentDate.month;
        }).toList();
      }

      if (_exportType != 'SEMUA') {
        txs = txs.where((t) => t.jenis == _exportType).toList();
      }

      if (_selectedCategory != 'SEMUA') {
        txs = txs.where((t) => t.kategori == _selectedCategory).toList();
      }

      if (_selectedWallet != 'SEMUA') {
        txs = txs.where((t) => t.idDana == _selectedWallet || t.idDanaTujuan == _selectedWallet).toList();
      }

      if (txs.isEmpty) {
        _showSnackBar(finance, 'Tidak ada transaksi untuk diekspor pada periode ini.', isError: true);
        setState(() => _isLoading = false);
        return;
      }

      await finance.exportTransactionsCSV(txs);
      _showSnackBar(finance, 'Berhasil mengekspor ${txs.length} transaksi ke CSV.');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar(finance, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _executeImport(FinanceProvider finance) async {
    HapticFeedback.heavyImpact();
    
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _isLoading = true);
        String path = result.files.single.path!;
        int count = await finance.importTransactionsCSV(path);
        
        _showSnackBar(finance, 'Berhasil mengimpor $count transaksi. Saldo otomatis disinkronisasi.');
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar(finance, 'Gagal import: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(FinanceProvider finance, String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.error_rounded : Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : finance.themeAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);

    Set<String> catSet = {'SEMUA'};
    for (var t in finance.myTransaksi) {
      if (t.kategori.isNotEmpty && t.jenis != 'Transfer') catSet.add(t.kategori);
    }
    List<String> uniqueCategories = catSet.toList()..sort();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: finance.themeBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: finance.themeBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.3), blurRadius: 30, offset: const Offset(0, 10))],
      ),
      padding: EdgeInsets.only(
        top: 24, left: 24, right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
                  Text("Kelola Data", style: TextStyle(color: finance.themeText, fontSize: 18, fontWeight: FontWeight.w900)),
                  Text("EXPORT & IMPORT CSV", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: finance.themeBorder)),
            child: Row(
              children: [
                Expanded(child: _buildTabOption('EXPORT', 'Export ke CSV', _activeTab, finance, (v) => setState(() => _activeTab = v))),
                Expanded(child: _buildTabOption('IMPORT', 'Import dari CSV', _activeTab, finance, (v) => setState(() => _activeTab = v))),
              ],
            ),
          ),
          const SizedBox(height: 24),

          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _activeTab == 'EXPORT' ? _buildExportView(finance, uniqueCategories) : _buildImportView(finance),
          ),
        ],
      ),
    );
  }

  Widget _buildExportView(FinanceProvider finance, List<String> uniqueCategories) {
    return Column(
      key: const ValueKey('export_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("PERIODE LAPORAN", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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

        Text("TIPE TRANSAKSI", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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

        CustomButton(
          text: _isLoading ? "Menyiapkan File..." : "Download CSV",
          variant: ButtonVariant.primary,
          icon: Icons.download_rounded,
          fullWidth: true,
          isLoading: _isLoading,
          onPressed: () => _executeExport(finance),
        ),
      ],
    );
  }

  Widget _buildImportView(FinanceProvider finance) {
    return Column(
      key: const ValueKey('import_view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: finance.themeAccent.withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: finance.themeAccent.withValues(alpha:0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, color: finance.themeAccent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Pastikan file berformat .csv dan memiliki kolom wajib: nominal, jenis, tanggal. Data akan otomatis memperbarui saldo sumber dana terkait.",
                  style: TextStyle(color: finance.themeText, fontSize: 12, height: 1.5),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        CustomButton(
          text: _isLoading ? "Membaca File..." : "Pilih File CSV",
          variant: ButtonVariant.primary,
          icon: Icons.upload_file_rounded,
          fullWidth: true,
          isLoading: _isLoading,
          onPressed: () => _executeImport(finance),
        ),
      ],
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