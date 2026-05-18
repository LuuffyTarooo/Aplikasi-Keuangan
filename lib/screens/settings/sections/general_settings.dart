// lib/screens/settings/sections/general_settings.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/screens/settings/widgets/setting_ui.dart';
import 'package:aplikasi_keuangan/core/theme/theme_customizer_sheet.dart'; // 🟢 IMPORT SHEET KUSTOMISASI

class GeneralSettings extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final String mataUang;
  final VoidCallback onOpenCurrencyModal;

  const GeneralSettings({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.mataUang,
    required this.onOpenCurrencyModal,
  });

  @override
  State<GeneralSettings> createState() => _GeneralSettingsState();
}

class _GeneralSettingsState extends State<GeneralSettings> {
  bool _notifications = true;

  @override
  Widget build(BuildContext context) {
    // 🟢 Ambil data tema dari provider
    final finance = Provider.of<FinanceProvider>(context);

    return SettingsGroup(
      title: "General",
      children: [
        // Notifikasi
        SettingsItem(
          icon: Icons.notifications_rounded,
          title: "Notifikasi",
          trailing: Switch(
            value: _notifications,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              setState(() => _notifications = val);
            },
            // 🟢 Warna switch sekarang dinamis ngikutin aksen!
            activeThumbColor: finance.themeAccent, 
            activeTrackColor: finance.themeAccent.withValues(alpha: 0.5),
            inactiveTrackColor: Colors.white10,
          ),
        ),

        // 🟢 INI DIA TOMBOL BARUNYA JAR: KUSTOMISASI TAMPILAN
        SettingsItem(
          icon: Icons.palette_rounded,
          title: "Kustomisasi Tampilan",
          trailing: const Icon(Icons.color_lens_rounded, color: Colors.white54, size: 18),
          onTap: () {
            HapticFeedback.mediumImpact();
            // Manggil bottom sheet buat milih warna
            ThemeCustomizerSheet.show(context);
          },
        ),

        // Bahasa
        SettingsItem(
          icon: Icons.language_rounded,
          title: "Bahasa",
          trailing: const Text("Indonesia", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fitur ganti bahasa segera hadir!")));
          },
        ),

        // Mata Uang
        SettingsItem(
          icon: Icons.attach_money_rounded,
          title: "Mata Uang Utama",
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: finance.themeAccent.withValues(alpha: 0.1),
              border: Border.all(color: finance.themeAccent.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.mataUang,
              // 🟢 Warna teks mata uang juga ngikutin aksen!
              style: TextStyle(color: finance.themeAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
          ),
          onTap: widget.onOpenCurrencyModal,
        ),
      ],
    );
  }
}