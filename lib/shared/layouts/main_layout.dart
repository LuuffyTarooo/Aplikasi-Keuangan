// lib/shared/layouts/main_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onNavigate;
  final VoidCallback onQuickAdd;
  final VoidCallback? onVoiceAdd;
  final bool isVoiceActive;

  const MainLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onNavigate,
    required this.onQuickAdd,
    this.onVoiceAdd,
    this.isVoiceActive = false,
  });

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isLongPressing = false;
  bool _isHoveringMic = false;
  double _touchStartY = 0;

  void _handlePanStart(DragStartDetails details) {
    _touchStartY = details.globalPosition.dy;
    setState(() {
      _isLongPressing = true;
    });
    HapticFeedback.mediumImpact();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (!_isLongPressing) return;
    // Kalau ditarik ke atas lebih dari 60px
    if (_touchStartY - details.globalPosition.dy > 60) {
      if (!_isHoveringMic) {
        setState(() => _isHoveringMic = true);
        HapticFeedback.lightImpact(); // Getar pas kena mic
      }
    } else {
      if (_isHoveringMic) setState(() => _isHoveringMic = false);
    }
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_isLongPressing) {
      if (_isHoveringMic && widget.onVoiceAdd != null) {
        HapticFeedback.heavyImpact();
        widget.onVoiceAdd!();
      }
      setState(() {
        _isLongPressing = false;
        _isHoveringMic = false;
      });
    }
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onQuickAdd();
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 AUTO-SYNC
    final finance = Provider.of<FinanceProvider>(context);

    return Scaffold(
      backgroundColor: finance.themeBg, // 🟢 Murni ngikutin latar tema!
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: widget.isVoiceActive
          ? null
          : _buildCustomBottomNav(finance),
    );
  }

  Widget _buildCustomBottomNav(FinanceProvider finance) {
    return Container(
      decoration: BoxDecoration(
        color: finance.themeBg.withValues(alpha:0.95), // 🟢 Latar Navigasi Solid adaptif
        border: Border(top: BorderSide(color: finance.themeBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1), // Shadow tipis aja biar flat
            blurRadius: 20,
            offset: const Offset(0, -5),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_rounded, 'HOME', 0, finance),
          _buildNavItem(Icons.track_changes_rounded, 'BUDGET', 1, finance),
          
          // --- TOMBOL TENGAH (GESTURE) ---
          GestureDetector(
            onPanStart: _handlePanStart,
            onPanUpdate: _handlePanUpdate,
            onPanEnd: _handlePanEnd,
            onTap: _handleTap,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Icon Mic (Muncul pas ditarik ke atas)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  top: _isLongPressing ? -70 : 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _isLongPressing ? 1.0 : 0.0,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // 🟢 FIX: Ngikutin tema aksen pas hover
                        color: _isHoveringMic ? finance.themeAccent : finance.themeCard,
                        border: Border.all(color: finance.themeBorder),
                        boxShadow: _isHoveringMic ? [
                          BoxShadow(color: finance.themeAccent.withValues(alpha:0.5), blurRadius: 15)
                        ] : null,
                      ),
                      child: Icon(Icons.mic, color: _isHoveringMic ? Colors.white : finance.themeTextSub),
                    ),
                  ),
                ),
                
                // Tombol Plus Utama
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.diagonal3Values(
                    _isLongPressing ? 0.9 : 1.0, 
                    _isLongPressing ? 0.9 : 1.0, 
                    1.0, 
                  ),
                  transformAlignment: Alignment.center,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    // 🟢 FIX: Tombol utama ngikutin Aksen
                    color: _isLongPressing ? finance.themeCard : finance.themeAccent,
                    borderRadius: BorderRadius.circular(24),
                    border: _isLongPressing ? Border.all(color: finance.themeBorder) : null,
                    boxShadow: _isLongPressing ? null : [
                      BoxShadow(color: finance.themeAccent.withValues(alpha:0.4), blurRadius: 10)
                    ],
                  ),
                  child: Icon(Icons.add_circle_outline, color: _isLongPressing ? finance.themeTextSub : Colors.white, size: 28),
                ),
              ],
            ),
          ),

          _buildNavItem(Icons.pie_chart_rounded, 'LAPORAN', 2, finance),
          _buildNavItem(Icons.settings_rounded, 'SETTINGS', 3, finance),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, FinanceProvider finance) {
    final isActive = widget.currentIndex == index;
    return GestureDetector(
      onTap: () => widget.onNavigate(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isActive ? finance.themeAccent.withValues(alpha:0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isActive ? finance.themeAccent : finance.themeTextSub, // 🟢 AUTO-SYNC
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: isActive ? finance.themeAccent : finance.themeTextSub, // 🟢 AUTO-SYNC
            ),
          ),
        ],
      ),
    );
  }
}