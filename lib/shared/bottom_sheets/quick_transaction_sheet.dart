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

    finance.handleSaveTransaksi(newTx);

    AudioHelper.playSuccessSound();
    HapticHelper.success();

    await Future.delayed(const Duration(milliseconds: 600));
    
    SystemNavigator.pop();
  }

  List<CategoryModel> _getDisplayCategories(FinanceProvider finance) {
    return _jenis == 'Pengeluaran' ? finance.expenseCategories : finance.incomeCategories;
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final categories = _getDisplayCategories(finance);
    
    // Auto select category if empty
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
              Text("Input Cepat ⚡", style: TextStyle(color: finance.themeText, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 24),

              // Section 1: Tipe Transaksi
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: finance.themeBorder)),
                child: Row(
                  children: ['Pengeluaran', 'Pemasukan'].map((tab) {
                    final isActive = _jenis == tab;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () { HapticFeedback.lightImpact(); setState(() { _jenis = tab; _selectedKategori = null; }); },
                        child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isActive ? finance.themeAccent : Colors.transparent, borderRadius: BorderRadius.circular(16)), alignment: Alignment.center, child: Text(tab, style: TextStyle(color: isActive ? Colors.white : finance.themeTextSub, fontWeight: FontWeight.bold, fontSize: 13))),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Section 2: Kategori (Pill Selector)
              if (_jenis != 'Transfer') ...[
                Text("KATEGORI", style: TextStyle(color: finance.themeTextSub, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final kat = categories[index];
                      final isSelected = _selectedKategori?.name == kat.name;
                      return GestureDetector(
                        onTap: () { HapticFeedback.lightImpact(); setState(() => _selectedKategori = kat); },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? kat.bgColor : finance.themeCard,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: isSelected ? kat.accentColor.withValues(alpha: 0.5) : finance.themeBorder)
                          ),
                          child: Row(
                            children: [
                              Icon(kat.icon, size: 16, color: isSelected ? kat.accentColor : finance.themeTextSub),
                              const SizedBox(width: 8),
                              Text(kat.name, style: TextStyle(color: isSelected ? kat.accentColor : finance.themeTextSub, fontSize: 12, fontWeight: FontWeight.bold))
                            ]
                          )
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Section 3: Dompet
              Text("DOMPET SUMBER", style: TextStyle(color: finance.themeTextSub, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: finance.mySumberDana.length,
                  itemBuilder: (context, index) {
                    final d = finance.mySumberDana[index];
                    final isSelected = _idDana == d.idDana;
                    return GestureDetector(
                      onTap: () { HapticFeedback.lightImpact(); setState(() => _idDana = d.idDana); },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? finance.themeAccent.withValues(alpha: 0.1) : finance.themeCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? finance.themeAccent : finance.themeBorder)
                        ),
                        child: Row(
                          children: [
                            WalletHelper.getWalletLogo(d.namaAset, size: 'sm'),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(d.namaAset, style: TextStyle(color: isSelected ? finance.themeAccent : finance.themeText, fontSize: 12, fontWeight: FontWeight.w900)),
                                Text(Formatters.formatCurrency(d.saldoTerkini), style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold)),
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

              // Section 4: Nominal
              TextField(
                controller: _nominalController,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: TextStyle(color: finance.themeText, fontSize: 32, fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: finance.themeCard,
                  prefixIconConstraints: const BoxConstraints(minWidth: 60),
                  prefixIcon: Center(
                    widthFactor: 1.0,
                    child: Text("${Formatters.activeCurrency.symbol} ", style: TextStyle(color: finance.themeTextSub, fontSize: 20, fontWeight: FontWeight.bold)),
                  ),
                  hintText: "0",
                  hintStyle: TextStyle(color: finance.themeTextSub.withValues(alpha: 0.5)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: finance.themeBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: finance.themeBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: finance.themeAccent, width: 2)),
                ),
                onChanged: (val) {
                  setState(() {}); // Trigger rebuild for button state
                },
              ),
              const SizedBox(height: 16),

              // Section 5: Catatan
              TextField(
                controller: _catatanController,
                style: TextStyle(color: finance.themeText, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: finance.themeCard,
                  prefixIcon: Icon(Icons.notes_rounded, color: finance.themeTextSub, size: 20),
                  hintText: "Catatan opsional...",
                  hintStyle: TextStyle(color: finance.themeTextSub.withValues(alpha: 0.5)),
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
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        SystemNavigator.pop();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: finance.themeBorder)),
                        alignment: Alignment.center,
                        child: Text("Batal", style: TextStyle(color: finance.themeTextSub, fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: GestureDetector(
                      onTap: isReady ? () => _handleSubmit(finance) : null,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          color: isReady ? finance.themeAccent : finance.themeCard, 
                          borderRadius: BorderRadius.circular(20), 
                          border: Border.all(color: isReady ? finance.themeAccent : finance.themeBorder)
                        ),
                        alignment: Alignment.center,
                        child: _isSubmitting 
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text("Selesai & Tutup", style: TextStyle(color: isReady ? Colors.white : finance.themeTextSub, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                      ),
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
