// lib/screens/transaction/transaction_form_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/finance_provider.dart';
import '../../models/transaction_model.dart';
import '../../models/wallet_model.dart';
import '../../models/category_model.dart'; 

import '../../core/utils/formatters.dart';
import '../../core/utils/wallet_helper.dart';
import '../../core/utils/category_suggester.dart';

class TransactionFormScreen extends StatefulWidget {
  final TransactionModel? initialData;

  const TransactionFormScreen({super.key, this.initialData});

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> with SingleTickerProviderStateMixin {
  String _jenis = 'Pengeluaran';
  String _nominal = '';
  String _kategori = '';
  String _keterangan = '';
  String _idDana = '';
  String _idDanaTujuan = '';
  DateTime _tanggal = DateTime.now();

  bool _hasManuallyChangedCategory = false; 

  String? _errorMsg;
  bool _isSuccess = false;
  bool _isSubmitting = false;

  final LayerLink _walletLink = LayerLink();
  final LayerLink _targetWalletLink = LayerLink();
  bool _isWalletDropdownOpen = false;
  bool _isTargetWalletDropdownOpen = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  final List<String> _reqPengeluaran = ['Makan & Minuman', 'Transportasi', 'Belanja', 'Tagihan', 'Rumah Tangga', 'Hiburan', 'Kesehatan', 'Transfer Temen', 'Pendidikan', 'Peliharaan'];
  final List<String> _reqPemasukan = ['Gaji', 'Bonus', 'Investasi', 'Hadiah', 'Upah'];

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnimation = Tween<double>(begin: 0, end: 10).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);

