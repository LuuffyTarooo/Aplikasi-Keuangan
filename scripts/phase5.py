import os

def fix_wallet_model():
    filepath = r'C:\Users\fajar\aplikasi_keuangan\lib\models\wallet_model.dart'
    if not os.path.exists(filepath): return
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    safe_parse = """
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0.0;
    return 0.0;
  }
"""
    if "_parseDouble" not in content:
        content = content.replace("class WalletModel {", "class WalletModel {" + safe_parse)
    
    content = content.replace("(json['saldo_awal'] ?? 0).toDouble()", "_parseDouble(json['saldo_awal'])")
    content = content.replace("(json['saldo_terkini'] ?? 0).toDouble()", "_parseDouble(json['saldo_terkini'])")
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Fixed wallet_model.dart")

def fix_transaction_model():
    filepath = r'C:\Users\fajar\aplikasi_keuangan\lib\models\transaction_model.dart'
    if not os.path.exists(filepath): return
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    safe_parse = """
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(RegExp(r'[^0-9.-]'), '')) ?? 0.0;
    return 0.0;
  }
"""
    if "_parseDouble" not in content:
        content = content.replace("class TransactionModel {", "class TransactionModel {" + safe_parse)
    
    content = content.replace("(json['nominal'] ?? 0).toDouble()", "_parseDouble(json['nominal'])")
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Fixed transaction_model.dart")

def fix_quick_add():
    filepath = r'C:\Users\fajar\aplikasi_keuangan\lib\shared\bottom_sheets\quick_add_wizard_screen.dart'
    if not os.path.exists(filepath): return
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Add dispose
    dispose_code = """
  @override
  void dispose() {
    _nominalController.dispose();
    _catatanController.dispose();
    super.dispose();
  }
"""
    if "void dispose()" not in content:
        content = content.replace("class _QuickAddWizardScreenState extends State<QuickAddWizardScreen> {", "class _QuickAddWizardScreenState extends State<QuickAddWizardScreen> {" + dispose_code)

    # Add nominal validation
    old_submit = """  Future<void> _submit(FinanceProvider finance) async {
    final nominalRaw = _nominalController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final inputNominal = nominalRaw.isNotEmpty ? double.parse(nominalRaw) : 0.0;"""
    
    new_submit = """  Future<void> _submit(FinanceProvider finance) async {
    final nominalRaw = _nominalController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    final inputNominal = nominalRaw.isNotEmpty ? double.parse(nominalRaw) : 0.0;

    if (inputNominal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal tidak boleh 0 atau kosong')),
      );
      return;
    }"""
    
    content = content.replace(old_submit, new_submit)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Fixed quick_add_wizard_screen.dart")

if __name__ == '__main__':
    fix_wallet_model()
    fix_transaction_model()
    fix_quick_add()
