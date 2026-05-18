// lib/screens/settings/settings_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 🚀 IMPORT COMPONENT SECTION & WIDGET KITA
import 'package:aplikasi_keuangan/screens/settings/sections/general_settings.dart';
import 'package:aplikasi_keuangan/screens/settings/sections/help_support_section.dart';
import 'package:aplikasi_keuangan/screens/settings/sections/security_section.dart'; 
import 'package:aplikasi_keuangan/screens/settings/widgets/setting_ui.dart'; 
import 'package:aplikasi_keuangan/screens/settings/sections/data_storage_section.dart'; 

class SettingsScreen extends StatefulWidget {
  final Function(dynamic)? onNavigate; // 🟢 1. Tambahin callback biar bisa pindah tab secara safe

  const SettingsScreen({super.key, this.onNavigate});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = true;
  String _mataUang = 'IDR';
  
  final String _appPin = "1234"; 

  void _openAboutModal() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.white10)),
        title: const Text("Duit Tracker v1.0.0", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: const Text("Dibuat dengan 🔥 oleh lu buat ngatur duit biar makin jago!", style: TextStyle(color: Colors.white54, fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Beres", style: TextStyle(color: Color(0xFFD946EF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openPinModal() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.white10)),
        title: const Text("Keamanan PIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: const Text("Modal dialog konfigurasi PIN atau PinManagerDialog lu bakal dipanggil di sini Jar.", style: TextStyle(color: Colors.white54, fontSize: 12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xFFD946EF), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _openCurrencyModal() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Color(0xFF161B22), borderRadius: BorderRadius.vertical(top: Radius.circular(32)), border: Border(top: BorderSide(color: Colors.white10))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Pilih Mata Uang", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 16),
            ListTile(
              title: const Text("Rupiah (IDR)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: _mataUang == 'IDR' ? const Icon(Icons.check_circle_rounded, color: Color(0xFFD946EF)) : null,
              onTap: () { setState(() => _mataUang = 'IDR'); Navigator.pop(context); },
            ),
            ListTile(
              title: const Text("US Dollar (USD)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: _mataUang == 'USD' ? const Icon(Icons.check_circle_rounded, color: Color(0xFFD946EF)) : null,
              onTap: () { setState(() => _mataUang = 'USD'); Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF05010D),
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
                      // 🟢 2. VAKSIN ANTI LAYAR PUTIH: Cek kondisi tumpukan navigasi stack
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context); // Kalau dia halaman terpisah, pop biasa
                      } else {
                        widget.onNavigate?.call(0); // Kalau dia bertindak sebagai tab, lempar balik ke Dashboard (Index 0)
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Pengaturan", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                      Text("KUSTOMISASI & BANTUAN", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
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
                      onOpenCurrencyModal: _openCurrencyModal,
                    ),
                    const SizedBox(height: 16),

                    // 2. Security Section
                    SecuritySection(
                      appPin: _appPin,
                      onOpenPinModal: _openPinModal,
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
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white30, size: 14),
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
                      onOpenAboutModal: _openAboutModal,
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