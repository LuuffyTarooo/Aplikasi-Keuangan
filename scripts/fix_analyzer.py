import os
import re

def fix_file(filepath, fixes):
    if not os.path.exists(filepath):
        return
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for old, new in fixes:
        new_content = new_content.replace(old, new)
        
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Fixed {filepath}")

fixes_map = {
    r'c:\Users\fajar\aplikasi_keuangan\lib\shared\bottom_sheets\add_wallet_sheet.dart': [
        ('TransactionTypes.income', "'Pemasukan'")
    ],
    r'c:\Users\fajar\aplikasi_keuangan\lib\screens\transaction\transaction_form_screen.dart': [
        ("dompetTujuan.walletName ?? ''", "dompetTujuan.walletName")
    ],
    r'c:\Users\fajar\aplikasi_keuangan\lib\screens\dashboard\wallets\manage_wallets_screen.dart': [
        ("import 'package:aplikasi_keuangan/core/utils/wallet_logo_resolver.dart';\n", "")
    ],
    r'c:\Users\fajar\aplikasi_keuangan\lib\screens\report\widgets\history_section.dart': [
        ("import 'package:aplikasi_keuangan/shared/bottom_sheets/add_wallet_sheet.dart';\n", "")
    ],
    r'c:\Users\fajar\aplikasi_keuangan\lib\shared\bottom_sheets\quick_add_wizard_screen.dart': [
        ("import 'package:aplikasi_keuangan/core/utils/wallet_logo_resolver.dart';\n", ""),
        ("import 'package:aplikasi_keuangan/shared/bottom_sheets/add_wallet_sheet.dart';\n", "")
    ],
    r'c:\Users\fajar\aplikasi_keuangan\lib\shared\bottom_sheets\quick_transaction_sheet.dart': [
        ("import 'package:aplikasi_keuangan/core/utils/wallet_logo_resolver.dart';\n", ""),
        ("import 'package:aplikasi_keuangan/shared/bottom_sheets/add_wallet_sheet.dart';\n", "")
    ]
}

for filepath, fixes in fixes_map.items():
    fix_file(filepath, fixes)
