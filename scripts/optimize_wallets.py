import os
import re

def optimize_manage_wallets():
    filepath = r'C:\Users\fajar\aplikasi_keuangan\lib\screens\dashboard\wallets\manage_wallets_screen.dart'
    if not os.path.exists(filepath): return
    
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Remove _getTransactionCount
    content = re.sub(r'  // Fungsi Helper Menghitung Jumlah Transaksi di suatu Dompet\s*int _getTransactionCount.*?\s*return .*?\s*\}', '', content, flags=re.DOTALL)
    
    # 2. Add O(N+M) calculation inside build
    old_build_start = """  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);

    // Pisahin dompet aktif & non-aktif
    List<WalletModel> activeWallets = finance.myWallets.where((w) => w.isActive).toList();
    List<WalletModel> archivedWallets = finance.myWallets.where((w) => !w.isActive).toList();"""
    
    new_build_start = """  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);

    // Optimasi: Hitung jumlah transaksi O(N+M) alih-alih memfilter list per dompet
    final Map<String, int> txCountByWallet = {};
    for (var tx in finance.myTransaksi) {
      txCountByWallet[tx.walletId] = (txCountByWallet[tx.walletId] ?? 0) + 1;
      if (tx.targetWalletId != null) {
        txCountByWallet[tx.targetWalletId!] = (txCountByWallet[tx.targetWalletId!] ?? 0) + 1;
      }
    }

    // Pisahin dompet aktif & non-aktif
    List<WalletModel> activeWallets = finance.myWallets.where((w) => w.isActive).toList();
    List<WalletModel> archivedWallets = finance.myWallets.where((w) => !w.isActive).toList();"""

    content = content.replace(old_build_start, new_build_start)

    # 3. Replace mapping with ListView.builder for active wallets
    old_active_map = """                  ...activeWallets.map((w) {
                    int txCount = _getTransactionCount(w.walletId, finance);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container("""
                      
    new_active_map = """                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: activeWallets.length,
                    itemBuilder: (context, index) {
                      final w = activeWallets[index];
                      int txCount = txCountByWallet[w.walletId] ?? 0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container("""

    content = content.replace(old_active_map, new_active_map)
    
    # Close the active listview builder
    old_active_close = """                        ),
                      ),
                    );
                  }),"""
    new_active_close = """                        ),
                      ),
                    );
                  },
                  ),"""
    content = content.replace(old_active_close, new_active_close)
    
    # 4. Replace mapping with ListView.builder for archived wallets
    old_archived_map = """                    ...archivedWallets.map((w) {
                      int txCount = _getTransactionCount(w.walletId, finance);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Opacity("""
                        
    new_archived_map = """                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: archivedWallets.length,
                      itemBuilder: (context, index) {
                        final w = archivedWallets[index];
                        int txCount = txCountByWallet[w.walletId] ?? 0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Opacity("""

    content = content.replace(old_archived_map, new_archived_map)
    
    old_archived_close = """                              ),
                            ),
                          ),
                        );
                      }),"""
                      
    new_archived_close = """                              ),
                            ),
                          ),
                        );
                      },
                    ),"""
    
    content = content.replace(old_archived_close, new_archived_close)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Optimized manage_wallets_screen.dart")

if __name__ == '__main__':
    optimize_manage_wallets()