    if (widget.initialData != null) {
      _jenis = widget.initialData!.jenis;
      _nominal = widget.initialData!.nominal.toInt().toString();
      _kategori = widget.initialData!.kategori;
      _keterangan = widget.initialData!.keterangan;
      _idDana = widget.initialData!.idDana;
      _idDanaTujuan = widget.initialData!.idDanaTujuan ?? '';
      _tanggal = DateTime.parse(widget.initialData!.tanggal);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final finance = Provider.of<FinanceProvider>(context, listen: false);
        if (finance.mySumberDana.isNotEmpty) {
          setState(() => _idDana = finance.mySumberDana.first.idDana);
        }
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    HapticFeedback.heavyImpact();
    setState(() => _errorMsg = msg);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _errorMsg = null);
    });
  }

  void _triggerShake() {
    _shakeController.forward(from: 0);
  }

  void _handleNumpad(String value) {
    HapticFeedback.lightImpact();
    setState(() {
      if (value == 'backspace') {
        if (_nominal.isNotEmpty) _nominal = _nominal.substring(0, _nominal.length - 1);
      } else {
        if (!(_nominal.isEmpty && (value == '000' || value == '0'))) {
          if (_nominal.length < 12) {
            _nominal += value;
          }
        }
      }
    });
  }

  void _showAddWalletSheet(BuildContext context, FinanceProvider finance) {
    String inputName = '';
    final controller = TextEditingController();
    final listTemplateBank = WalletHelper.popularWallets; 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: const BoxDecoration(color: Color(0xFF161B22), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Buat Dompet Baru", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 20)),
                        )
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text("NAMA DOMPET CUSTOM", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: const Color(0xFF222730), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                            child: Row(
                              children: [
                                WalletHelper.getWalletLogo(inputName.isEmpty ? 'NE' : inputName, size: 'sm'),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    onChanged: (val) => setSheetState(() => inputName = val),
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                                    decoration: const InputDecoration(border: InputBorder.none, hintText: "cth: Celengan BCA", hintStyle: TextStyle(color: Colors.white30, fontWeight: FontWeight.normal)),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
                          const Text("ATAU PILIH TEMPLATE CEPAT", style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                          const SizedBox(height: 16),

                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 0.85, crossAxisSpacing: 12, mainAxisSpacing: 12),
                            itemCount: listTemplateBank.length,
                            itemBuilder: (context, index) {
                              final template = listTemplateBank[index];
                              final isSelected = inputName.toLowerCase() == template.toLowerCase();
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setSheetState(() { inputName = template; controller.text = template; });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(color: isSelected ? const Color(0xFF10B981).withValues(alpha:0.1) : const Color(0xFF222730), borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? const Color(0xFF10B981) : Colors.white10)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      WalletHelper.getWalletLogo(template, size: 'sm'),
                                      const SizedBox(height: 10),
                                      Text(template, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontSize: 10, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 40), 
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    decoration: const BoxDecoration(color: Color(0xFF161B22), border: Border(top: BorderSide(color: Colors.white10))),
                    child: GestureDetector(
                      onTap: () {
                        if (inputName.isNotEmpty) {
                          final newWallet = WalletModel(idDana: 'd_${DateTime.now().millisecondsSinceEpoch}', namaAset: inputName, saldoAwal: 0, saldoTerkini: 0, userId: finance.currentUser?.id ?? '', isActive: true);
                          finance.allSumberDana.add(newWallet);
                          setState(() => _idDana = newWallet.idDana);
                          finance.switchUser(finance.currentUser!.id); 
                          Navigator.pop(context);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(color: inputName.isNotEmpty ? const Color(0xFF10B981) : Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(24), boxShadow: inputName.isNotEmpty ? [BoxShadow(color: const Color(0xFF10B981).withValues(alpha:0.4), blurRadius: 20)] : null),
                        alignment: Alignment.center,
                        child: Text("Gunakan Dompet Ini", style: TextStyle(color: inputName.isNotEmpty ? Colors.white : Colors.white54, fontWeight: FontWeight.w900, fontSize: 16)),
                      ),
                    ),
                  )
                ],
              ),
            );
          }
        );
      }
    );
  }

  void _showManageCategorySheet(BuildContext context, FinanceProvider finance) {
    String newCatName = '';
    String editingCatId = '';
    String editCatName = '';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentCategories = finance.myKategori.where((k) => k.jenis == _jenis).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: const BoxDecoration(color: Color(0xFF1E1B38), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Atur Kategori", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 20)),
                        )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFF0A0514), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                            child: TextField(
                              onChanged: (val) => setModalState(() => newCatName = val),
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(border: InputBorder.none, hintText: "Kategori baru...", hintStyle: TextStyle(color: Colors.white30)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            if (newCatName.trim().isNotEmpty) {
                              final newCat = CategoryModel(id: 'k_${DateTime.now().millisecondsSinceEpoch}', name: newCatName.trim(), jenis: _jenis, userId: finance.currentUser?.id ?? '');
                              finance.allKategori.add(newCat);
                              finance.switchUser(finance.currentUser!.id); 
                              setModalState(() => newCatName = '');
                            }
                          },
                          child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: _themeColor, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.add, color: Colors.white, size: 20)),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      physics: const BouncingScrollPhysics(),
                      itemCount: currentCategories.length,
                      itemBuilder: (context, index) {
                        final kat = currentCategories[index];
                        final isEditing = editingCatId == kat.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white10)),
                          child: isEditing 
                            ? Row(
                                children: [
                                  Expanded(child: TextField(autofocus: true, onChanged: (val) => setModalState(() => editCatName = val), controller: TextEditingController(text: editCatName)..selection = TextSelection.collapsed(offset: editCatName.length), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold), decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero))),
                                  IconButton(
                                    icon: const Icon(Icons.check_circle, color: Colors.greenAccent),
                                    onPressed: () {
                                      if (editCatName.trim().isNotEmpty) {
                                        final idx = finance.allKategori.indexWhere((k) => k.id == kat.id);
                                        if (idx != -1) {
                                          finance.allKategori[idx] = CategoryModel(id: kat.id, name: editCatName.trim(), jenis: kat.jenis, userId: finance.currentUser?.id ?? '');
                                          finance.switchUser(finance.currentUser!.id);
                                        }
                                      }
                                      setModalState(() => editingCatId = '');
                                    },
                                  )
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(kat.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                  Row(
                                    children: [
                                      IconButton(icon: const Icon(Icons.edit_outlined, color: Colors.white54, size: 18), onPressed: () => setModalState(() { editingCatId = kat.id; editCatName = kat.name; })),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                        onPressed: () { finance.allKategori.removeWhere((k) => k.id == kat.id); finance.switchUser(finance.currentUser!.id); setModalState(() {}); },
                                      ),
                                    ],
                                  )
                                ],
                              ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: _tanggal, firstDate: DateTime(2000), lastDate: DateTime(2101),
      builder: (context, child) { return Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.dark(primary: _themeColor, onPrimary: Colors.white, surface: const Color(0xFF1E1B38), onSurface: Colors.white)), child: child!); },
    );
    if (picked != null && picked != _tanggal) setState(() { _tanggal = picked; });
  }

