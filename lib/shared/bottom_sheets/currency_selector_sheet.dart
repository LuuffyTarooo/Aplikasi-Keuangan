// lib/shared/bottom_sheets/currency_selector_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/models/currency_model.dart';
import 'package:aplikasi_keuangan/utils/currency_manager.dart';

class CurrencySelectorSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _CurrencySheetContent(),
    );
  }
}

class _CurrencySheetContent extends StatefulWidget {
  const _CurrencySheetContent();

  @override
  State<_CurrencySheetContent> createState() => _CurrencySheetContentState();
}

class _CurrencySheetContentState extends State<_CurrencySheetContent> {
  CurrencyModel? _selectedCurrency;
  final TextEditingController _rateController = TextEditingController();
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    _selectedCurrency = CurrencyManager.defaultCurrencies.firstWhere(
      (c) => c.code == finance.currentCurrency.code,
      orElse: () => CurrencyManager.defaultCurrencies.first,
    );
    if (_selectedCurrency!.code != 'IDR') {
      _rateController.text = finance.currentCurrency.exchangeRateToIdr.toInt().toString();
    }
  }

  void _save(FinanceProvider finance) {
    if (_selectedCurrency == null) return;
    
    double customRate = 1.0;
    if (_selectedCurrency!.code != 'IDR') {
      customRate = double.tryParse(_rateController.text) ?? 0.0;
      if (customRate <= 0) {
        setState(() { _errorMsg = 'Nilai kurs tidak valid!'; });
        return;
      }
    }
    
    finance.updateCurrency(_selectedCurrency!, customRate);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final isCustomRateNeeded = _selectedCurrency != null && _selectedCurrency!.code != 'IDR';

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: finance.themeBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: finance.themeBorder)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Pilih Mata Uang", style: TextStyle(color: finance.themeText, fontSize: 20, fontWeight: FontWeight.w900)),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: finance.themeCard, shape: BoxShape.circle, border: Border.all(color: finance.themeBorder)),
                    child: Icon(Icons.close_rounded, color: finance.themeTextSub, size: 20),
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            Text("Sesuaikan mata uang yang ingin ditampilkan. Jika mata uang asing, tentukan kurs ke Rupiah.", style: TextStyle(color: finance.themeTextSub, fontSize: 12)),
            const SizedBox(height: 24),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CurrencyManager.defaultCurrencies.map((c) {
                final isSelected = _selectedCurrency?.code == c.code;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    setState(() { 
                      _selectedCurrency = c; 
                      _errorMsg = '';
                      if (c.code == 'IDR') {
                        _rateController.clear();
                      } else {
                        _rateController.text = c.exchangeRateToIdr.toInt().toString();
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? finance.themeAccent.withValues(alpha: 0.15) : finance.themeCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? finance.themeAccent : finance.themeBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(c.symbol, style: TextStyle(color: isSelected ? finance.themeAccent : finance.themeTextSub, fontWeight: FontWeight.w900, fontSize: 14)),
                        const SizedBox(width: 8),
                        Text(c.code, style: TextStyle(color: isSelected ? finance.themeAccent : finance.themeTextSub, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            if (isCustomRateNeeded) ...[
              const SizedBox(height: 24),
              Text("NILAI KURS CUSTOM", style: TextStyle(color: finance.themeTextSub, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
              const SizedBox(height: 8),
              TextField(
                controller: _rateController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: finance.themeText, fontSize: 24, fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: finance.themeCard,
                  prefixIconConstraints: const BoxConstraints(minWidth: 60),
                  prefixIcon: Center(
                    widthFactor: 1.0,
                    child: Text("Rp", style: TextStyle(color: finance.themeTextSub, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  suffixText: "/ 1 ${_selectedCurrency!.code}",
                  suffixStyle: TextStyle(color: finance.themeTextSub, fontWeight: FontWeight.bold, fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: finance.themeBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: finance.themeBorder)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: finance.themeAccent, width: 2)),
                ),
                onChanged: (_) => setState(() => _errorMsg = ''),
              ),
              if (_errorMsg.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_errorMsg, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
              ]
            ],

            const SizedBox(height: 32),
            GestureDetector(
              onTap: () { HapticFeedback.heavyImpact(); _save(finance); },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(color: finance.themeAccent, borderRadius: BorderRadius.circular(24)),
                alignment: Alignment.center,
                child: const Text("Simpan Pengaturan", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
