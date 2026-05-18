// lib/shared/widgets/calculator_numpad.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFFA855F7), surface: Color(0xFF161B22)),
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
    final displayString = _formatDisplay();

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161B22).withValues(alpha:0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          border: const Border(top: BorderSide(color: Colors.white10)),
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
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha:0.05), 
                        borderRadius: BorderRadius.circular(16), 
                        border: Border.all(color: Colors.white10)
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_month_rounded, size: 16, color: Colors.white54),
                          const SizedBox(width: 8),
                          Text(_getShortIndoDate(_tanggal), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // 🟢 FIX: Murni TextField tanpa Container Double Card!
                  Expanded(
                    child: TextField(
                      controller: _catatanController,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        hintText: "Catatan...",
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon: const Icon(Icons.edit_rounded, size: 16, color: Colors.white54),
                        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF9333EA))),
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
                    style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -1),
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
                        Row(children: [ Expanded(child: _buildBtn('7')), const SizedBox(width: 10), Expanded(child: _buildBtn('8')), const SizedBox(width: 10), Expanded(child: _buildBtn('9')) ]),
                        const SizedBox(height: 10),
                        Row(children: [ Expanded(child: _buildBtn('4')), const SizedBox(width: 10), Expanded(child: _buildBtn('5')), const SizedBox(width: 10), Expanded(child: _buildBtn('6')) ]),
                        const SizedBox(height: 10),
                        Row(children: [ Expanded(child: _buildBtn('1')), const SizedBox(width: 10), Expanded(child: _buildBtn('2')), const SizedBox(width: 10), Expanded(child: _buildBtn('3')) ]),
                        const SizedBox(height: 10),
                        Row(children: [ Expanded(child: _buildBtn('0')), const SizedBox(width: 10), Expanded(child: _buildBtn('000', fontSize: 18)), const SizedBox(width: 10), Expanded(child: _buildBtn('+', isOp: true)) ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch, 
                      children: [
                        _buildBtn('DEL', isDel: true),
                        const SizedBox(height: 10),
                        _buildBtn('-', isOp: true),
                        const SizedBox(height: 10),
                        _buildBtn('OK', isSubmit: true),
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

  Widget _buildBtn(String label, {bool isOp = false, bool isDel = false, bool isSubmit = false, double fontSize = 24}) {
    Color bgColor = Colors.white.withValues(alpha:0.05);
    Color textColor = Colors.white;
    Border border = Border.all(color: Colors.white10);
    double height = 56;

    if (isSubmit) {
      bgColor = const Color(0xFF9333EA);
      textColor = Colors.white;
      border = Border.all(color: const Color(0xFF9333EA).withValues(alpha:0.5));
      height = 56 * 2 + 10; 
    } else if (isDel) {
      textColor = Colors.pinkAccent;
    } else if (isOp) {
      textColor = const Color(0xFFA855F7);
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
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 32)
                : Text(label, style: TextStyle(color: textColor, fontSize: fontSize, fontWeight: FontWeight.w900)),
      ),
    );
  }
}