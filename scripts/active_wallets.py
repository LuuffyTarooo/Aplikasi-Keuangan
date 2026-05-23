import os

def add_active_wallets_getter():
    filepath = r'C:\Users\fajar\aplikasi_keuangan\lib\providers\finance_provider.dart'
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    getter_code = """  /// Dompet aktif milik user.
  List<WalletModel> get myActiveWallets =>
      myWallets.where((d) => d.isActive).toList();
"""
    
    if "List<WalletModel> get myActiveWallets" not in content:
        # Insert after myWallets
        old_getter = """  List<WalletModel> get myWallets =>
      currentUser == null ? [] : allWallets.where((d) => d.userId == currentUser!.id).toList();"""
        
        if old_getter in content:
            content = content.replace(old_getter, old_getter + "\n\n" + getter_code)
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print("Added myActiveWallets to finance_provider.dart")

def replace_in_files():
    files_to_update = [
        r'C:\Users\fajar\aplikasi_keuangan\lib\screens\transaction\transaction_form_screen.dart',
        r'C:\Users\fajar\aplikasi_keuangan\lib\shared\bottom_sheets\quick_add_wizard_screen.dart',
        r'C:\Users\fajar\aplikasi_keuangan\lib\shared\bottom_sheets\quick_transaction_sheet.dart'
    ]
    
    for filepath in files_to_update:
        if not os.path.exists(filepath):
            continue
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        new_content = content.replace('finance.myWallets', 'finance.myActiveWallets')
        # fix: if transaction detail sheet or history needs all wallets, we might have accidentally changed it. 
        # But those 3 files are exclusively for ADDING transactions, so active wallets are correct!
        
        if new_content != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Updated {os.path.basename(filepath)}")

if __name__ == '__main__':
    add_active_wallets_getter()
    replace_in_files()
