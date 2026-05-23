import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    
    # Imports
    old_import = "import 'package:aplikasi_keuangan/core/utils/wallet_helper.dart';"
    new_imports = """import 'package:aplikasi_keuangan/core/utils/wallet_logo_resolver.dart';
import 'package:aplikasi_keuangan/shared/widgets/wallet_logo_widget.dart';
import 'package:aplikasi_keuangan/shared/bottom_sheets/add_wallet_sheet.dart';"""
    
    # Relative imports in some places?
    old_import_rel_1 = "import '../../core/utils/wallet_helper.dart';"
    new_imports_rel_1 = """import '../../core/utils/wallet_logo_resolver.dart';
import '../../shared/widgets/wallet_logo_widget.dart';
import '../../shared/bottom_sheets/add_wallet_sheet.dart';"""

    new_content = new_content.replace(old_import, new_imports)
    new_content = new_content.replace(old_import_rel_1, new_imports_rel_1)
    
    # Method replacements
    # WalletHelper.hasLogo(name) -> WalletLogoResolver.hasLogo(name)
    new_content = new_content.replace('WalletHelper.hasLogo(', 'WalletLogoResolver.hasLogo(')
    
    # WalletHelper.showAddWalletDialog(context, finance) -> AddWalletSheet.show(context, finance)
    new_content = new_content.replace('WalletHelper.showAddWalletDialog(', 'AddWalletSheet.show(')
    
    # WalletHelper.getWalletLogo(name, size: 'sm') -> WalletLogoWidget(walletName: name, size: 'sm')
    # Use regex for getWalletLogo because it has arguments
    new_content = re.sub(r'WalletHelper\.getWalletLogo\((.*?),\s*size:\s*(.*?)\)', r'WalletLogoWidget(walletName: \1, size: \2)', new_content)
    new_content = re.sub(r'WalletHelper\.getWalletLogo\((.*?)\)', r'WalletLogoWidget(walletName: \1)', new_content)
    
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

def process_dir(directory):
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    process_dir(r'C:\Users\fajar\aplikasi_keuangan\lib')
