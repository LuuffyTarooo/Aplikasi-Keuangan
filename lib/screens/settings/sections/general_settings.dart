// lib/screens/settings/sections/general_settings.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/screens/settings/widgets/setting_ui.dart';
// 🟢 FIX: Jalur import disesuaikan sama letak file yang bener
import 'package:aplikasi_keuangan/core/theme/theme_customizer_sheet.dart';
import 'package:aplikasi_keuangan/screens/manage_category_screen.dart'; 
import 'package:aplikasi_keuangan/shared/bottom_sheets/currency_selector_sheet.dart';

class GeneralSettings extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const GeneralSettings({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  State<GeneralSettings> createState() => _GeneralSettingsState();
}

class _GeneralSettingsState extends State<GeneralSettings> {
  @override
  Widget build(BuildContext context) {
    // 🟢 AUTO-SYNC: Ambil data tema dari provider
    final finance = Provider.of<FinanceProvider>(context);

    return SettingsGroup(
      title: "General",
      children: [
        // Notifikasi
        SettingsItem(
          icon: Icons.notifications_rounded,
          title: "Notifikasi",
          trailing: Switch(
            value: finance.isNotificationEnabled,
            onChanged: (val) {
              HapticFeedback.lightImpact();
              finance.toggleNotification(val);
            },
            // 🟢 FIX: Pake WidgetStatePropertyAll biar ga muncul Warning di VS Code
            thumbColor: WidgetStatePropertyAll(finance.themeAccent), 
            activeTrackColor: finance.themeAccent.withValues(alpha: 0.3),
            inactiveThumbColor: finance.themeTextSub,
            inactiveTrackColor: finance.themeBorder,
          ),
        ),

        // Kustomisasi Tampilan
        SettingsItem(
          icon: Icons.palette_rounded,
          title: "Kustomisasi Tampilan",
          trailing: Icon(Icons.color_lens_rounded, color: finance.themeTextSub, size: 18), // 🟢 AUTO-SYNC
          onTap: () {
            HapticFeedback.mediumImpact();
            // Manggil bottom sheet buat milih warna aksen & dark/light mode
            ThemeCustomizerSheet.show(context);
          },
        ),

        // Bahasa
        SettingsItem(
          icon: Icons.language_rounded,
          title: "Bahasa",
          trailing: Text("Indonesia", style: TextStyle(color: finance.themeTextSub, fontSize: 12, fontWeight: FontWeight.bold)), // 🟢 AUTO-SYNC
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Fitur ganti bahasa segera hadir!", style: TextStyle(color: finance.themeText, fontWeight: FontWeight.bold)),
                backgroundColor: finance.themeCard,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: finance.themeBorder)),
              ),
            );
          },
        ),

        // Manajemen Kategori
        SettingsItem(
          icon: Icons.category_rounded,
          title: "Manajemen Kategori",
          trailing: Icon(Icons.chevron_right_rounded, color: finance.themeTextSub, size: 18),
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ManageCategoryScreen()),
            );
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
              finance.currentCurrency.code,
              style: TextStyle(color: finance.themeAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5), 
            ),
          ),
          onTap: () {
            HapticFeedback.mediumImpact();
            CurrencySelectorSheet.show(context);
          },
        ),
      ],
    );
  }
}