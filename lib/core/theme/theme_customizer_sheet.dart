// lib/screens/settings/sheets/theme_customizer_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; 

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

  void _openColorPicker(BuildContext context, {required String title, required Color currentColor, required ValueChanged<Color> onColorChanged}) {
    HapticFeedback.mediumImpact();
    Color pickerColor = currentColor; 

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.white10)),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            colorPickerWidth: 300,
            pickerAreaHeightPercent: 0.7,
            enableAlpha: false,
            displayThumbColor: true,
            paletteType: PaletteType.hsvWithHue,
            pickerAreaBorderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00AA5B), foregroundColor: Colors.white),
            onPressed: () {
              HapticFeedback.heavyImpact();
              onColorChanged(pickerColor); 
              Navigator.pop(context);
            },
            child: const Text("Terapkan", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: finance.themeBg, 
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
              Text("Kustomisasi Tema", style: TextStyle(color: finance.themeText, fontSize: 18, fontWeight: FontWeight.w900)),
              GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: finance.themeCard, shape: BoxShape.circle), child: Icon(Icons.close_rounded, color: finance.themeTextSub, size: 20)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // 🟢 1. SAKLAR MODE GELAP / TERANG
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: finance.themeBorder)),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(finance.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded, color: finance.themeAccent),
              title: Text("Mode Gelap (Dark Mode)", style: TextStyle(color: finance.themeText, fontWeight: FontWeight.bold)),
              trailing: Switch(
                value: finance.isDarkMode,
                thumbColor: WidgetStatePropertyAll(finance.themeAccent), // Fix warning VS Code
                activeTrackColor: finance.themeAccent.withValues(alpha: 0.3),
                inactiveThumbColor: finance.themeTextSub,
                inactiveTrackColor: finance.themeBorder,
                onChanged: (val) {
                  HapticFeedback.lightImpact();
                  finance.toggleTheme(val); 
                },
              ),
            ),
          ),
          
          const SizedBox(height: 16),

          // 🟢 2. PEMILIH WARNA AKSEN (TOMBOL & ICON)
          GestureDetector(
            onTap: () => _openColorPicker(
              context, title: "Warna Aksen", currentColor: finance.themeAccent, 
              onColorChanged: (color) => finance.updateThemeAccent(color)
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: finance.themeBorder)),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(color: finance.themeAccent, shape: BoxShape.circle, border: Border.all(color: finance.themeBorder)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Warna Aksen (Tombol & Icon)", style: TextStyle(color: finance.themeText, fontSize: 14, fontWeight: FontWeight.bold)),
                        Text("Sentuh untuk mengubah warna.", style: TextStyle(color: finance.themeTextSub, fontSize: 10)),
                      ],
                    ),
                  ),
                  Icon(Icons.color_lens_rounded, color: finance.themeTextSub),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}