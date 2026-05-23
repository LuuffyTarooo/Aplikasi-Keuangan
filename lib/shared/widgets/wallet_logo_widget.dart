// lib/shared/widgets/wallet_logo_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aplikasi_keuangan/core/utils/wallet_logo_resolver.dart';

class WalletLogoWidget extends StatelessWidget {
  final String? walletName;
  final String size;

  const WalletLogoWidget({
    super.key,
    required this.walletName,
    this.size = 'md',
  });

  @override
  Widget build(BuildContext context) {
    final name = (walletName ?? '').toLowerCase();
    
    final double boxSize = size == 'sm' ? 32.0 : 46.0;
    final double radius = size == 'sm' ? 10.0 : 14.0;

    Widget buildBox(Color bgColor, Widget child) {
      return Container(
        width: boxSize,
        height: boxSize,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        alignment: Alignment.center,
        child: child,
      );
    }

    // Cash variants
    if (name.contains('tunai') || name.contains('cash')) {
      return buildBox(
        Colors.green.shade600, 
        const Text('Rp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))
      );
    }

    final svgFile = WalletLogoResolver.resolveLogoPath(walletName);

    if (svgFile != null) {
      return SizedBox(
        width: boxSize,
        height: boxSize,
        child: SvgPicture.asset(
          'assets/icons/banks/$svgFile',
          width: boxSize,
          height: boxSize,
          fit: BoxFit.contain,
        ),
      );
    }

    if (name.contains('bri') || name.contains('rakyat')) {
      return buildBox(
        const Color(0xFF0B5C9F), 
        const Text('BRI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))
      );
    }

    // Initials fallback
    String initials = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
    if (initials.isEmpty) initials = 'NE';
    
    return buildBox(
      const Color(0xFF24292E), 
      Text(initials, style: const TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.0)),
    );
  }
}
