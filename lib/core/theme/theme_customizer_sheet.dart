// lib/screens/settings/sheets/theme_customizer_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_keuangan/providers/finance_provider.dart';

class ThemeCustomizerSheet {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const _ThemeCustomizerContent(),
    );
  }
}

class _ThemeCustomizerContent extends StatelessWidget {
  const _ThemeCustomizerContent();

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: finance.themeBg, // 🟢 Pakai warna latar solid
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: finance.themeBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Tampilan Aplikasi", style: TextStyle(color: finance.themeText, fontSize: 18, fontWeight: FontWeight.w900)),
              GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: finance.themeCard, shape: BoxShape.circle), child: Icon(Icons.close_rounded, color: finance.themeTextSub, size: 20)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // 🟢 SAKLAR MODE GELAP / TERANG
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: finance.themeCard,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: finance.themeBorder),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(finance.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: finance.themeAccent),
              title: Text("Mode Gelap (Dark Mode)", style: TextStyle(color: finance.themeText, fontWeight: FontWeight.bold)),
              trailing: Switch(
                value: finance.isDarkMode,
                activeColor: finance.themeAccent,
                activeTrackColor: finance.themeAccent.withValues(alpha: 0.3),
                inactiveThumbColor: finance.themeTextSub,
                inactiveTrackColor: finance.themeBorder,
                onChanged: (val) {
                  HapticFeedback.lightImpact();
                  finance.toggleTheme(val); // 🟢 Manggil fungsi baru kita
                },
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}