// lib/shared/widgets/custom_button.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aplikasi_keuangan/providers/finance_provider.dart';

enum ButtonVariant { primary, secondary, danger, outline }

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final EdgeInsetsGeometry? padding;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.fullWidth = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // 🟢 AUTO-SYNC: Ambil warna aksen dari provider
    final finance = Provider.of<FinanceProvider>(context);

    Color bgColor;
    Color textColor = Colors.white;
    List<BoxShadow>? shadows;
    Border? border;

    // Logic Variant Warna
    switch (variant) {
      case ButtonVariant.primary:
        // 🟢 KABEL DICOLOK: Warna tombol, bayangan glow, dan garis border ngikutin tema
        bgColor = finance.themeAccent; 
        shadows = [BoxShadow(color: finance.themeAccent.withValues(alpha:0.4), blurRadius: 20)];
        border = Border.all(color: finance.themeAccent.withValues(alpha:0.5));
        break;
      case ButtonVariant.danger:
        bgColor = Colors.pink.shade500;
        shadows = [BoxShadow(color: Colors.pink.withValues(alpha:0.4), blurRadius: 20)];
        border = Border.all(color: Colors.pink.withValues(alpha:0.5));
        break;
      case ButtonVariant.outline:
        bgColor = Colors.transparent;
        textColor = Colors.white70;
        border = Border.all(color: Colors.white10, width: 2);
        break;
      case ButtonVariant.secondary:
        bgColor = Colors.white.withValues(alpha:0.1);
        border = Border.all(color: Colors.white10);
        break;
    }

    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: padding ?? const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: border,
          boxShadow: shadows,
        ),
        child: Row(
          mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            else if (icon != null) ...[
              Icon(icon, color: textColor, size: 20),
              const SizedBox(width: 8),
            ],
            if (!isLoading)
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ),
    );
  }
}