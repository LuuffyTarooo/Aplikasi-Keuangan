// lib/screens/transaction/transaction_form_screen.dart
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

  String? _errorMsg;
  bool _isSuccess = false;
  bool _isSubmitting = false;

  final LayerLink _walletLink = LayerLink();
  final LayerLink _targetWalletLink = LayerLink();
  bool _isWalletDropdownOpen = false;
  bool _isTargetWalletDropdownOpen = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

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
              decoration: BoxDecoration(color: finance.themeBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), border: Border(top: BorderSide(color: finance.themeBorder))),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Buat Dompet Baru", style: TextStyle(color: finance.themeText, fontSize: 20, fontWeight: FontWeight.w900)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: finance.themeCard, shape: BoxShape.circle, border: Border.all(color: finance.themeBorder)), child: Icon(Icons.close_rounded, color: finance.themeTextSub, size: 20)),
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
                          Text("NAMA DOMPET CUSTOM", style: TextStyle(color: finance.themeTextSub, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: finance.themeBorder)),
                            child: Row(
                              children: [
                                WalletHelper.getWalletLogo(inputName.isEmpty ? 'NE' : inputName, size: 'sm'),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    onChanged: (val) => setSheetState(() => inputName = val),
                                    style: TextStyle(color: finance.themeText, fontSize: 16, fontWeight: FontWeight.w900),
                                    decoration: InputDecoration(border: InputBorder.none, hintText: "cth: Celengan BCA", hintStyle: TextStyle(color: finance.themeTextSub.withValues(alpha:0.5), fontWeight: FontWeight.normal)),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
                          Text("ATAU PILIH TEMPLATE CEPAT", style: TextStyle(color: finance.themeTextSub, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
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
                                  decoration: BoxDecoration(color: isSelected ? finance.themeAccent.withValues(alpha:0.1) : finance.themeCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? finance.themeAccent : finance.themeBorder)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      WalletHelper.getWalletLogo(template, size: 'sm'),
                                      const SizedBox(height: 10),
                                      Text(template, style: TextStyle(color: isSelected ? finance.themeAccent : finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                    decoration: BoxDecoration(color: finance.themeBg, border: Border(top: BorderSide(color: finance.themeBorder))),
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
                        decoration: BoxDecoration(color: inputName.isNotEmpty ? finance.themeAccent : finance.themeCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: inputName.isNotEmpty ? finance.themeAccent : finance.themeBorder)),
                        alignment: Alignment.center,
                        child: Text("Gunakan Dompet Ini", style: TextStyle(color: inputName.isNotEmpty ? Colors.white : finance.themeTextSub, fontWeight: FontWeight.w900, fontSize: 16)),
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



  Future<void> _selectDate(BuildContext context, FinanceProvider finance) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: _tanggal, firstDate: DateTime(2000), lastDate: DateTime(2101),
      builder: (context, child) { return Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.dark(primary: finance.themeAccent, onPrimary: Colors.white, surface: finance.themeCard, onSurface: finance.themeText)), child: child!); },
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

    final dompetAsal = finance.mySumberDana.firstWhere((d) => d.idDana == _idDana);
    final inputNominal = double.parse(_nominal);

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

  List<CategoryModel> _getDisplayCategories(FinanceProvider finance) {
    return _jenis == 'Pengeluaran' ? finance.expenseCategories : finance.incomeCategories;
  }

  Widget _buildDropdownOverlay(bool isTujuan, FinanceProvider finance) {
    final link = isTujuan ? _targetWalletLink : _walletLink;
    return CompositedTransformFollower(
      link: link,
      offset: const Offset(0, 62), 
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
              color: finance.themeBg, // 🟢 Dropdown solid
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: finance.themeBorder),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (finance.mySumberDana.isEmpty)
                    Padding(padding: const EdgeInsets.all(16), child: Text("Belum ada dompet", textAlign: TextAlign.center, style: TextStyle(color: finance.themeTextSub))),
                    
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
                          color: isSelected ? finance.themeAccent.withValues(alpha:0.1) : finance.themeCard, 
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? finance.themeAccent : finance.themeBorder),
                        ),
                        child: Row(
                          children: [
                            WalletHelper.getWalletLogo(dompet.namaAset, size: 'sm'),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(dompet.namaAset, style: TextStyle(color: isSelected ? finance.themeAccent : finance.themeText, fontWeight: FontWeight.w900, fontSize: 13)),
                                  Text(Formatters.formatCurrency(dompet.saldoTerkini), style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  
                  if (_jenis == 'Pemasukan') ...[
                    Divider(color: finance.themeBorder, height: 16),
                    
                    GestureDetector(
                      onTap: () {
                        setState(() { _isWalletDropdownOpen = false; _isTargetWalletDropdownOpen = false; });
                        _showAddWalletSheet(context, finance);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: finance.themeBorder, style: BorderStyle.solid)), 
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add, color: finance.themeTextSub, size: 16),
                            const SizedBox(width: 6),
                            Text("DOMPET BARU", style: TextStyle(color: finance.themeTextSub, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.0)),
                          ],
                        ),
                      ),
                    )
                  ]
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
      backgroundColor: finance.themeBg, // 🟢 Murni Latar Solid
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(onTap: () => Navigator.pop(context), child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: finance.themeCard, shape: BoxShape.circle, border: Border.all(color: finance.themeBorder)), child: Icon(Icons.arrow_back_ios_new_rounded, color: finance.themeTextSub, size: 18))),
                      Expanded(child: Center(child: Text("Tambah Transaksi", style: TextStyle(color: finance.themeText, fontSize: 18, fontWeight: FontWeight.bold)))),
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
                          decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(30), border: Border.all(color: finance.themeBorder)),
                          child: Row(
                            children: ['Pengeluaran', 'Pemasukan', 'Transfer'].map((tab) {
                              final isActive = _jenis == tab;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () { HapticFeedback.lightImpact(); setState(() { _jenis = tab; _kategori = ''; }); },
                                  child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: isActive ? finance.themeAccent : Colors.transparent, borderRadius: BorderRadius.circular(30)), alignment: Alignment.center, child: Text(tab, style: TextStyle(color: isActive ? Colors.white : finance.themeTextSub, fontWeight: FontWeight.bold, fontSize: 13))),
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
                              Text("${Formatters.activeCurrency.symbol} ", style: TextStyle(color: _nominal.isEmpty ? finance.themeTextSub.withValues(alpha:0.5) : finance.themeTextSub, fontSize: 32, fontWeight: FontWeight.bold)),
                              Text(_nominal.isEmpty ? "0" : Formatters.formatRibuan(_nominal), style: TextStyle(color: _nominal.isEmpty ? finance.themeTextSub.withValues(alpha:0.5) : finance.themeText, fontSize: _nominal.length > 8 ? 48 : 64, fontWeight: FontWeight.w900, letterSpacing: -1)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: CompositedTransformTarget(
                                      link: _walletLink,
                                      child: _buildPillTile(
                                        finance: finance,
                                        widget: Row(mainAxisAlignment: MainAxisAlignment.center, children: [if (dompetAsal.namaAset != 'Pilih Dompet') ...[WalletHelper.getWalletLogo(dompetAsal.namaAset, size: 'sm'), const SizedBox(width: 8)], Flexible(child: Text(dompetAsal.namaAset, style: TextStyle(color: finance.themeText, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis))]), 
                                        onTap: () => setState(() { _isWalletDropdownOpen = !_isWalletDropdownOpen; _isTargetWalletDropdownOpen = false; })
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildPillTile(
                                      finance: finance,
                                      widget: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.calendar_today_rounded, color: finance.themeTextSub, size: 16), const SizedBox(width: 8), Text(isToday ? "Hari Ini" : DateFormat('dd MMM').format(_tanggal), style: TextStyle(color: finance.themeText, fontWeight: FontWeight.bold, fontSize: 14))]), 
                                      onTap: () => _selectDate(context, finance)
                                    )
                                  ),
                                ],
                              ),

                              if (_jenis == 'Transfer') ...[
                                const SizedBox(height: 12),
                                CompositedTransformTarget(
                                  link: _targetWalletLink,
                                  child: _buildPillTile(
                                    finance: finance,
                                    widget: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.sync_alt_rounded, color: finance.themeTextSub, size: 16), const SizedBox(width: 8), Text(dompetTujuan?.namaAset ?? "Pilih Tujuan...", style: TextStyle(color: finance.themeText, fontWeight: FontWeight.bold, fontSize: 14))]), 
                                    onTap: () => setState(() { _isTargetWalletDropdownOpen = !_isTargetWalletDropdownOpen; _isWalletDropdownOpen = false; }), 
                                    borderColor: finance.themeAccent.withValues(alpha:0.5)
                                  ),
                                ),
                              ],

                              const SizedBox(height: 12),
                              
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: finance.themeBorder)),
                                child: TextField(
                                  onChanged: (val) {
                                    _keterangan = val;
                                  },
                                  controller: TextEditingController(text: _keterangan)..selection = TextSelection.collapsed(offset: _keterangan.length),
                                  style: TextStyle(color: finance.themeText, fontSize: 14, fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(icon: Icon(Icons.notes_rounded, color: finance.themeTextSub, size: 20), border: InputBorder.none, hintText: "Tambah catatan...", hintStyle: TextStyle(color: finance.themeTextSub.withValues(alpha: 0.5))),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (_jenis != 'Transfer') ...[
                          const SizedBox(height: 20),
                          SizedBox(
                            height: 48,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              scrollDirection: Axis.horizontal,
                              itemCount: listKategori.isEmpty ? 1 : listKategori.length, 
                              itemBuilder: (context, index) {
                                final kat = listKategori.isEmpty ? finance.getCategoryByName('') : listKategori[index];
                                final isSelected = _kategori == kat.name;
                                return GestureDetector(
                                  onTap: () { HapticFeedback.lightImpact(); setState(() { _kategori = kat.name; }); },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200), 
                                    margin: const EdgeInsets.only(right: 10), 
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), 
                                    decoration: BoxDecoration(
                                      color: isSelected ? kat.bgColor : finance.themeCard, 
                                      borderRadius: BorderRadius.circular(24), 
                                      border: Border.all(color: isSelected ? kat.accentColor.withValues(alpha: 0.5) : finance.themeBorder)
                                    ), 
                                    child: Row(
                                      children: [
                                        Icon(kat.icon, size: 18, color: isSelected ? kat.accentColor : finance.themeTextSub), 
                                        const SizedBox(width: 8), 
                                        Text(kat.name, style: TextStyle(color: isSelected ? kat.accentColor : finance.themeTextSub, fontSize: 13, fontWeight: FontWeight.bold))
                                      ]
                                    )
                                  ),
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
                            child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 20), decoration: BoxDecoration(color: isReadyToSave ? finance.themeAccent : finance.themeCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: isReadyToSave ? finance.themeAccent : finance.themeBorder)), alignment: Alignment.center, child: _isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(widget.initialData != null ? "Update Transaksi" : "Simpan $_jenis", style: TextStyle(color: isReadyToSave ? Colors.white : finance.themeTextSub, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5))),
                          ),
                        ),
                        
                        const SizedBox(height: 24),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: GridView.count(
                            shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 3, childAspectRatio: 1.8, mainAxisSpacing: 12, crossAxisSpacing: 12,
                            children: [
                              _buildNumpadBtn('1', finance), _buildNumpadBtn('2', finance), _buildNumpadBtn('3', finance), _buildNumpadBtn('4', finance), _buildNumpadBtn('5', finance), _buildNumpadBtn('6', finance), _buildNumpadBtn('7', finance), _buildNumpadBtn('8', finance), _buildNumpadBtn('9', finance), _buildNumpadBtn('000', finance), _buildNumpadBtn('0', finance), _buildNumpadBtn('backspace', finance, icon: Icons.backspace_outlined),
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
            Positioned(top: 40, left: 20, right: 20, child: Material(color: Colors.transparent, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.2), shape: BoxShape.circle), child: const Icon(Icons.error_outline, color: Colors.white, size: 16)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text("Oops, ada yang kurang!", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), const SizedBox(height: 2), Text(_errorMsg!, style: const TextStyle(color: Colors.white70, fontSize: 12))])), GestureDetector(onTap: () => setState(() => _errorMsg = null), child: const Icon(Icons.close, color: Colors.white, size: 20))])))),

          if (_isSuccess)
            Positioned.fill(child: Container(color: finance.themeBg.withValues(alpha: 0.9), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [TweenAnimationBuilder<double>(tween: Tween(begin: 0.0, end: 1.0), duration: const Duration(milliseconds: 500), curve: Curves.elasticOut, builder: (context, value, child) { return Transform.scale(scale: value, child: Container(width: 100, height: 100, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: Colors.white, size: 60))); }), const SizedBox(height: 24), Text("Mantap!", style: TextStyle(color: finance.themeText, fontSize: 32, fontWeight: FontWeight.w900)), const SizedBox(height: 8), Text("Transaksi berhasil dicatat.", style: TextStyle(color: finance.themeTextSub, fontSize: 14, fontWeight: FontWeight.bold))]))),
        ],
      ),
    );
  }

  Widget _buildPillTile({required FinanceProvider finance, required Widget widget, required VoidCallback onTap, Color? borderColor}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54, 
        padding: const EdgeInsets.symmetric(horizontal: 12), 
        decoration: BoxDecoration(
          color: finance.themeCard, 
          borderRadius: BorderRadius.circular(20), 
          border: Border.all(color: borderColor ?? finance.themeBorder),
        ), 
        alignment: Alignment.center, 
        child: widget,
      ),
    );
  }

  Widget _buildNumpadBtn(String val, FinanceProvider finance, {IconData? icon}) {
    return GestureDetector(
      onTap: () => _handleNumpad(val),
      child: Container(
        decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: finance.themeBorder)), 
        alignment: Alignment.center, 
        child: icon != null ? Icon(icon, color: finance.themeText, size: 24) : Text(val, style: TextStyle(color: finance.themeText, fontSize: 24, fontWeight: FontWeight.w500))
      ),
    );
  }
}