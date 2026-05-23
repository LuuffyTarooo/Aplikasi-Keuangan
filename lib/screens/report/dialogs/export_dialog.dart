// lib/screens/report/dialogs/export_dialog.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row, Border;

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
  String _exportPeriod = 'BULAN_INI';
  String _exportType = 'SEMUA';
  String _selectedCategory = 'SEMUA';
  String _selectedWallet = 'SEMUA';

  bool _isLoadingCsv = false;
  bool _isLoadingExcel = false;

  Future<File> exportToCsv(
    List<TransactionModel> transactions,
    FinanceProvider finance,
  ) async {
    List<List<dynamic>> rows = [];
    rows.add(['Tanggal', 'Jenis', 'Kategori', 'Nominal', 'Dompet', 'Catatan']);

    for (var tx in transactions) {
      final dompet = finance.myWallets.firstWhere(
        (d) => d.walletId == tx.walletId,
        orElse: () => finance.myWallets.first,
      );
      final date = DateFormat('yyyy-MM-dd').format(DateTime.parse(tx.tanggal));
      rows.add([
        date,
        tx.jenis,
        tx.kategori.isEmpty ? '-' : tx.kategori,
        tx.nominal,
        dompet.walletName,
        tx.keterangan.isEmpty ? '-' : tx.keterangan,
      ]);
    }

    String csvData = csv.encode(rows);
    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/export_transaksi_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    await file.writeAsString(csvData);
    return file;
  }

  Future<File> exportToExcel(
    List<TransactionModel> transactions,
    FinanceProvider finance,
  ) async {
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'Laporan Transaksi';

    // 1. Header Laporan (Baris 1-4)
    final Style titleStyle = workbook.styles.add('TitleStyle');
    titleStyle.bold = true;
    titleStyle.fontSize = 16;
    titleStyle.hAlign = HAlignType.center;

    sheet.getRangeByName('A1:F1').merge();
    sheet.getRangeByName('A1').setText('Laporan Keuangan');
    sheet.getRangeByName('A1').cellStyle = titleStyle;

    final List<String> monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    String periodeText;
    if (_exportPeriod == 'BULAN_INI') {
      final String monthName = monthNames[widget.currentDate.month - 1];
      final String year = widget.currentDate.year.toString();
      final DateTime firstDay = DateTime(
        widget.currentDate.year,
        widget.currentDate.month,
        1,
      );
      final DateTime lastDay = DateTime(
        widget.currentDate.year,
        widget.currentDate.month + 1,
        0,
      );
      periodeText =
          'Periode : $monthName $year, ${firstDay.day} $monthName - ${lastDay.day} $monthName $year';
    } else {
      if (transactions.isNotEmpty) {
        final List<DateTime> dates = transactions
            .map((t) => DateTime.parse(t.tanggal))
            .toList();
        dates.sort();
        final DateTime minDate = dates.first;
        final DateTime maxDate = dates.last;
        final String minStr =
            '${minDate.day} ${monthNames[minDate.month - 1]} ${minDate.year}';
        final String maxStrSafe =
            '${maxDate.day} ${monthNames[maxDate.month - 1]} ${maxDate.year}';
        periodeText = 'Periode : Semua Waktu, dari $minStr sampai $maxStrSafe';
      } else {
        periodeText = 'Periode : Semua Waktu';
      }
    }

    sheet.getRangeByName('A2').setText(periodeText);
    sheet
        .getRangeByName('A3')
        .setText(
          'Tanggal Ekspor: ${DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())}',
        );
    sheet
        .getRangeByName('A4')
        .setText('Total Transaksi: ${transactions.length} Data');

    // 2. Ringkasan (Baris 6-9)
    double totalPemasukan = transactions
        .where((t) => t.jenis == 'Pemasukan')
        .fold(0, (s, t) => s + t.nominal);
    double totalPengeluaran = transactions
        .where((t) => t.jenis == 'Pengeluaran')
        .fold(0, (s, t) => s + t.nominal);
    double saldoAkhir = totalPemasukan - totalPengeluaran;

    sheet.getRangeByName('A6').setText('Total Pemasukan');
    sheet.getRangeByName('B6').setNumber(totalPemasukan);
    sheet.getRangeByName('B6').cellStyle.fontColor = '#00C853';

    sheet.getRangeByName('A7').setText('Total Pengeluaran');
    sheet.getRangeByName('B7').setNumber(totalPengeluaran);
    sheet.getRangeByName('B7').cellStyle.fontColor = '#FF5252';

    sheet.getRangeByName('A8').setText('Saldo Akhir');
    sheet.getRangeByName('A8').cellStyle.bold = true;
    sheet.getRangeByName('B8').setNumber(saldoAkhir);
    sheet.getRangeByName('B8').cellStyle.bold = true;
    sheet.getRangeByName('B8').cellStyle.fontColor = '#2962FF';

    // 3. Tabel Transaksi (Mulai Baris 11)
    final String headerColorHex =
        '${(finance.themeCard.r * 255).toInt().toRadixString(16).padLeft(2, '0')}${(finance.themeCard.g * 255).toInt().toRadixString(16).padLeft(2, '0')}${(finance.themeCard.b * 255).toInt().toRadixString(16).padLeft(2, '0')}'
            .toUpperCase();

    final Style headerStyle = workbook.styles.add('HeaderStyle');
    headerStyle.backColor = '#$headerColorHex';
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.bold = true;
    headerStyle.hAlign = HAlignType.center;

    final List<String> headers = [
      'Tanggal',
      'Jenis',
      'Kategori',
      'Nominal',
      'Dompet',
      'Catatan',
    ];
    for (int col = 0; col < headers.length; col++) {
      final Range range = sheet.getRangeByIndex(11, col + 1);
      range.setText(headers[col]);
      range.cellStyle = headerStyle;
    }

    int rowIndex = 12;
    for (var tx in transactions) {
      final dompet = finance.myWallets.firstWhere(
        (d) => d.walletId == tx.walletId,
        orElse: () => finance.myWallets.first,
      );
      final date = DateFormat('yyyy-MM-dd').format(DateTime.parse(tx.tanggal));

      sheet.getRangeByIndex(rowIndex, 1).setText(date);
      sheet.getRangeByIndex(rowIndex, 2).setText(tx.jenis);
      sheet
          .getRangeByIndex(rowIndex, 3)
          .setText(tx.kategori.isEmpty ? '-' : tx.kategori);
      sheet.getRangeByIndex(rowIndex, 4).setNumber(tx.nominal);
      sheet.getRangeByIndex(rowIndex, 5).setText(dompet.walletName);
      sheet
          .getRangeByIndex(rowIndex, 6)
          .setText(tx.keterangan.isEmpty ? '-' : tx.keterangan);

      // Zebra striping
      if (rowIndex % 2 == 0) {
        sheet.getRangeByIndex(rowIndex, 1, rowIndex, 6).cellStyle.backColor =
            '#F5F5F5';
      }

      // Pewarnaan Kolom Jenis
      final Range jenisCell = sheet.getRangeByIndex(rowIndex, 2);
      if (tx.jenis == 'Pemasukan') {
        jenisCell.cellStyle.backColor = '#00C853';
        jenisCell.cellStyle.fontColor = '#FFFFFF';
      } else if (tx.jenis == 'Pengeluaran') {
        jenisCell.cellStyle.backColor = '#FF5252';
        jenisCell.cellStyle.fontColor = '#FFFFFF';
      } else if (tx.jenis == 'Transfer') {
        jenisCell.cellStyle.backColor = '#2962FF';
        jenisCell.cellStyle.fontColor = '#FFFFFF';
      }
      jenisCell.cellStyle.bold = true;
      jenisCell.cellStyle.hAlign = HAlignType.center;

      rowIndex++;
    }

    // No extra number format for Currency, keep it pure numeric

    for (int col = 1; col <= headers.length; col++) {
      sheet.autoFitColumn(col);
    }

    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final directory = await getTemporaryDirectory();
    final file = File(
      '${directory.path}/laporan_transaksi_${DateTime.now().millisecondsSinceEpoch}.xlsx',
    );
    await file.writeAsBytes(bytes, flush: true);

    return file;
  }

  void _executeExport(FinanceProvider finance, String format) async {
    HapticFeedback.heavyImpact();

    if (format == 'CSV') {
      setState(() => _isLoadingCsv = true);
    } else {
      setState(() => _isLoadingExcel = true);
    }

    try {
      List<TransactionModel> txs = List.from(finance.myTransaksi);
      // Urutkan dari yang terlama ke terbaru
      txs.sort((a, b) => DateTime.parse(a.tanggal).compareTo(DateTime.parse(b.tanggal)));

      if (_exportPeriod == 'BULAN_INI') {
        txs = txs.where((t) {
          final d = DateTime.parse(t.tanggal);
          return d.year == widget.currentDate.year &&
              d.month == widget.currentDate.month;
        }).toList();
      }

      if (_exportType != 'SEMUA') {
        txs = txs.where((t) => t.jenis == _exportType).toList();
      }

      if (_selectedCategory != 'SEMUA') {
        txs = txs.where((t) => t.kategori == _selectedCategory).toList();
      }

      if (_selectedWallet != 'SEMUA') {
        txs = txs
            .where(
              (t) =>
                  t.walletId == _selectedWallet ||
                  t.targetWalletId == _selectedWallet,
            )
            .toList();
      }

      if (txs.isEmpty) {
        _showSnackBar(finance, 'Data tidak tersedia', isError: true);
        return;
      }

      if (format == 'CSV') {
        final file = await exportToCsv(txs, finance);
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Export CSV Laporan Keuangan');

        _showSnackBar(
          finance,
          'Berhasil mengekspor ${txs.length} transaksi ke CSV',
        );
      } else {
        final file = await exportToExcel(txs, finance);
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Export Excel Laporan Keuangan');

        _showSnackBar(
          finance,
          'Berhasil mengekspor ${txs.length} transaksi ke Excel',
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar(finance, e.toString(), isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCsv = false;
          _isLoadingExcel = false;
        });
      }
    }
  }

  void _showSnackBar(
    FinanceProvider finance,
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
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
      if (t.kategori.isNotEmpty && t.jenis != 'Transfer') {
        catSet.add(t.kategori);
      }
    }
    List<String> uniqueCategories = catSet.toList()..sort();

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: finance.themeBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: finance.themeBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
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
                  Text(
                    "Kelola Data",
                    style: TextStyle(
                      color: finance.themeText,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    "EXPORT LAPORAN TRANSAKSI",
                    style: TextStyle(
                      color: finance.themeTextSub,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: finance.themeCard,
                    shape: BoxShape.circle,
                    border: Border.all(color: finance.themeBorder),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: finance.themeTextSub,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Text(
            "PERIODE LAPORAN",
            style: TextStyle(
              color: finance.themeTextSub,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: finance.themeCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: finance.themeBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabOption(
                    'BULAN_INI',
                    'Bulan Ini',
                    _exportPeriod,
                    finance,
                    (v) => setState(() => _exportPeriod = v),
                  ),
                ),
                Expanded(
                  child: _buildTabOption(
                    'SEMUA',
                    'Semua Waktu',
                    _exportPeriod,
                    finance,
                    (v) => setState(() => _exportPeriod = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text(
            "TIPE TRANSAKSI",
            style: TextStyle(
              color: finance.themeTextSub,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['SEMUA', 'Pengeluaran', 'Pemasukan'].map((type) {
              bool isActive = _exportType == type;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _exportType = type);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? finance.themeAccent : finance.themeCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isActive
                          ? finance.themeAccent
                          : finance.themeBorder,
                    ),
                  ),
                  child: Text(
                    type == 'SEMUA' ? 'Semua Tipe' : type,
                    style: TextStyle(
                      color: isActive ? finance.themeBg : finance.themeTextSub,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
                    Text(
                      "KATEGORI",
                      style: TextStyle(
                        color: finance.themeTextSub,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      finance: finance,
                      value: _selectedCategory,
                      items: uniqueCategories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c == 'SEMUA' ? 'Semua Kategori' : c),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        HapticFeedback.lightImpact();
                        setState(() => _selectedCategory = v!);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SUMBER DANA",
                      style: TextStyle(
                        color: finance.themeTextSub,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      finance: finance,
                      value: _selectedWallet,
                      items: [
                        const DropdownMenuItem(
                          value: 'SEMUA',
                          child: Text('Semua Dompet'),
                        ),
                        ...finance.myWallets.map(
                          (d) => DropdownMenuItem(
                            value: d.walletId,
                            child: Text(d.walletName),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        HapticFeedback.lightImpact();
                        setState(() => _selectedWallet = v!);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          Row(
            children: [
              Expanded(
                child: CustomButton(
                  text: _isLoadingCsv ? "Proses..." : "Export CSV",
                  variant: ButtonVariant.primary,
                  icon: Icons.table_chart_rounded,
                  fullWidth: true,
                  isLoading: _isLoadingCsv,
                  onPressed: _isLoadingCsv || _isLoadingExcel
                      ? null
                      : () => _executeExport(finance, 'CSV'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomButton(
                  text: _isLoadingExcel ? "Proses..." : "Export Excel",
                  variant: ButtonVariant.primary,
                  icon: Icons.border_all_rounded,
                  fullWidth: true,
                  isLoading: _isLoadingExcel,
                  onPressed: _isLoadingCsv || _isLoadingExcel
                      ? null
                      : () => _executeExport(finance, 'EXCEL'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabOption(
    String value,
    String label,
    String currentVal,
    FinanceProvider finance,
    Function(String) onTap,
  ) {
    bool isActive = currentVal == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? finance.themeAccent.withValues(alpha: 0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? finance.themeAccent : finance.themeTextSub,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required FinanceProvider finance,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: finance.themeCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: finance.themeBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: finance.themeCard,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: finance.themeTextSub,
          ),
          style: TextStyle(
            color: finance.themeText,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
