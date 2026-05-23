import os
import re

replacements = {
    r'\ballSumberDana\b': 'allWallets',
    r'\bmySumberDana\b': 'myWallets',
    r'\baddSumberDana\b': 'addWallet',
    r'\bdeleteSumberDana\b': 'deleteWallet',
    r'\btoggleArsipSumberDana\b': 'toggleArchiveWallet',
    r'\bidDana\b': 'walletId',
    r'\bidDanaTujuan\b': 'targetWalletId',
    r'\bnamaAset\b': 'walletName',
    r'\bsaldoAwal\b': 'initialBalance',
    r'\bsaldoTerkini\b': 'currentBalance',
}

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for pattern, repl in replacements.items():
        new_content = re.sub(pattern, repl, new_content)
        
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
