// lib/screens/settings/widgets/setting_ui.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';

class SettingsGroup extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const SettingsGroup({super.key, required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    // 🟢 Panggil provider tema buat widget grup
    final finance = Provider.of<FinanceProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8, top: 16),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: finance.themeCard, // 🟢 Flat Design solid
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: finance.themeBorder),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const SettingsItem({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 🟢 Panggil provider tema buat item baris
    final finance = Provider.of<FinanceProvider>(context);

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: finance.themeBg, // 🟢 Kotak ikon ngikutin background biar kontras
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: finance.themeBorder)
        ),
        child: Icon(icon, color: finance.themeTextSub, size: 20),
      ),
      title: Text(title, style: TextStyle(color: finance.themeText, fontSize: 14, fontWeight: FontWeight.bold)),
      trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, color: finance.themeTextSub.withValues(alpha: 0.5), size: 14),
    );
  }
}