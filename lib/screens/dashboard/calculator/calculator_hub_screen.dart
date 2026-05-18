// lib/screens/calculator/calculator_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _activeTab = 'dasar';

  // --- STATE KALKULATOR DASAR ---
  String _calcExpr = '';
  String _calcResult = '';

  // --- STATE DISKON & PAJAK ---
  String _hargaAsli = '';
  String _diskonPersen = '';
  String _pajakPersen = '11';

  // --- STATE PATUNGAN ---
  String _totalTagihan = '';
  String _biayaTambahan = '';
  String _jumlahOrang = '2';

  // --- STATE CICILAN ---
  String _hargaBarang = '';
  String _uangMuka = '';
  String _bungaTahun = '';
  String _tenorBulan = '12';

  // =====================================
  // ⚡ LOGIKA KALKULATOR DASAR
  // =====================================
  void _handleNumpad(String val) {
    HapticFeedback.lightImpact();
    setState(() {
      if (val == 'C') {
        _calcExpr = '';
        _calcResult = '';
      } else if (val == 'DEL') {
        if (_calcExpr.isNotEmpty) _calcExpr = _calcExpr.substring(0, _calcExpr.length - 1);
      } else if (val == '=') {
        _calcResult = _calculateExpression(_calcExpr);
      } else {
        _calcExpr += val;
      }
    });
  }

  String _calculateExpression(String expr) {
    try {
      String sanitized = expr.replaceAll('x', '*').replaceAll('÷', '/');
      if (sanitized.isEmpty) return '';

      List<String> tokens = [];
      String currentNum = '';
      for (int i = 0; i < sanitized.length; i++) {
        String char = sanitized[i];
        if (char == '+' || char == '-' || char == '*' || char == '/') {
          if (currentNum.isNotEmpty) tokens.add(currentNum);
          tokens.add(char);
          currentNum = '';
        } else {
          currentNum += char;
        }
      }
      if (currentNum.isNotEmpty) tokens.add(currentNum);

      double result = double.parse(tokens[0]);
      for (int i = 1; i < tokens.length; i += 2) {
        String op = tokens[i];
        double nextNum = double.parse(tokens[i + 1]);
        if (op == '+') result += nextNum;
        if (op == '-') result -= nextNum;
        if (op == '*') result *= nextNum;
        if (op == '/') result /= nextNum;
      }
      return NumberFormat('#,###', 'id_ID').format(result);
    } catch (e) {
      return 'Error';
    }
  }

  String _formatRibuan(String val) {
    if (val.isEmpty) return '';
    return NumberFormat('#,###', 'id_ID').format(int.tryParse(val.replaceAll(RegExp(r'\D'), '')) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);

    // === KALKULASI DISKON ===
    double numHarga = double.tryParse(_hargaAsli.replaceAll(RegExp(r'\D'), '')) ?? 0;
    double numDiskon = double.tryParse(_diskonPersen) ?? 0;
    double numPajak = double.tryParse(_pajakPersen) ?? 0;
    double nilaiDiskon = numHarga * (numDiskon / 100);
    double hargaSetelahDiskon = numHarga - nilaiDiskon;
    double nilaiPajak = hargaSetelahDiskon * (numPajak / 100);
    double totalHargaDiskon = hargaSetelahDiskon + nilaiPajak;

    // === KALKULASI PATUNGAN ===
    double numTagihan = double.tryParse(_totalTagihan.replaceAll(RegExp(r'\D'), '')) ?? 0;
    double numTambahan = double.tryParse(_biayaTambahan.replaceAll(RegExp(r'\D'), '')) ?? 0;
    int numOrang = int.tryParse(_jumlahOrang) ?? 1;
    if (numOrang == 0) numOrang = 1;
    double totalSemuaSplit = numTagihan + numTambahan;
    double bayarPerOrang = totalSemuaSplit / numOrang;

    // === KALKULASI CICILAN ===
    double numBarang = double.tryParse(_hargaBarang.replaceAll(RegExp(r'\D'), '')) ?? 0;
    double numDP = double.tryParse(_uangMuka.replaceAll(RegExp(r'\D'), '')) ?? 0;
    double numBunga = double.tryParse(_bungaTahun) ?? 0;
    int numTenor = int.tryParse(_tenorBulan) ?? 1;
    if (numTenor == 0) numTenor = 1;
    double pokokHutang = (numBarang - numDP) > 0 ? (numBarang - numDP) : 0;
    double totalBunga = pokokHutang * (numBunga / 100) * (numTenor / 12);
    double totalHutang = pokokHutang + totalBunga;
    double cicilanPerBulan = totalHutang / numTenor;

    return Scaffold(
      backgroundColor: finance.themeBg, // 🟢 AUTO-SYNC: Latar Belakang Solid
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: finance.themeCard, shape: BoxShape.circle, border: Border.all(color: finance.themeBorder)),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: finance.themeText, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Kalkulator", style: TextStyle(color: finance.themeText, fontSize: 24, fontWeight: FontWeight.w900)),
                      Text("ALAT HITUNG PINTAR", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ],
                  ),
                ],
              ),
            ),

            // --- TAB NAVIGATOR ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  _buildTabButton('dasar', Icons.calculate_rounded, 'Dasar', finance),
                  _buildTabButton('diskon', Icons.percent_rounded, 'Diskon', finance),
                  _buildTabButton('split', Icons.people_rounded, 'Patungan', finance),
                  _buildTabButton('cicilan', Icons.credit_card_rounded, 'Cicilan', finance),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- KONTEN (Sesuai Tab) ---
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: _activeTab == 'dasar' ? _buildKalkulatorDasar(finance) :
                       _activeTab == 'diskon' ? _buildDiskonPajak(finance, numHarga, nilaiDiskon, numDiskon, nilaiPajak, numPajak, totalHargaDiskon) :
                       _activeTab == 'split' ? _buildSplitBill(finance, totalSemuaSplit, numOrang, bayarPerOrang) :
                       _buildCicilan(finance, pokokHutang, totalBunga, numTenor, totalHutang, cicilanPerBulan),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // TAB 1: KALKULATOR DASAR
  // =========================================================
  Widget _buildKalkulatorDasar(FinanceProvider finance) {
    String displayResult = _calcResult.isNotEmpty ? _calcResult : (_calcExpr.isNotEmpty ? _calcExpr : '0');
    double fontSize = displayResult.length > 15 ? 24 : (displayResult.length > 10 ? 32 : 48);

    return Column(
      children: [
        // Layar Tampilan
        Container(
          width: double.infinity,
          height: 160, 
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: finance.themeBorder)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(_calcExpr, style: TextStyle(color: finance.themeTextSub, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              FittedBox(fit: BoxFit.scaleDown, child: Text(displayResult, style: TextStyle(color: finance.themeText, fontSize: fontSize, fontWeight: FontWeight.w900))),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Numpad Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.1,
          children: [
            _buildNumpadBtn('C', finance, color: Colors.pinkAccent, bgColor: Colors.pinkAccent.withValues(alpha:0.1)),
            _buildNumpadBtn('(', finance), _buildNumpadBtn(')', finance),
            _buildNumpadBtn('÷', finance, color: finance.themeAccent, bgColor: finance.themeAccent.withValues(alpha:0.1)),

            _buildNumpadBtn('7', finance), _buildNumpadBtn('8', finance), _buildNumpadBtn('9', finance),
            _buildNumpadBtn('x', finance, color: finance.themeAccent, bgColor: finance.themeAccent.withValues(alpha:0.1)),

            _buildNumpadBtn('4', finance), _buildNumpadBtn('5', finance), _buildNumpadBtn('6', finance),
            _buildNumpadBtn('-', finance, color: finance.themeAccent, bgColor: finance.themeAccent.withValues(alpha:0.1)),

            _buildNumpadBtn('1', finance), _buildNumpadBtn('2', finance), _buildNumpadBtn('3', finance),
            _buildNumpadBtn('+', finance, color: finance.themeAccent, bgColor: finance.themeAccent.withValues(alpha:0.1)),

            _buildNumpadBtn('0', finance), _buildNumpadBtn('.', finance),
            _buildNumpadBtn('DEL', finance, icon: Icons.backspace_rounded, color: finance.themeTextSub),
            _buildNumpadBtn('=', finance, color: Colors.white, bgColor: finance.themeAccent), // = Selalu pakai warna solid
          ],
        )
      ],
    );
  }

  // =========================================================
  // TAB 2: DISKON & PAJAK
  // =========================================================
  Widget _buildDiskonPajak(FinanceProvider finance, double hrg, double nDskn, double pDskn, double nPjk, double pPjk, double ttl) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: finance.themeBorder)),
          child: Column(
            children: [
              _buildInput("Harga Asli", _hargaAsli, (v) => setState(() => _hargaAsli = v), "Rp", finance),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildInput("Diskon (%)", _diskonPersen, (v) => setState(() => _diskonPersen = v), "%", finance)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInput("Pajak/PB1 (%)", _pajakPersen, (v) => setState(() => _pajakPersen = v), "%", finance)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildResultCard(
          finance: finance,
          items: [
            {"label": "Harga Awal", "value": Formatters.formatCurrency(hrg), "color": finance.themeText},
            {"label": "Diskon ($pDskn%)", "value": "-${Formatters.formatCurrency(nDskn)}", "color": Colors.greenAccent},
            {"label": "Pajak ($pPjk%)", "value": "+${Formatters.formatCurrency(nPjk)}", "color": finance.themeTextSub},
          ],
          totalLabel: "Total Yang Harus Dibayar",
          totalValue: Formatters.formatCurrency(ttl),
        ),
      ],
    );
  }

  // =========================================================
  // TAB 3: PATUNGAN (SPLIT BILL)
  // =========================================================
  Widget _buildSplitBill(FinanceProvider finance, double ttlSemua, int numOrg, double byrPerOrg) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: finance.themeBorder)),
          child: Column(
            children: [
              _buildInput("Total Tagihan Makan", _totalTagihan, (v) => setState(() => _totalTagihan = v), "Rp", finance),
              const SizedBox(height: 16),
              _buildInput("Biaya Layanan/Pajak", _biayaTambahan, (v) => setState(() => _biayaTambahan = v), "+", finance),
              const SizedBox(height: 16),
              _buildInput("Dibagi Berapa Orang?", _jumlahOrang, (v) => setState(() => _jumlahOrang = v), "Orang", finance),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildResultCard(
          finance: finance,
          items: [
            {"label": "Total Semua Tagihan", "value": Formatters.formatCurrency(ttlSemua), "color": finance.themeText},
            {"label": "Jumlah Teman", "value": "$numOrg Orang", "color": finance.themeTextSub},
          ],
          totalLabel: "Patungan Per Orang",
          totalValue: Formatters.formatCurrency(byrPerOrg),
        ),
      ],
    );
  }

  // =========================================================
  // TAB 4: CICILAN (KREDIT)
  // =========================================================
  Widget _buildCicilan(FinanceProvider finance, double pkHutang, double ttlBunga, int nTnr, double ttlHutang, double cicilan) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: finance.themeBorder)),
          child: Column(
            children: [
              _buildInput("Harga Barang", _hargaBarang, (v) => setState(() => _hargaBarang = v), "Rp", finance),
              const SizedBox(height: 16),
              _buildInput("Uang Muka / DP", _uangMuka, (v) => setState(() => _uangMuka = v), "-", finance),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildInput("Bunga/Tahun (%)", _bungaTahun, (v) => setState(() => _bungaTahun = v), "%", finance)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInput("Tenor (Bulan)", _tenorBulan, (v) => setState(() => _tenorBulan = v), "Bln", finance)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _buildResultCard(
          finance: finance,
          items: [
            {"label": "Pokok Hutang (Harga - DP)", "value": Formatters.formatCurrency(pkHutang), "color": finance.themeText},
            {"label": "Total Bunga ($nTnr Bln)", "value": "+${Formatters.formatCurrency(ttlBunga)}", "color": Colors.pinkAccent},
            {"label": "Total Keseluruhan", "value": Formatters.formatCurrency(ttlHutang), "color": finance.themeText},
          ],
          totalLabel: "Cicilan Per Bulan",
          totalValue: Formatters.formatCurrency(cicilan),
        ),
      ],
    );
  }

  // --- HELPERS UI ---

  Widget _buildTabButton(String id, IconData icon, String label, FinanceProvider finance) {
    bool isActive = _activeTab == id;
    return GestureDetector(
      onTap: () { HapticFeedback.mediumImpact(); setState(() => _activeTab = id); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? finance.themeAccent.withValues(alpha:0.1) : finance.themeCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isActive ? finance.themeAccent.withValues(alpha:0.5) : finance.themeBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActive ? finance.themeAccent : finance.themeTextSub, size: 16),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isActive ? finance.themeText : finance.themeTextSub, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpadBtn(String label, FinanceProvider finance, {IconData? icon, Color? color, Color? bgColor}) {
    return GestureDetector(
      onTap: () => _handleNumpad(label),
      child: Container(
        decoration: BoxDecoration(color: bgColor ?? finance.themeCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: finance.themeBorder)),
        alignment: Alignment.center,
        child: icon != null 
          ? Icon(icon, color: color ?? finance.themeText, size: 24)
          : Text(label, style: TextStyle(color: color ?? finance.themeText, fontSize: 24, fontWeight: FontWeight.w900)),
      ),
    );
  }

  Widget _buildInput(String label, String value, Function(String) onChanged, String iconText, FinanceProvider finance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: finance.themeBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: finance.themeBorder)),
          child: Row(
            children: [
              Text(iconText, style: TextStyle(color: finance.themeAccent, fontSize: 14, fontWeight: FontWeight.w900)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (val) {
                    if (iconText == "Rp" || iconText == "+") {
                      onChanged(_formatRibuan(val)); 
                    } else {
                      onChanged(val);
                    }
                  },
                  controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
                  style: TextStyle(color: finance.themeText, fontSize: 14, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(hintText: "0", hintStyle: TextStyle(color: finance.themeTextSub.withValues(alpha:0.5)), border: InputBorder.none),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard({required FinanceProvider finance, required List<Map<String, dynamic>> items, required String totalLabel, required String totalValue}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: finance.themeAccent.withValues(alpha:0.05), borderRadius: BorderRadius.circular(32), border: Border.all(color: finance.themeAccent.withValues(alpha:0.2))),
      child: Column(
        children: [
          ...items.map((i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(i['label'], style: TextStyle(color: finance.themeTextSub, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(i['value'], style: TextStyle(color: i['color'], fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          )),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: finance.themeBorder)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(totalLabel.toUpperCase(), style: TextStyle(color: finance.themeAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                const SizedBox(height: 4),
                FittedBox(fit: BoxFit.scaleDown, child: Text(totalValue, style: TextStyle(color: finance.themeText, fontSize: 32, fontWeight: FontWeight.w900))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}