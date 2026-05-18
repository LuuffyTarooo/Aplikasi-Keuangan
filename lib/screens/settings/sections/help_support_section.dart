// lib/screens/settings/sections/help_support_section.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aplikasi_keuangan/screens/settings/widgets/setting_ui.dart';

class HelpSupportSection extends StatelessWidget {
  final VoidCallback onOpenAboutModal;

  const HelpSupportSection({super.key, required this.onOpenAboutModal});

  @override
  Widget build(BuildContext context) {
    return SettingsGroup(
      title: "Help & Support",
      children: [
        // Saran & Rating
        SettingsItem(
          icon: Icons.star_rounded,
          title: "Saran & Rating",
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Membuka Email Support...")));
          },
        ),

        // Hubungi Support
        SettingsItem(
          icon: Icons.help_outline_rounded,
          title: "Hubungi Support",
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Membuka WhatsApp Support...")));
          },
        ),

        // Panduan Penggunaan
        SettingsItem(
          icon: Icons.book_rounded,
          title: "Panduan Penggunaan",
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Halaman panduan sedang disusun!")));
          },
        ),

        // Tentang Aplikasi
        SettingsItem(
          icon: Icons.info_outline_rounded,
          title: "Tentang Aplikasi",
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF9333EA).withValues(alpha: 0.1),
              border: Border.all(color: const Color(0xFF9333EA).withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "V1.0.0",
              style: TextStyle(color: Color(0xFFA855F7), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5),
            ),
          ),
          onTap: onOpenAboutModal,
        ),
      ],
    );
  }
}