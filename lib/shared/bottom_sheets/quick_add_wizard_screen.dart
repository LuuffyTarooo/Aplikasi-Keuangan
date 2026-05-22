import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';
import 'package:aplikasi_keuangan/models/category_model.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';
import 'package:aplikasi_keuangan/core/utils/audio_helper.dart';
import 'package:aplikasi_keuangan/core/utils/haptic_helper.dart';
import 'package:aplikasi_keuangan/core/utils/wallet_helper.dart';
import 'package:intl/intl.dart';

class QuickAddWizardScreen extends StatefulWidget {
  const QuickAddWizardScreen({super.key});

  @override
  State<QuickAddWizardScreen> createState() => _QuickAddWizardScreenState();
}

class _QuickAddWizardScreenState extends State<QuickAddWizardScreen> {
  int _currentStep = 0;

  // Transaction Data
  String _jenis = '';
  CategoryModel? _selectedKategori;
  String? _idDana;
  final TextEditingController _nominalController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _catatanController = TextEditingController();
  String? _idDanaTujuan;
  bool _isClosing = false;

  void _nextStep() {
    HapticFeedback.lightImpact();
    setState(() {
      _currentStep++;
    });
  }

  void _close() {
    setState(() => _isClosing = true);
    Future.delayed(const Duration(milliseconds: 200), () {
      SystemNavigator.pop();
    });
  }

