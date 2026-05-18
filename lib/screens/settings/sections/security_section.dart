// lib/screens/settings/sections/security_section.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:aplikasi_keuangan/screens/settings/widgets/setting_ui.dart';

class SecuritySection extends StatefulWidget {
  final String? appPin;
  final VoidCallback onOpenPinModal;
  final Function(bool) setUseBiometric;

  const SecuritySection({
    super.key,
    required this.appPin,
    required this.onOpenPinModal,
    required this.setUseBiometric,
  });

  @override
  State<SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends State<SecuritySection> {
  bool _useFaceId = false;
  bool _useFingerprint = false;
  String? _cooldownTime;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _loadBiometricSettings();
    _startCooldownTimer();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBiometricSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _useFaceId = prefs.getBool('setting_useFaceId') ?? false;
      _useFingerprint = prefs.getBool('setting_useFingerprint') ?? false;

      if (_useFaceId || _useFingerprint) {
        widget.setUseBiometric(true);
      }
    });
  }

  void _startCooldownTimer() {
    _checkCooldown();
    _cooldownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkCooldown();
    });
  }

  Future<void> _checkCooldown() async {
    final prefs = await SharedPreferences.getInstance();
    final String? resetTimeStr = prefs.getString('pin_reset_available_at');
    
    if (resetTimeStr != null) {
      final int? resetTime = int.tryParse(resetTimeStr);
      if (resetTime != null) {
        final int timeLeft = resetTime - DateTime.now().millisecondsSinceEpoch;
        if (timeLeft > 0) {
          final int hours = timeLeft ~/ (1000 * 60 * 60);
          final int minutes = (timeLeft % (1000 * 60 * 60)) ~/ (1000 * 60);
          setState(() {
            _cooldownTime = "${hours}j ${minutes}m";
          });
        } else {
          setState(() {
            _cooldownTime = "Siap Direset";
          });
        }
        return;
      }
    }
    setState(() {
      _cooldownTime = null;
    });
  }

  Future<void> _toggleFaceId() async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    final newVal = !_useFaceId;
    
    setState(() {
      _useFaceId = newVal;
    });
    await prefs.setBool('setting_useFaceId', newVal);
    widget.setUseBiometric(newVal || _useFingerprint);
  }

  Future<void> _toggleFingerprint() async {
    HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    final newVal = !_useFingerprint;

    setState(() {
      _useFingerprint = newVal;
    });
    await prefs.setBool('setting_useFingerprint', newVal);
    widget.setUseBiometric(_useFaceId || newVal);
  }

  @override
  Widget build(BuildContext context) {
    final bool isPinActive = widget.appPin != null && widget.appPin!.isNotEmpty;

    return SettingsGroup(
      title: "Security",
      children: [
        SettingsItem(
          icon: Icons.lock_outline_rounded,
          title: "Kode PIN",
          onTap: widget.onOpenPinModal,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isPinActive ? const Color(0xFF10B981).withValues(alpha:0.1) : Colors.white.withValues(alpha:0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isPinActive ? const Color(0xFF10B981).withValues(alpha:0.3) : Colors.white10),
              boxShadow: isPinActive ? [BoxShadow(color: const Color(0xFF10B981).withValues(alpha:0.2), blurRadius: 10)] : null,
            ),
            child: Text(
              isPinActive ? 'AKTIF' : 'NONAKTIF',
              style: TextStyle(
                color: isPinActive ? const Color(0xFF34D399) : Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),

        if (isPinActive)
          SettingsItem(
            icon: Icons.key_rounded,
            title: "Reset Kode PIN",
            onTap: widget.onOpenPinModal,
            trailing: _cooldownTime != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha:0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha:0.3)),
                      boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha:0.2), blurRadius: 10)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.orangeAccent, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          _cooldownTime!.toUpperCase(),
                          style: const TextStyle(color: Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                        ),
                      ],
                    ),
                  )
                : null,
          ),

        SettingsItem(
          icon: Icons.face_rounded,
          title: "Face ID",
          trailing: Switch(
            value: _useFaceId,
            onChanged: (val) => _toggleFaceId(),
            activeThumbColor: const Color(0xFFD946EF), // 🟢 FIX: Ganti ke activeThumbColor
            activeTrackColor: const Color(0xFF9333EA).withValues(alpha: 0.5),
          ),
        ),

        SettingsItem(
          icon: Icons.fingerprint_rounded,
          title: "Sidik Jari",
          trailing: Switch(
            value: _useFingerprint,
            onChanged: (val) => _toggleFingerprint(),
            activeThumbColor: const Color(0xFFD946EF), // 🟢 FIX: Ganti ke activeThumbColor
            activeTrackColor: const Color(0xFF9333EA).withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}