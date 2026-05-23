import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';
import 'package:aplikasi_keuangan/models/wallet_model.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';
import 'package:aplikasi_keuangan/core/utils/wallet_logo_resolver.dart';
import 'package:aplikasi_keuangan/shared/widgets/wallet_logo_widget.dart';

class AddWalletSheet {
  static void show(BuildContext context, FinanceProvider finance) {
    HapticFeedback.mediumImpact();
    String walletName = '';
    String balanceString = '';
    bool includeInTransaction = false; // Default: Exclude (tidak catat ke transaksi)

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: finance.themeBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: finance.themeBorder)),
              title: Text("Tambah Dompet", style: TextStyle(color: finance.themeText, fontSize: 20, fontWeight: FontWeight.w900)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("NAMA DOMPET", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _showWalletTemplateSheet(context, finance, (selectedName) {
                          setDialogState(() => walletName = selectedName);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: finance.themeCard,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            WalletLogoWidget(walletName: walletName.isEmpty ? 'NE' : walletName, size: 'sm'),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                walletName.isEmpty ? "Pilih atau Ketik Nama Dompet" : walletName,
                                style: TextStyle(color: walletName.isEmpty ? finance.themeTextSub.withValues(alpha: 0.5) : finance.themeText, fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                            Icon(Icons.keyboard_arrow_down_rounded, color: finance.themeTextSub, size: 20)
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text("SALDO AWAL", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    TextField(
                      onChanged: (val) => setDialogState(() => balanceString = val),
                      keyboardType: TextInputType.number,
                      inputFormatters: [CurrencyInputFormatter()],
                      style: TextStyle(color: finance.themeText, fontSize: 14, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        filled: true, fillColor: finance.themeCard,
                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 8),
                          child: Text(Formatters.activeCurrency.symbol, style: TextStyle(color: finance.themeText, fontSize: 14, fontWeight: FontWeight.bold)),
                        ),
                        hintText: "0",
                        hintStyle: TextStyle(color: finance.themeTextSub.withValues(alpha: 0.5)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Column(
                      children: [
                        // Card 1: Include (Count in wallet)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setDialogState(() => includeInTransaction = true);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: includeInTransaction ? finance.themeAccent.withValues(alpha: 0.05) : finance.themeCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: includeInTransaction ? finance.themeAccent : finance.themeBorder, width: includeInTransaction ? 1.5 : 1.0),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Catat ke Transaksi", style: TextStyle(color: includeInTransaction ? finance.themeAccent : finance.themeText, fontSize: 13, fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 4),
                                      Text("Saldo dicatat sebagai 'Pemasukan' dan masuk riwayat.", style: TextStyle(color: includeInTransaction ? finance.themeText : finance.themeTextSub, fontSize: 11, height: 1.4)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    color: includeInTransaction ? finance.themeAccent : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: includeInTransaction ? finance.themeAccent : finance.themeTextSub.withValues(alpha: 0.5), width: 1.5),
                                  ),
                                  child: includeInTransaction ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Card 2: Exclude (Don't count in wallet)
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setDialogState(() => includeInTransaction = false);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: !includeInTransaction ? finance.themeAccent.withValues(alpha: 0.05) : finance.themeCard,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: !includeInTransaction ? finance.themeAccent : finance.themeBorder, width: !includeInTransaction ? 1.5 : 1.0),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Hanya Saldo Dompet", style: TextStyle(color: !includeInTransaction ? finance.themeAccent : finance.themeText, fontSize: 13, fontWeight: FontWeight.w900)),
                                      const SizedBox(height: 4),
                                      Text("Hanya mengisi dompet tanpa menambah riwayat transaksi.", style: TextStyle(color: !includeInTransaction ? finance.themeText : finance.themeTextSub, fontSize: 11, height: 1.4)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    color: !includeInTransaction ? finance.themeAccent : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: !includeInTransaction ? finance.themeAccent : finance.themeTextSub.withValues(alpha: 0.5), width: 1.5),
                                  ),
                                  child: !includeInTransaction ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: finance.themeCard, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        child: Text("Batal", style: TextStyle(color: finance.themeText, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton(
                        onPressed: walletName.trim().isEmpty ? null : () {
                          HapticFeedback.heavyImpact();
                          final double initialBalance = double.tryParse(balanceString.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0.0;
                          final userId = finance.currentUser?.id ?? 'u1';
                          
                          final newWallet = WalletModel(
                            walletId: 'w_${DateTime.now().millisecondsSinceEpoch}',
                            walletName: walletName.trim(),
                            initialBalance: initialBalance,
                            currentBalance: initialBalance,
                            userId: userId,
                            isActive: true,
                          );
                          finance.addWallet(newWallet);
                          
                          if (includeInTransaction && initialBalance > 0) {
                            finance.handleSaveTransaksi(_createInitialTx(newWallet.walletId, initialBalance, userId));
                          }
                          
                          Navigator.pop(context);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16), 
                          backgroundColor: walletName.trim().isEmpty ? finance.themeBorder : finance.themeAccent, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                        ),
                        child: const Text("Simpan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                )
              ],
            );
          },
        );
      },
    );
  }

  // BottomSheet khusus untuk memilih template Dompet
  static void _showWalletTemplateSheet(BuildContext context, FinanceProvider finance, Function(String) onSelected) {
    String inputName = '';
    final controller = TextEditingController();
    final listTemplateBank = WalletLogoResolver.popularWallets; 

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(color: finance.themeBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), border: Border(top: BorderSide(color: finance.themeBorder))),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Pilih Template Dompet", style: TextStyle(color: finance.themeText, fontSize: 20, fontWeight: FontWeight.w900)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: finance.themeCard, shape: BoxShape.circle, border: Border.all(color: finance.themeBorder)), child: Icon(Icons.close_rounded, color: finance.themeTextSub, size: 20)),
                        )
                      ],
                    ),
                  ),
                  
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Text("NAMA DOMPET CUSTOM", style: TextStyle(color: finance.themeTextSub, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: finance.themeBorder)),
                            child: Row(
                              children: [
                                WalletLogoWidget(walletName: inputName.isEmpty ? 'NE' : inputName, size: 'sm'),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: controller,
                                    onChanged: (val) => setSheetState(() => inputName = val),
                                    style: TextStyle(color: finance.themeText, fontSize: 16, fontWeight: FontWeight.w900),
                                    decoration: InputDecoration(border: InputBorder.none, hintText: "cth: Celengan BCA", hintStyle: TextStyle(color: finance.themeTextSub.withValues(alpha:0.5), fontWeight: FontWeight.normal)),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),
                          Text("ATAU PILIH TEMPLATE CEPAT", style: TextStyle(color: finance.themeTextSub, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.0)),
                          const SizedBox(height: 16),

                          LayoutBuilder(builder: (context, constraints) {
                            int cols = (constraints.maxWidth / 80).floor();
                            if (cols < 3) cols = 3;
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: cols, childAspectRatio: 0.85, crossAxisSpacing: 12, mainAxisSpacing: 12),
                            itemCount: listTemplateBank.length,
                            itemBuilder: (context, index) {
                              final template = listTemplateBank[index];
                              final isSelected = inputName.toLowerCase() == template.toLowerCase();
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setSheetState(() { inputName = template; controller.text = template; });
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(color: isSelected ? finance.themeAccent.withValues(alpha:0.1) : finance.themeCard, borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? finance.themeAccent : finance.themeBorder)),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      WalletLogoWidget(walletName: template, size: 'sm'),
                                      const SizedBox(height: 10),
                                      Text(template, style: TextStyle(color: isSelected ? finance.themeAccent : finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.w900), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    ],
                                  ),
                                ),
                              );
                              },
                            );
                          }),
                          const SizedBox(height: 40), 
                        ],
                      ),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                    decoration: BoxDecoration(color: finance.themeBg, border: Border(top: BorderSide(color: finance.themeBorder))),
                    child: GestureDetector(
                      onTap: () {
                        if (inputName.isNotEmpty) {
                          onSelected(inputName);
                          Navigator.pop(context);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(color: inputName.isNotEmpty ? finance.themeAccent : finance.themeCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: inputName.isNotEmpty ? finance.themeAccent : finance.themeBorder)),
                        alignment: Alignment.center,
                        child: Text("Gunakan Nama Ini", style: TextStyle(color: inputName.isNotEmpty ? Colors.white : finance.themeTextSub, fontWeight: FontWeight.w900, fontSize: 16)),
                      ),
                    ),
                  )
                ],
              ),
              ),
            );
          }
        );
      }
    );
  }

  static TransactionModel _createInitialTx(String walletId, double nominal, String userId) {
    return TransactionModel(
      idTransaksi: 't_${DateTime.now().millisecondsSinceEpoch}',
      jenis: 'Pemasukan',
      nominal: nominal,
      walletId: walletId,
      kategori: 'Saldo Awal',
      keterangan: 'Pencatatan Saldo Awal',
      tanggal: DateTime.now().toIso8601String(),
      userId: userId,
    );
  }
}