  Future<void> _submit(FinanceProvider finance) async {
    final nominalRaw = _nominalController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final inputNominal = nominalRaw.isNotEmpty ? double.parse(nominalRaw) : 0.0;

    // Cegah crash jika dompet belum ter-load
    final fallbackDanaId = finance.mySumberDana.isNotEmpty
        ? finance.mySumberDana.first.idDana
        : 'default_wallet';

    final newTx = TransactionModel(
      idTransaksi: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      jenis: _jenis,
      nominal: inputNominal,
      idDana: _idDana ?? fallbackDanaId,
      idDanaTujuan: _idDanaTujuan,
      kategori: _jenis == 'Transfer'
          ? 'Transfer'
          : (_selectedKategori?.name ?? 'Lainnya'),
      keterangan: _catatanController.text.isEmpty
          ? 'Transaksi Cepat'
          : _catatanController.text,
      tanggal: _selectedDate.toIso8601String(),
      userId: finance.currentUser?.id ?? '',
    );

    finance.handleSaveTransaksi(newTx);
    AudioHelper.playSuccessSound();
    HapticHelper.success();

    await Future.delayed(const Duration(milliseconds: 600));
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final categories = _jenis == 'Pemasukan'
        ? finance.incomeCategories
        : finance.expenseCategories;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Invisible layer to dismiss
          GestureDetector(
            onTap: _close,
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),

          // The floating wizard
          Align(
            alignment: Alignment.topCenter,
            child: SafeArea(
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _isClosing ? 0.0 : 1.0,
                child: AnimatedScale(
                  duration: const Duration(milliseconds: 200),
                  scale: _isClosing ? 0.9 : 1.0,
                  curve: Curves.easeOutBack,
                  child: Container(
                    margin: const EdgeInsets.only(top: 24, left: 16, right: 16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: finance.themeCard,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: finance.themeBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _buildStepContent(finance, categories),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent(
    FinanceProvider finance,
    List<CategoryModel> categories,
  ) {
    switch (_currentStep) {
      case 0:
        return _buildTipeStep(finance);
      case 1:
        if (_jenis == 'Transfer') {
          return _buildDompetStep(finance, isSumber: true);
        }
        return _buildKategoriStep(finance, categories);
      case 2:
        if (_jenis == 'Transfer') {
          return _buildDompetStep(finance, isSumber: false);
        }
        return _buildDompetStep(finance, isSumber: true);
      case 3:
        return _buildNominalStep(finance);
      case 4:
        return _buildTanggalStep(finance);
      case 5:
        return _buildCatatanStep(finance);
      default:
        return const SizedBox();
    }
  }

  // STEP 0: TIPE
  Widget _buildTipeStep(FinanceProvider finance) {
    return Padding(
      key: const ValueKey(0),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tipe",
            style: TextStyle(color: finance.themeTextSub, fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildOptionTile("Pemasukan", finance, () {
            _jenis = 'Pemasukan';
            _nextStep();
          }),
          Divider(color: finance.themeBorder, height: 1),
          _buildOptionTile("Pengeluaran", finance, () {
            _jenis = 'Pengeluaran';
            _nextStep();
          }),
          Divider(color: finance.themeBorder, height: 1),
          _buildOptionTile("Transfer", finance, () {
            _jenis = 'Transfer';
            _nextStep();
          }),
        ],
      ),
    );
  }

  // STEP 1: KATEGORI
  Widget _buildKategoriStep(
    FinanceProvider finance,
    List<CategoryModel> categories,
  ) {
    return Padding(
      key: const ValueKey(1),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Kategori",
            style: TextStyle(color: finance.themeTextSub, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((k) {
              return ActionChip(
                label: Text(k.name),
                avatar: Icon(k.icon, size: 16, color: k.accentColor),
                backgroundColor: finance.themeBg,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: finance.themeBorder),
                ),
                onPressed: () {
                  _selectedKategori = k;
                  _nextStep();
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // STEP 2: DOMPET
  Widget _buildDompetStep(FinanceProvider finance, {required bool isSumber}) {
    return Padding(
      key: ValueKey(isSumber ? 2 : 25),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isSumber ? "Sumber Dana" : "Tujuan Dana",
            style: TextStyle(color: finance.themeTextSub, fontSize: 14),
          ),
          const SizedBox(height: 16),
          Column(
            children: finance.mySumberDana.map((d) {
              if (!isSumber && d.idDana == _idDana) {
                return const SizedBox(); // Cegah transfer ke dompet yang sama
              }
              return Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: WalletHelper.getWalletLogo(d.namaAset, size: 'sm'),
                    title: Text(
                      d.namaAset,
                      style: TextStyle(color: finance.themeText),
                    ),
                    subtitle: Text(
                      Formatters.formatCurrency(d.saldoTerkini),
                      style: TextStyle(color: finance.themeTextSub),
                    ),
                    onTap: () {
                      if (isSumber) {
                        _idDana = d.idDana;
                      } else {
                        _idDanaTujuan = d.idDana;
                      }
                      _nextStep();
                    },
                  ),
                  if (d != finance.mySumberDana.last)
                    Divider(color: finance.themeBorder, height: 1),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // STEP 3: NOMINAL
  Widget _buildNominalStep(FinanceProvider finance) {
    return Padding(
      key: const ValueKey(3),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Nominal",
            style: TextStyle(color: finance.themeTextSub, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nominalController,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: finance.themeText,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            inputFormatters: [CurrencyInputFormatter()],
            decoration: InputDecoration(
              prefixIconConstraints: const BoxConstraints(minWidth: 40),
              prefixIcon: Text(
                "${Formatters.activeCurrency.symbol} ",
                style: TextStyle(
                  color: finance.themeTextSub,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              border: InputBorder.none,
              hintText: "0",
              hintStyle: TextStyle(
                color: finance.themeTextSub.withOpacity(0.5),
              ),
            ),
            onSubmitted: (_) => _nextStep(),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                if (_nominalController.text.isNotEmpty) _nextStep();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: finance.themeAccent,
                foregroundColor: Colors.black,
              ),
              child: const Text("Lanjut"),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 4: TANGGAL
  Widget _buildTanggalStep(FinanceProvider finance) {
    return Padding(
      key: const ValueKey(4),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Tanggal",
            style: TextStyle(color: finance.themeTextSub, fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildOptionTile("Hari Ini", finance, () {
            _selectedDate = DateTime.now();
            _nextStep();
          }),
          Divider(color: finance.themeBorder, height: 1),
          _buildOptionTile("Kemarin", finance, () {
            _selectedDate = DateTime.now().subtract(const Duration(days: 1));
            _nextStep();
          }),
          Divider(color: finance.themeBorder, height: 1),
          _buildOptionTile("Pilih Manual...", finance, () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (date != null) {
              _selectedDate = date;
              _nextStep();
            }
          }),
        ],
      ),
    );
  }

  // STEP 5: CATATAN
  Widget _buildCatatanStep(FinanceProvider finance) {
    return Padding(
      key: const ValueKey(5),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Catatan (Opsional)",
            style: TextStyle(color: finance.themeTextSub, fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _catatanController,
            autofocus: true,
            style: TextStyle(color: finance.themeText, fontSize: 16),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "Masukkan catatan...",
              hintStyle: TextStyle(
                color: finance.themeTextSub.withOpacity(0.5),
              ),
            ),
            onSubmitted: (_) => _submit(finance),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => _submit(finance),
                child: Text(
                  "Lewati",
                  style: TextStyle(color: finance.themeTextSub),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _submit(finance),
                style: ElevatedButton.styleFrom(
                  backgroundColor: finance.themeAccent,
                  foregroundColor: Colors.black,
                ),
                child: const Text("Simpan"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(
    String title,
    FinanceProvider finance,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                color: finance.themeText,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
