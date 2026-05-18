// lib/shared/widgets/custom_badge.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_keuangan/providers/finance_provider.dart';

enum BadgeVariant { primary, success, danger, warning, info, defaultBadge }

class CustomBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final BadgeVariant variant;

  const CustomBadge({
    super.key,
    required this.text,
    this.icon,
    this.variant = BadgeVariant.defaultBadge,
  });

  @override
  Widget build(BuildContext context) {
    // 🟢 AUTO-SYNC: Ambil warna aksen dari provider
    final finance = Provider.of<FinanceProvider>(context);

    Color bgColor;
    Color textColor;

    switch (variant) {
      case BadgeVariant.primary:
        // 🟢 KABEL DICOLOK: Badge primary pakai warna aksen dinamis
        bgColor = finance.themeAccent.withValues(alpha:0.1);
        textColor = finance.themeAccent;
        break;
      case BadgeVariant.success:
        bgColor = Colors.green.withValues(alpha:0.1);
        textColor = Colors.greenAccent;
        break;
      case BadgeVariant.danger:
        bgColor = Colors.pink.withValues(alpha:0.1);
        textColor = Colors.pinkAccent;
        break;
      default:
        bgColor = Colors.white.withValues(alpha:0.05);
        textColor = Colors.white70;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha:0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}