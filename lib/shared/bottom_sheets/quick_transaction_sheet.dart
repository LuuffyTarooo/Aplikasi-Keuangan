// lib/shared/bottom_sheets/quick_transaction_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';
import 'package:aplikasi_keuangan/models/category_model.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';
import 'package:aplikasi_keuangan/core/utils/wallet_helper.dart';
import 'package:aplikasi_keuangan/core/utils/audio_helper.dart';
import 'package:aplikasi_keuangan/core/utils/haptic_helper.dart';

class QuickTransactionSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => const _QuickTransactionContent(),
    );
  }
}

class _QuickTransactionContent extends StatefulWidget {
  const _QuickTransactionContent();

  @override
  State<_QuickTransactionContent> createState() => _QuickTransactionContentState();
}

class _QuickTransactionContentState extends State<_QuickTransactionContent> {
  String _jenis = 'Pengeluaran';
  CategoryModel? _selectedKategori;
  String? _idDana;
  final TextEditingController _nominalController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final finance = Provider.of<FinanceProvider>(context, listen: false);
      if (finance.mySumberDana.isNotEmpty) {
        setState(() => _idDana = finance.mySumberDana.first.idDana);
      }
    });
  }

  void _handleSubmit(FinanceProvider finance) async {
    if (_isSubmitting) return;

    final nominalRaw = _nominalController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (nominalRaw.isEmpty) return;

    final inputNominal = double.parse(nominalRaw);
    if (inputNominal <= 0) return;

    if (_idDana == null) return;
    if (_jenis != 'Transfer' && _selectedKategori == null) return;

    setState(() => _isSubmitting = true);

    final newTx = TransactionModel(
      idTransaksi: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      jenis: _jenis,
      nominal: inputNominal,
      idDana: _idDana!,
      idDanaTujuan: null, 
      kategori: _jenis == 'Transfer' ? 'Transfer' : _selectedKategori!.name,
      keterangan: _catatanController.text.isEmpty ? 'Transaksi Cepat' : _catatanController.text,
      tanggal: DateTime.now().toIso8601String(),
      userId: finance.currentUser?.id ?? '',
    );

    // Using the existing handleSaveTransaksi method which maps to addTransaction logic
    finance.handleSaveTransaksi(newTx);

    AudioHelper.playSuccessSound();
    HapticHelper.success();

    await Future.delayed(const Duration(milliseconds: 300));
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  List<CategoryModel> _getDisplayCategories(FinanceProvider finance) {
    return _jenis == 'Pengeluaran' ? finance.expenseCategories : finance.incomeCategories;
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final categories = _getDisplayCategories(finance);
    
    if (_selectedKategori == null && categories.isNotEmpty && _jenis != 'Transfer') {
      _selectedKategori = categories.first;
    } else if (_jenis != 'Transfer' && categories.isNotEmpty && !categories.contains(_selectedKategori)) {
      _selectedKategori = categories.first;
    }

    final isReady = _nominalController.text.isNotEmpty && _idDana != null && (_jenis == 'Transfer' || _selectedKategori != null);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: finance.themeBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: finance.themeBorder)),
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: finance.themeBorder, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text("Input Cepat ⚡", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
              const SizedBox(height: 24),

              // Section 1: Tipe Transaksi (SegmentedButton)
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'Pengeluaran', label: Text('Pengeluaran')),
                    ButtonSegment(value: 'Pemasukan', label: Text('Pemasukan')),
                    ButtonSegment(value: 'Transfer', label: Text('Transfer')),
                  ],
                  selected: {_jenis},
                  onSelectionChanged: (Set<String> newSelection) {
                    HapticFeedback.lightImpact();
                    setState(() {
                      _jenis = newSelection.first;
                      _selectedKategori = null;
                    });
                  },
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return finance.themeAccent;
                        }
                        return finance.themeCard;
                      },
                    ),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.black;
                        }
                        return finance.themeTextSub;
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section 2: Kategori (Wrap dengan Chip)
              if (_jenis != 'Transfer') ...[
                Text("KATEGORI", style: TextStyle(color: finance.themeTextSub, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: categories.map((kat) {
                    final isSelected = _selectedKategori?.name == kat.name;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(kat.icon, size: 16, color: isSelected ? kat.accentColor : finance.themeTextSub),
                          const SizedBox(width: 6),
                          Text(kat.name),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        if (selected) {
                          HapticFeedback.lightImpact();
                          setState(() => _selectedKategori = kat);
                        }
                      },
                      selectedColor: kat.bgColor,
                      backgroundColor: finance.themeCard,
                      labelStyle: TextStyle(
                        color: isSelected ? kat.accentColor : finance.themeTextSub,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isSelected ? kat.accentColor.withOpacity(0.5) : finance.themeBorder),
                      ),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
              ],

              // Section 3: Dompet (ListView Horizontal)
              Text("DOMPET SUMBER", style: TextStyle(color: finance.themeTextSub, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              const SizedBox(height: 12),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: finance.mySumberDana.length,
                  itemBuilder: (context, index) {
                    final d = finance.mySumberDana[index];
                    final isSelected = _idDana == d.idDana;
                    return GestureDetector(
                      onTap: () { HapticFeedback.lightImpact(); setState(() => _idDana = d.idDana); },
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? finance.themeAccent.withOpacity(0.1) : finance.themeCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? finance.themeAccent : finance.themeBorder)
                        ),
                        child: Row(
                          children: [
                            WalletHelper.getWalletLogo(d.namaAset, size: 'sm'),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(d.namaAset, style: TextStyle(color: isSelected ? finance.themeAccent : finance.themeText, fontSize: 13, fontWeight: FontWeight.bold)),
                                Text(Formatters.formatCurrency(d.saldoTerkini), style: TextStyle(color: finance.themeTextSub, fontSize: 11, fontWeight: FontWeight.bold)),
                              ],
                            )
                          ]
                        )
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Section 4: Nominal (TextFormField)
              TextFormField(
                controller: _nominalController,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: TextStyle(color: finance.themeText, fontSize: 32, fontWeight: FontWeight.bold),
                inputFormatters: [CurrencyInputFormatter()],
                decoration: InputDecoration(
                  filled: true,
                  fillColor: finance.themeCard,
                  prefixIconConstraints: const BoxConstraints(minWidth: 60),
                  prefixIcon: Center(
                    widthFactor: 1.0,
                    child: Text("${Formatters.activeCurrency.symbol} ", style: TextStyle(color: finance.themeTextSub, fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  hintText: "0",
                  hintStyle: TextStyle(color: finance.themeTextSub.withOpacity(0.5)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                ),
                onChanged: (val) {
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),

              // Section 5: Catatan (TextFormField multi-line)
              TextFormField(
                controller: _catatanController,
                maxLines: 3,
                minLines: 1,
                style: TextStyle(color: finance.themeText, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: finance.themeCard,
                  prefixIcon: Icon(Icons.notes_rounded, color: finance.themeTextSub, size: 20),
                  hintText: "Catatan opsional...",
                  hintStyle: TextStyle(color: finance.themeTextSub.withOpacity(0.5)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),

              // Action Bar
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: finance.themeTextSub.withOpacity(0.2),
                        foregroundColor: finance.themeTextSub,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: const Text("Batalkan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: isReady ? () => _handleSubmit(finance) : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: finance.themeAccent,
                        foregroundColor: Colors.black, // Dark text on yellow background
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                        disabledBackgroundColor: finance.themeCard,
                        disabledForegroundColor: finance.themeTextSub,
                      ),
                      child: _isSubmitting 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                        : const Text("Selesai", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
