// lib/shared/widgets/calculator_numpad.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_keuangan/providers/finance_provider.dart';

class CalculatorNumpad extends StatefulWidget {
  final String initialCatatan;
  final String initialTanggal; 
  final Function(double nominal, String catatan, String tanggal) onSubmit;

  const CalculatorNumpad({
    super.key,
    this.initialCatatan = '',
    required this.initialTanggal,
    required this.onSubmit,
  });

  static void show(
    BuildContext context, {
    String initialCatatan = '',
    required String initialTanggal,
    required Function(double nominal, String catatan, String tanggal) onSubmit,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CalculatorNumpad(
        initialCatatan: initialCatatan,
        initialTanggal: initialTanggal,
        onSubmit: (nom, cat, tgl) {
          Navigator.pop(context); 
          onSubmit(nom, cat, tgl);
        },
      ),
    );
  }

  @override
  State<CalculatorNumpad> createState() => _CalculatorNumpadState();
}

class _CalculatorNumpadState extends State<CalculatorNumpad> {
  String _expression = '0';
  late TextEditingController _catatanController;
  late DateTime _tanggal;

  @override
  void initState() {
    super.initState();
    _catatanController = TextEditingController(text: widget.initialCatatan);
    _tanggal = DateTime.tryParse(widget.initialTanggal) ?? DateTime.now();
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  void _handlePress(String val) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_expression == '0' && val != '+' && val != '-' && val != '000') {
        _expression = val;
        return;
      }
      if (val == '+' || val == '-') {
        final lastChar = _expression.substring(_expression.length - 1);
        if (lastChar == '+' || lastChar == '-') {
          _expression = _expression.substring(0, _expression.length - 1) + val;
          return;
        }
      }
      _expression += val;
    });
  }

  void _handleBackspace() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_expression.length > 1) {
        _expression = _expression.substring(0, _expression.length - 1);
      } else {
        _expression = '0';
      }
    });
  }

  double _calculateResult() {
    try {
      List<String> tokens = [];
      String currentNum = '';
      
      for (int i = 0; i < _expression.length; i++) {
        String char = _expression[i];
        if (char == '+' || char == '-') {
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
      }
      return result;
    } catch (e) {
      return 0;
    }
  }

  void _handleSubmit() {
    HapticFeedback.heavyImpact();
    final result = _calculateResult();
    
    if (result < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nominal nggak boleh minus!')));
      return;
    }
    if (result == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nominal nggak boleh 0!')));
      return;
    }

    widget.onSubmit(result, _catatanController.text, _tanggal.toIso8601String());
  }

  String _formatDisplay() {
    String output = '';
    String currentNum = '';
    
    for (int i = 0; i < _expression.length; i++) {
      String char = _expression[i];
      if (char == '+' || char == '-') {
        if (currentNum.isNotEmpty) {
          output += NumberFormat('#,###').format(int.parse(currentNum)).replaceAll(',', '.');
          currentNum = '';
        }
        output += ' $char ';
      } else {
        currentNum += char;
      }
    }
    if (currentNum.isNotEmpty) {
      output += NumberFormat('#,###').format(int.parse(currentNum)).replaceAll(',', '.');
    }
    return output;
  }

  String _getShortIndoDate(DateTime date) {
    final List<String> shortMonths = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    String day = date.day.toString().padLeft(2, '0');
    String month = shortMonths[date.month - 1];
    return "$day $month ${date.year}";
  }

  Future<void> _selectDate(FinanceProvider finance) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(primary: finance.themeAccent, surface: finance.themeCard),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _tanggal = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    final displayString = _formatDisplay();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: finance.themeBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: Border(top: BorderSide(color: finance.themeBorder)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.5), blurRadius: 40, offset: const Offset(0, -10))],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --- BARIS INPUT (TANGGAL & CATATAN ANTI DOUBLE CARD) ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => _selectDate(finance),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: finance.themeCard, 
                        borderRadius: BorderRadius.circular(16), 
                        border: Border.all(color: finance.themeBorder)
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_month_rounded, size: 16, color: finance.themeTextSub),
                          const SizedBox(width: 8),
                          Text(_getShortIndoDate(_tanggal), style: TextStyle(color: finance.themeText, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // 🟢 FIX: Murni TextField tanpa Container Double Card!
                  Expanded(
                    child: TextField(
                      controller: _catatanController,
                      style: TextStyle(color: finance.themeText, fontSize: 12, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: finance.themeCard,
                        hintText: "Catatan...",
                        hintStyle: TextStyle(color: finance.themeTextSub.withValues(alpha: 0.5)),
                        prefixIcon: Icon(Icons.edit_rounded, size: 16, color: finance.themeTextSub),
                        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: finance.themeBorder)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: finance.themeBorder)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: finance.themeAccent)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // --- TAMPILAN NOMINAL ---
              Container(
                height: 60, 
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    displayString,
                    style: TextStyle(color: finance.themeText, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // --- GRID NUMPAD ---
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      children: [
                        Row(children: [ Expanded(child: _buildBtn('7', finance)), const SizedBox(width: 10), Expanded(child: _buildBtn('8', finance)), const SizedBox(width: 10), Expanded(child: _buildBtn('9', finance)) ]),
                        const SizedBox(height: 10),
                        Row(children: [ Expanded(child: _buildBtn('4', finance)), const SizedBox(width: 10), Expanded(child: _buildBtn('5', finance)), const SizedBox(width: 10), Expanded(child: _buildBtn('6', finance)) ]),
                        const SizedBox(height: 10),
                        Row(children: [ Expanded(child: _buildBtn('1', finance)), const SizedBox(width: 10), Expanded(child: _buildBtn('2', finance)), const SizedBox(width: 10), Expanded(child: _buildBtn('3', finance)) ]),
                        const SizedBox(height: 10),
                        Row(children: [ Expanded(child: _buildBtn('0', finance)), const SizedBox(width: 10), Expanded(child: _buildBtn('000', finance, fontSize: 18)), const SizedBox(width: 10), Expanded(child: _buildBtn('+', finance, isOp: true)) ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch, 
                      children: [
                        _buildBtn('DEL', finance, isDel: true),
                        const SizedBox(height: 10),
                        _buildBtn('-', finance, isOp: true),
                        const SizedBox(height: 10),
                        _buildBtn('OK', finance, isSubmit: true),
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBtn(String label, FinanceProvider finance, {bool isOp = false, bool isDel = false, bool isSubmit = false, double fontSize = 24}) {
    Color bgColor = finance.themeCard;
    Color textColor = finance.themeText;
    Border border = Border.all(color: finance.themeBorder);
    double height = 56;

    if (isSubmit) {
      bgColor = finance.themeAccent;
      textColor = Colors.black;
      border = Border.all(color: finance.themeAccent.withValues(alpha:0.5));
      height = 56 * 2 + 10; 
    } else if (isDel) {
      textColor = Colors.pinkAccent;
    } else if (isOp) {
      textColor = finance.themeAccent;
    }

    return GestureDetector(
      onTap: () {
        if (isSubmit) {
          _handleSubmit();
        } else if (isDel) {
          _handleBackspace();
        } else {
          _handlePress(label);
        }
      },
      child: Container(
        height: height,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(20), border: border),
        alignment: Alignment.center,
        child: isDel
            ? const Icon(Icons.backspace_rounded, color: Colors.pinkAccent)
            : isSubmit
                ? const Icon(Icons.check_rounded, color: Colors.black, size: 32)
                : Text(label, style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: FontWeight.w900)),
      ),
    );
  }
}