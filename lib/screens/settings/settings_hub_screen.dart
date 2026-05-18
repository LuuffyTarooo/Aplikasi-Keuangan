// lib/screens/settings/settings_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🟢 FIX: Import SharedPreferences

// 🚀 IMPORT COMPONENT SECTION & WIDGET KITA
import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/screens/settings/sections/general_settings.dart';
import 'package:aplikasi_keuangan/screens/settings/sections/help_support_section.dart';
import 'package:aplikasi_keuangan/screens/settings/sections/security_section.dart'; 
import 'package:aplikasi_keuangan/screens/settings/widgets/setting_ui.dart'; 
import 'package:aplikasi_keuangan/screens/settings/sections/data_storage_section.dart'; 
import 'package:aplikasi_keuangan/screens/settings/dialogs/pin_manager_dialog.dart';

class SettingsScreen extends StatefulWidget {
  final Function(dynamic)? onNavigate; 

  const SettingsScreen({super.key, this.onNavigate});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = true;
  String _mataUang = 'IDR';
  String _appPin = ""; 

  @override
  void initState() {
    super.initState();
    _loadSettings(); // 🟢 Manggil data permanen pas halaman dibuka
  }

  // 🟢 FUNGSI LOAD DATA PERMANEN
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _appPin = prefs.getString('app_pin') ?? "";
      _mataUang = prefs.getString('app_currency') ?? "IDR";
      // Note: Dark mode udah otomatis diurus di FinanceProvider lu
    });
  }

  void _openAboutModal(FinanceProvider finance) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: finance.themeBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: finance.themeBorder)),
        title: Text("Duit Tracker v1.0.0", style: TextStyle(color: finance.themeText, fontWeight: FontWeight.w900)),
        content: Text("Dibuat dengan 🔥 oleh lu buat ngatur duit biar makin jago!", style: TextStyle(color: finance.themeTextSub, fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Beres", style: TextStyle(color: finance.themeAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openPinModal(FinanceProvider finance) {
    HapticFeedback.mediumImpact();
    
    PinManagerScreen.show(context, _appPin, (newPin) async {
      setState(() {
        _appPin = newPin ?? ""; 
      });
      
      // 🟢 FUNGSI SAVE PIN PERMANEN
      final prefs = await SharedPreferences.getInstance();
      if (newPin == null || newPin.isEmpty) {
        await prefs.remove('app_pin'); // Dihapus kalau dinonaktifkan
      } else {
        await prefs.setString('app_pin', newPin); // Disimpan
      }
    });
  }

  void _openCurrencyModal(FinanceProvider finance) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: finance.themeBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), border: Border(top: BorderSide(color: finance.themeBorder))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Pilih Mata Uang", style: TextStyle(color: finance.themeText, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            ListTile(
              title: Text("Rupiah (IDR)", style: TextStyle(color: finance.themeText, fontWeight: FontWeight.bold)),
              trailing: _mataUang == 'IDR' ? Icon(Icons.check_circle_rounded, color: finance.themeAccent) : null,
              onTap: () async { 
                setState(() => _mataUang = 'IDR'); 
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('app_currency', 'IDR'); // 🟢 Save Permanen
                if (context.mounted) Navigator.pop(context); 
              },
            ),
            ListTile(
              title: Text("US Dollar (USD)", style: TextStyle(color: finance.themeText, fontWeight: FontWeight.bold)),
              trailing: _mataUang == 'USD' ? Icon(Icons.check_circle_rounded, color: finance.themeAccent) : null,
              onTap: () async { 
                setState(() => _mataUang = 'USD'); 
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('app_currency', 'USD'); // 🟢 Save Permanen
                if (context.mounted) Navigator.pop(context); 
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);

    return Scaffold(
      backgroundColor: finance.themeBg, 
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () { 
                      HapticFeedback.lightImpact(); 
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context); 
                      } else {
                        widget.onNavigate?.call(0); 
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: finance.themeCard, shape: BoxShape.circle, border: Border.all(color: finance.themeBorder)),
                      child: Icon(Icons.arrow_back_ios_new_rounded, color: finance.themeTextSub, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Pengaturan", style: TextStyle(color: finance.themeText, fontSize: 24, fontWeight: FontWeight.w900)),
                      Text("KUSTOMISASI & BANTUAN", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ],
                  ),
                ],
              ),
            ),

            // Main Settings Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // 1. General Section
                    GeneralSettings(
                      isDarkMode: _isDarkMode,
                      mataUang: _mataUang,
                      onThemeChanged: (val) => setState(() => _isDarkMode = val),
                      onOpenCurrencyModal: () => _openCurrencyModal(finance),
                    ),
                    const SizedBox(height: 16),

                    // 2. Security Section
                    SecuritySection(
                      appPin: _appPin,
                      onOpenPinModal: () => _openPinModal(finance),
                      setUseBiometric: (_) {}, 
                    ),
                    const SizedBox(height: 16),

                    // 3. Data & Storage Section (Penyimpanan)
                    SettingsGroup(
                      title: "Penyimpanan", 
                      children: [
                        SettingsItem(
                          icon: Icons.storage_rounded,
                          title: "Kelola Data & Storage",
                          trailing: Icon(Icons.arrow_forward_ios_rounded, color: finance.themeTextSub, size: 14),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            DataStorageSheet.show(context); 
                          },
                        )
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 4. Help & Support Section
                    HelpSupportSection(
                      onOpenAboutModal: () => _openAboutModal(finance),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}