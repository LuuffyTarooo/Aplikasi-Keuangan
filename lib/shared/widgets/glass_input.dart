// lib/shared/widgets/glass_input.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_keuangan/providers/finance_provider.dart';

class GlassInput extends StatelessWidget {
  final String? label;
  final String hintText;
  final IconData? icon;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? errorText;

  const GlassInput({
    super.key,
    this.label,
    required this.hintText,
    this.icon,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    // 🟢 AUTO-SYNC: Ambil warna aksen dari provider
    final finance = Provider.of<FinanceProvider>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: 6),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: const TextStyle(color: Colors.white30),
                errorText: errorText,
                filled: true,
                fillColor: Colors.white.withValues(alpha:0.05),
                prefixIcon: icon != null ? Icon(icon, color: Colors.white54, size: 20) : null,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha:0.1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  // 🟢 KABEL DICOLOK: Glow input box ngikutin aksen
                  borderSide: BorderSide(color: finance.themeAccent, width: 1.5), 
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.pink.shade500),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}