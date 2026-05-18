// lib/shared/sheets/base_sheet.dart
import 'package:flutter/material.dart';

class BaseSheet {
  BaseSheet._();

  /// Fungsi global buat nampilin Bottom Sheet dengan gaya Glassmorphism seragam
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: isScrollControlled,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0F1A).withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white10),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          top: 16,
          left: 16,
          right: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle Bar atas modal
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            
            // Konten dinamis yang diisi dari file lain
            child,
          ],
        ),
      ),
    );
  }
}