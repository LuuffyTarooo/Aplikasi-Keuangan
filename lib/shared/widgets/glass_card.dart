// lib/shared/widgets/glass_card.dart
import 'dart:ui';
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
    this.padding = const EdgeInsets.all(20), // md default
  });

  @override
  Widget build(BuildContext context) {
    // 🟢 AUTO-SYNC: Panggil provider buat ngambil warna Card dari tema aktif!
    final finance = Provider.of<FinanceProvider>(context);

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              // 🟢 KABEL DICOLOK: Warna sekarang dinamis ngikutin settingan kustomisasi
              color: finance.themeCard,
              border: Border.all(
                color: Colors.white.withValues(alpha:0.1),
                width: 1,
              ),
              // Efek glossy tipis tetap kita pertahankan biar mevvah
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha:0.1),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.05],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}