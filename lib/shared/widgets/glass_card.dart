// lib/shared/widgets/glass_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20), 
  });

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        // 🟢 FLAT DESIGN: Gak ada efek blur, gak ada efek gradient. Murni warna solid!
        decoration: BoxDecoration(
          color: finance.themeCard,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: finance.themeBorder,
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}