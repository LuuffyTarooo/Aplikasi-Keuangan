// lib/core/utils/wallet_helper.dart
import 'package:flutter/material.dart';

class WalletHelper {
  // LIST MASTER DATA TEMPLATE WALLET
  static const List<String> popularWallets = [
    'BCA', 'Mandiri', 'BRI', 'BNI', 'BTN', 'CIMB', 'Danamon', 'Permata', 'Panin', 'Mega', 'Sinarmas', 'OCBC', 'Maybank',
    'Jago', 'blu', 'SeaBank', 'Neo', 'LINE', 'Allo', 'Saqu',
    'GoPay', 'OVO', 'DANA', 'ShopeePay', 'LinkAja', 'Tunai'
  ];

  static Widget getWalletLogo(String? namaWallet, {String size = 'md'}) {
    final name = (namaWallet ?? '').toLowerCase();
    
    // Ukuran kotak dinamis
    final double boxSize = size == 'sm' ? 32.0 : 46.0;
    final double radius = size == 'sm' ? 10.0 : 14.0;

    // 🟢 CETAKAN BASE KOTAK LOGO (PURE CODE STYLING)
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
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: child,
          ),
        ),
      );
    }

    // ==========================================
    // 🏦 BAN-BANK DI INDONESIA (Plek Ketiplek Sesuai List Lu)
    // ==========================================
    if (name.contains('bri') || name.contains('rakyat')) {
      return buildBox(const Color(0xFF0B5C9F), const Text('BRI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)));
    }
    if (name.contains('mandiri')) {
      return buildBox(
        const Color(0xFF0A3967),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('mandiri', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic, fontSize: 12, height: 1.0)),
            Container(width: 24, height: 1.5, margin: const EdgeInsets.only(top: 2), color: const Color(0xFFF2C144)),
          ],
        ),
      );
    }
    if (name.contains('bni')) {
      return buildBox(
        const Color(0xFF006885),
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('BNI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
            Text('46', style: TextStyle(color: Color(0xFFF15A23), fontWeight: FontWeight.w900, fontSize: 14)),
          ],
        ),
      );
    }
    if (name.contains('btn')) {
      return buildBox(
        const Color(0xFF0054A6),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('BTN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, height: 1.0)),
            Container(width: 18, height: 2, margin: const EdgeInsets.only(top: 2), color: const Color(0xFFFEE100)),
          ],
        ),
      );
    }
    if (name.contains('bca')) {
      return buildBox(const Color(0xFF0066AE), const Text('BCA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, fontStyle: FontStyle.italic)));
    }
    if (name.contains('cimb') || name.contains('niaga')) {
      return buildBox(const Color(0xFFE3000F), const Text('CIMB', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)));
    }
    if (name.contains('danamon')) {
      return buildBox(const Color(0xFFEA5B0C), const Text('Danamon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)));
    }
    if (name.contains('permata')) {
      return buildBox(const Color(0xFF008680), const Text('Permata', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)));
    }
    if (name.contains('panin')) {
      return buildBox(const Color(0xFF005E9E), const Text('Panin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)));
    }
    if (name.contains('mega')) {
      return buildBox(const Color(0xFFFFC000), const Text('MEGA', style: TextStyle(color: Color(0xFF003D79), fontWeight: FontWeight.w900, fontSize: 13)));
    }
    if (name.contains('sinarmas')) {
      return buildBox(const Color(0xFFE31837), const Text('sinarmas', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)));
    }
    if (name.contains('ocbc')) {
      return buildBox(const Color(0xFFE1251B), const Text('OCBC', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)));
    }
    if (name.contains('maybank')) {
      return buildBox(const Color(0xFFFFD100), const Text('Maybank', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 11)));
    }

    // ==========================================
    // 📱 ALL DIGITAL BANKS
    // ==========================================
    if (name.contains('jago')) {
      return buildBox(const Color(0xFFF48120), const Text('jago', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)));
    }
    if (name.contains('blu')) {
      return buildBox(const Color(0xFF00AEEF), const Text('blu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)));
    }
    if (name.contains('sea')) {
      return buildBox(const Color(0xFFFF7300), const Text('SeaBank', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)));
    }
    if (name.contains('neo')) {
      return buildBox(const Color(0xFF111111), const Text('neo', style: TextStyle(color: Color(0xFF00E5FF), fontWeight: FontWeight.w900, fontSize: 15)));
    }
    if (name.contains('line')) {
      return buildBox(const Color(0xFF00C300), const Text('LINE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)));
    }
    if (name.contains('allo')) {
      return buildBox(const Color(0xFF7C3AED), const Text('Allo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)));
    }
    if (name.contains('saqu')) {
      return buildBox(const Color(0xFFE1146B), const Text('Saqu', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)));
    }

    // ==========================================
    // 💳 ALL E-WALLETS
    // ==========================================
    if (name.contains('gopay')) {
      return buildBox(const Color(0xFF00AED6), const Text('gopay', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)));
    }
    if (name.contains('ovo')) {
      return buildBox(const Color(0xFF4C3494), const Text('OVO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontStyle: FontStyle.italic, fontSize: 15)));
    }
    if (name.contains('dana')) {
      return buildBox(const Color(0xFF118EEA), const Text('DANA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)));
    }
    if (name.contains('shopee') || name.contains('spay')) {
      return buildBox(
        const Color(0xFFEE4D2D),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)),
          child: const Text('S', style: TextStyle(color: Color(0xFFEE4D2D), fontWeight: FontWeight.w900, fontSize: 13)),
        ),
      );
    }
    if (name.contains('linkaja')) {
      return buildBox(const Color(0xFFE3000F), const Text('LinkAja', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)));
    }

    // ==========================================
    // 💰 CASH / CASH TUNAI / CUSTOM FALLBACK
    // ==========================================
    if (name.contains('tunai') || name.contains('cash')) {
      return buildBox(Colors.green.shade600, const Text('Rp', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)));
    }

    // Jika user ketik nama dompet sendiri (misal: "Uang Jajan Jar")
    String singkatan = name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase();
    return buildBox(
      const Color(0xFF24292E), 
      Text(singkatan, style: const TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1.0)),
    );
  }
}