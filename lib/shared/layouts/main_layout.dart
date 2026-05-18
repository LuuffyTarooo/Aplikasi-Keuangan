// lib/shared/layouts/main_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    return Scaffold(
      // 🟢 UBAH BARIS INI BIAR GAK PUTIH LAGI:
      backgroundColor: const Color(0xFF05010D), 
      extendBody: true,
      body: widget.child,
      bottomNavigationBar: widget.isVoiceActive
          ? null
          : _buildCustomBottomNav(),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF05010D).withValues(alpha:0.9),
        border: const Border(top: BorderSide(color: Colors.white10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.3),
            blurRadius: 40,
            offset: const Offset(0, -10),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_rounded, 'HOME', 0),
          _buildNavItem(Icons.track_changes_rounded, 'BUDGET', 1),
          
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
                        color: _isHoveringMic ? const Color(0xFF9333EA) : const Color(0xFF161B22),
                        border: Border.all(color: Colors.white10),
                        boxShadow: _isHoveringMic ? [
                          BoxShadow(color: const Color(0xFF9333EA).withValues(alpha:0.5), blurRadius: 15)
                        ] : null,
                      ),
                      child: Icon(Icons.mic, color: _isHoveringMic ? Colors.white : Colors.white70),
                    ),
                  ),
                ),
                
                // Tombol Plus Utama
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  transform: Matrix4.diagonal3Values(
  _isLongPressing ? 0.9 : 1.0, // Skala Sumbu X
  _isLongPressing ? 0.9 : 1.0, // Skala Sumbu Y
  1.0,                         // Skala Sumbu Z (Tetap Normal)
),
                  transformAlignment: Alignment.center,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isLongPressing ? const Color(0xFF161B22) : const Color(0xFF9333EA),
                    borderRadius: BorderRadius.circular(24),
                    border: _isLongPressing ? Border.all(color: Colors.white10) : null,
                    boxShadow: _isLongPressing ? null : [
                      BoxShadow(color: const Color(0xFF9333EA).withValues(alpha:0.4), blurRadius: 20)
                    ],
                  ),
                  child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),

          _buildNavItem(Icons.pie_chart_rounded, 'LAPORAN', 2),
          _buildNavItem(Icons.settings_rounded, 'SETTINGS', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
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
              color: isActive ? const Color(0xFF9333EA).withValues(alpha:0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isActive ? const Color(0xFFA855F7) : Colors.white54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: isActive ? const Color(0xFFA855F7) : Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}