void _handleSubmit(FinanceProvider finance) async {
    if (_isSubmitting) return;

    if (finance.mySumberDana.isEmpty) return _showError('Bikin dompet dulu ya Jar!');
    if (_nominal.isEmpty || _nominal == '0') {
      _triggerShake();
      return _showError('Isi nominal transaksinya dulu ya, Jar!');
    }
    if (_jenis == 'Transfer' && _idDanaTujuan.isEmpty) return _showError('Pilih dompet tujuannya dulu!');
    if (_jenis == 'Transfer' && _idDana == _idDanaTujuan) return _showError('Dompet asal dan tujuan nggak boleh sama!');
    if (_jenis != 'Transfer' && _kategori.isEmpty) return _showError('Pilih kategori transaksinya dulu!');

    // 🟢 GEMBOK SALDO MINUS!
    // Ambil data dompet asal yang dipilih
    final dompetAsal = finance.mySumberDana.firstWhere((d) => d.idDana == _idDana);
    final inputNominal = double.parse(_nominal);

    // Cek buat Pengeluaran atau Transfer
    if (_jenis == 'Pengeluaran' || _jenis == 'Transfer') {
      if (inputNominal > dompetAsal.saldoTerkini) {
        _triggerShake();
        return _showError('Saldo ${dompetAsal.namaAset} kurang! Sisa: ${Formatters.formatCurrency(dompetAsal.saldoTerkini)}');
      }
    }

    setState(() => _isSubmitting = true);

    final newTx = TransactionModel(
      idTransaksi: widget.initialData?.idTransaksi ?? '',
      jenis: _jenis, nominal: inputNominal,
      idDana: _idDana, idDanaTujuan: _jenis == 'Transfer' ? _idDanaTujuan : null,
      kategori: _jenis == 'Transfer' ? 'Transfer' : _kategori,
      keterangan: _keterangan.isEmpty ? 'Transaksi' : _keterangan,
      tanggal: _tanggal.toIso8601String(),
      userId: finance.currentUser!.id,
    );

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() { _isSubmitting = false; _isSuccess = true; });

    finance.handleSaveTransaksi(newTx);
    HapticFeedback.mediumImpact();
    
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) Navigator.pop(context);
  }

  Color get _themeColor {
    if (_jenis == 'Pemasukan') return const Color(0xFF10B981); 
    if (_jenis == 'Transfer') return const Color(0xFF3B82F6); 
    return const Color(0xFFFF0055); 
  }

  List<CategoryModel> _getDisplayCategories(FinanceProvider finance) {
    List<CategoryModel> cats = finance.myKategori.toList();
    if (!cats.any((k) => k.jenis == 'Pengeluaran')) {
      for (var c in _reqPengeluaran) { cats.add(CategoryModel(id: 'auto_$c', name: c, jenis: 'Pengeluaran', userId: finance.currentUser?.id ?? '')); }
    }
    if (!cats.any((k) => k.jenis == 'Pemasukan')) {
      for (var c in _reqPemasukan) { cats.add(CategoryModel(id: 'auto_$c', name: c, jenis: 'Pemasukan', userId: finance.currentUser?.id ?? '')); }
    }
    return cats.where((k) => k.jenis == _jenis).toList();
  }

  Widget _buildDropdownOverlay(bool isTujuan, FinanceProvider finance) {
    final link = isTujuan ? _targetWalletLink : _walletLink;
    return CompositedTransformFollower(
      link: link,
      offset: const Offset(0, 62), // 🟢 Disesuaikan dengan tinggi baru card
      showWhenUnlinked: false,
      child: Align(
        alignment: Alignment.topLeft,
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 250,
            constraints: const BoxConstraints(maxHeight: 300),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0514).withValues(alpha: 0.98),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (finance.mySumberDana.isEmpty)
                    const Padding(padding: EdgeInsets.all(16), child: Text("Belum ada dompet", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54))),
                    
                  ...finance.mySumberDana.map((dompet) {
                    if (isTujuan && dompet.idDana == _idDana) return const SizedBox.shrink();
                    final isSelected = isTujuan ? _idDanaTujuan == dompet.idDana : _idDana == dompet.idDana;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          if (isTujuan) { _idDanaTujuan = dompet.idDana; _isTargetWalletDropdownOpen = false; } 
                          else { _idDana = dompet.idDana; _isWalletDropdownOpen = false; }
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected ? _themeColor : Colors.transparent, 
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected ? Border.all(color: Colors.white.withValues(alpha:0.2)) : null,
                        ),
                        child: Row(
                          children: [
                            WalletHelper.getWalletLogo(dompet.namaAset, size: 'sm'),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(dompet.namaAset, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontWeight: FontWeight.w900, fontSize: 13)),
                                  Text(Formatters.formatCurrency(dompet.saldoTerkini), style: TextStyle(color: isSelected ? Colors.white.withValues(alpha:0.8) : Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  
                  const Divider(color: Colors.white10, height: 16),
                  
                  GestureDetector(
                    onTap: () {
                      setState(() { _isWalletDropdownOpen = false; _isTargetWalletDropdownOpen = false; });
                      _showAddWalletSheet(context, finance);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha:0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3), style: BorderStyle.solid)), 
                      alignment: Alignment.center,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add, color: Color(0xFF10B981), size: 16),
                          SizedBox(width: 6),
                          Text("DOMPET BARU", style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final isToday = DateFormat('yyyy-MM-dd').format(_tanggal) == DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    final emptyWallet = WalletModel(idDana: '', namaAset: 'Pilih Dompet', saldoAwal: 0, saldoTerkini: 0, userId: '');
    final dompetAsal = finance.mySumberDana.isEmpty ? emptyWallet : finance.mySumberDana.firstWhere((d) => d.idDana == _idDana, orElse: () => finance.mySumberDana.first);
    final dompetTujuan = (_idDanaTujuan.isNotEmpty && finance.mySumberDana.isNotEmpty) ? finance.mySumberDana.firstWhere((d) => d.idDana == _idDanaTujuan, orElse: () => finance.mySumberDana.first) : null;

    final listKategori = _getDisplayCategories(finance);
    final bool isReadyToSave = _nominal.isNotEmpty && _nominal != '0' && (_jenis == 'Transfer' ? _idDanaTujuan.isNotEmpty : _kategori.isNotEmpty);

    return Scaffold(
      backgroundColor: const Color(0xFF05010D),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF2A1054), Color(0xFF0A0514)], stops: [0.0, 0.4]))),
          Positioned(top: -50, right: -50, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF7C3AED).withValues(alpha: 0.2)))),
          Positioned(top: MediaQuery.of(context).size.height * 0.3, left: -100, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFC026D3).withValues(alpha: 0.1)))),
          Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80.0, sigmaY: 80.0), child: Container(color: Colors.transparent))),

          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), shape: BoxShape.circle), child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18))),
                      const Expanded(child: Center(child: Text("Tambah Transaksi", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))),
                      const SizedBox(width: 42), 
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 10),

                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: const Color(0xFF1E1B38).withValues(alpha:0.5), borderRadius: BorderRadius.circular(30), border: Border.all(color: Colors.white10)),
                          child: Row(
                            children: ['Pengeluaran', 'Pemasukan', 'Transfer'].map((tab) {
                              final isActive = _jenis == tab;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () { HapticFeedback.lightImpact(); setState(() { _jenis = tab; _kategori = ''; _hasManuallyChangedCategory = false; }); },
                                  child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: isActive ? _themeColor : Colors.transparent, borderRadius: BorderRadius.circular(30), boxShadow: isActive ? [BoxShadow(color: _themeColor.withValues(alpha:0.5), blurRadius: 15)] : null), alignment: Alignment.center, child: Text(tab, style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontWeight: FontWeight.bold, fontSize: 13))),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 32),

                        AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(_shakeAnimation.value * ((_shakeController.status == AnimationStatus.forward || _shakeController.status == AnimationStatus.reverse) ? (_shakeController.value < 0.5 ? 1 : -1) : 0), 0),
                              child: child,
                            );
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text("Rp ", style: TextStyle(color: _nominal.isEmpty ? Colors.white30 : Colors.white70, fontSize: 32, fontWeight: FontWeight.bold)),
                              Text(_nominal.isEmpty ? "0" : Formatters.formatRibuan(_nominal), style: TextStyle(color: _nominal.isEmpty ? Colors.white30 : Colors.white, fontSize: _nominal.length > 8 ? 48 : 64, fontWeight: FontWeight.w900, letterSpacing: -1)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              // 🟢 FIXED HEIGHT LOCK: Tinggi dikunci mati di 54px & alignment: Center
                              Row(
                                children: [
                                  Expanded(
                                    child: CompositedTransformTarget(
                                      link: _walletLink,
                                      child: _buildPillTile(
                                        widget: Row(mainAxisAlignment: MainAxisAlignment.center, children: [if (dompetAsal.namaAset != 'Pilih Dompet') ...[WalletHelper.getWalletLogo(dompetAsal.namaAset, size: 'sm'), const SizedBox(width: 8)], Flexible(child: Text(dompetAsal.namaAset, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis))]), 
                                        onTap: () => setState(() { _isWalletDropdownOpen = !_isWalletDropdownOpen; _isTargetWalletDropdownOpen = false; })
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildPillTile(
                                      widget: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 16), const SizedBox(width: 8), Text(isToday ? "Hari Ini" : DateFormat('dd MMM').format(_tanggal), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))]), 
                                      onTap: () => _selectDate(context)
                                    )
                                  ),
                                ],
                              ),

                              if (_jenis == 'Transfer') ...[
                                const SizedBox(height: 12),
                                CompositedTransformTarget(
                                  link: _targetWalletLink,
                                  child: _buildPillTile(
                                    widget: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.sync_alt_rounded, color: Colors.white70, size: 16), const SizedBox(width: 8), Text(dompetTujuan?.namaAset ?? "Pilih Tujuan...", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))]), 
                                    onTap: () => setState(() { _isTargetWalletDropdownOpen = !_isTargetWalletDropdownOpen; _isWalletDropdownOpen = false; }), 
                                    borderColor: const Color(0xFF3B82F6).withValues(alpha:0.5)
                                  ),
                                ),
                              ],

                              const SizedBox(height: 12),
                              
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFF1E1B38), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white10)),
                                child: TextField(
                                  onChanged: (val) {
                                    _keterangan = val;
                                    if (!_hasManuallyChangedCategory && _jenis != 'Transfer') {
                                      final autoKat = CategorySuggester.suggestCategory(val); 
                                      if (autoKat != null && listKategori.any((k) => k.name == autoKat)) _kategori = autoKat;
                                    }
                                    setState(() {});
                                  },
                                  controller: TextEditingController(text: _keterangan)..selection = TextSelection.collapsed(offset: _keterangan.length),
                                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                                  decoration: const InputDecoration(icon: Icon(Icons.notes_rounded, color: Colors.white54, size: 20), border: InputBorder.none, hintText: "Tambah catatan...", hintStyle: TextStyle(color: Colors.white30)),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_jenis != 'Transfer') ...[
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 44,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              scrollDirection: Axis.horizontal,
                              itemCount: listKategori.length + 1, 
                              itemBuilder: (context, index) {
                                if (index == listKategori.length) return GestureDetector(onTap: () => _showManageCategorySheet(context, finance), child: Container(margin: const EdgeInsets.only(left: 4), padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white.withValues(alpha:0.2), style: BorderStyle.solid)), child: const Row(children: [Icon(Icons.settings_outlined, size: 16, color: Colors.white54), SizedBox(width: 6), Text("Atur", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold))])));
                                final kat = listKategori[index];
                                final isSelected = _kategori == kat.name;
                                return GestureDetector(
                                  onTap: () { HapticFeedback.lightImpact(); setState(() { _kategori = kat.name; _hasManuallyChangedCategory = true; }); },
                                  child: AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), decoration: BoxDecoration(color: isSelected ? _themeColor.withValues(alpha:0.2) : const Color(0xFF1E1B38), borderRadius: BorderRadius.circular(24), border: Border.all(color: isSelected ? _themeColor : Colors.white10)), child: Row(children: [Icon(Icons.local_offer_outlined, size: 16, color: isSelected ? _themeColor : Colors.white54), const SizedBox(width: 8), Text(kat.name, style: TextStyle(color: isSelected ? Colors.white : Colors.white70, fontSize: 13, fontWeight: FontWeight.bold))])),
                                );
                              },
                            ),
                          ),
                        ],

                        const SizedBox(height: 32),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: GestureDetector(
                            onTap: () => _handleSubmit(finance),
                            child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20), decoration: BoxDecoration(color: isReadyToSave ? _themeColor : const Color(0xFF1E1B38), borderRadius: BorderRadius.circular(24), boxShadow: isReadyToSave ? [BoxShadow(color: _themeColor.withValues(alpha:0.4), blurRadius: 20)] : null), alignment: Alignment.center, child: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(widget.initialData != null ? "Update Transaksi" : "Simpan $_jenis", style: TextStyle(color: isReadyToSave ? Colors.white : Colors.white54, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5))),
                          ),
                        ),
                        
                        const SizedBox(height: 24),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: GridView.count(
                            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 3, childAspectRatio: 1.8, mainAxisSpacing: 12, crossAxisSpacing: 12,
                            children: [
                              _buildNumpadBtn('1'), _buildNumpadBtn('2'), _buildNumpadBtn('3'), _buildNumpadBtn('4'), _buildNumpadBtn('5'), _buildNumpadBtn('6'), _buildNumpadBtn('7'), _buildNumpadBtn('8'), _buildNumpadBtn('9'), _buildNumpadBtn('000'), _buildNumpadBtn('0'), _buildNumpadBtn('backspace', icon: Icons.backspace_outlined),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (_isWalletDropdownOpen || _isTargetWalletDropdownOpen)
            Positioned.fill(child: GestureDetector(onTap: () => setState(() { _isWalletDropdownOpen = false; _isTargetWalletDropdownOpen = false; }), child: Container(color: Colors.transparent))),

          if (_isWalletDropdownOpen) _buildDropdownOverlay(false, finance),
          if (_isTargetWalletDropdownOpen) _buildDropdownOverlay(true, finance),

          if (_errorMsg != null)
            Positioned(top: 40, left: 20, right: 20, child: Material(color: Colors.transparent, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha:0.4), blurRadius: 20)]), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.2), shape: BoxShape.circle), child: const Icon(Icons.error_outline, color: Colors.white, size: 16)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Oops, ada yang kurang!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 2), Text(_errorMsg!, style: const TextStyle(color: Colors.white70, fontSize: 12))])), GestureDetector(onTap: () => setState(() => _errorMsg = null), child: const Icon(Icons.close, color: Colors.white, size: 20))])))),

          if (_isSuccess)
            Positioned.fill(child: Container(color: const Color(0xFF05010D).withValues(alpha: 0.8), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [TweenAnimationBuilder<double>(tween: Tween(begin: 0.0, end: 1.0), duration: const Duration(milliseconds: 500), curve: Curves.elasticOut, builder: (context, value, child) { return Transform.scale(scale: value, child: Container(width: 100, height: 100, decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha:0.5), blurRadius: 40)]), child: const Icon(Icons.check_rounded, color: Colors.white, size: 60))); }), const SizedBox(height: 24), const Text("Mantap!", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900)), const SizedBox(height: 8), const Text("Transaksi berhasil dicatat.", style: TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.bold))])))),
        ],
      ),
    );
  }

  // 🟢 SEKARANG TINGGINYA DIKUNCI MATI (height: 54) & POSISI KONTEN OTOMATIS CENTER VERTIKAL
  Widget _buildPillTile({required Widget widget, required VoidCallback onTap, Color? borderColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54, 
        padding: const EdgeInsets.symmetric(horizontal: 12), 
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B38), 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: borderColor ?? Colors.white10),
        ), 
        alignment: Alignment.center, 
        child: widget,
      ),
    );
  }

  Widget _buildNumpadBtn(String val, {IconData? icon}) {
    return GestureDetector(
      onTap: () => _handleNumpad(val),
      child: Container(decoration: BoxDecoration(color: const Color(0xFF1E1B38), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withValues(alpha:0.02))), alignment: Alignment.center, child: icon != null ? Icon(icon, color: Colors.white, size: 24) : Text(val, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500))),
    );
  }
}