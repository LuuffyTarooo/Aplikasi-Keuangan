// lib/screens/auth/login_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/main.dart'; 

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  String enteredPin = '';
  bool isError = false;
  
  String _timeLeft = '24:00:00';
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialSecurityState();
    });
  }

  void _checkInitialSecurityState() {
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    
    int now = DateTime.now().millisecondsSinceEpoch;
    
    // 1. Cek apakah lagi dalam masa hukuman countdown 24 jam
    if (finance.pinLockoutUntil > 0 && now < finance.pinLockoutUntil) {
      _startCountdownTimer(finance.pinLockoutUntil);
      return;
    } 
    
    // 2. Kalau masa hukuman udah lewat pas app baru dibuka, bebaskan!
    if (finance.pinLockoutUntil > 0 && now >= finance.pinLockoutUntil) {
      finance.clearLockoutAndResetPin();
      _unlockApp();
      return;
    }

    // 3. Kalau user emang pemales belum pernah pasang PIN, langsung masuk!
    if (finance.userPin.isEmpty) {
      _unlockApp();
      return;
    }

    // 4. Kalau semua aman dan PIN ada, panggil Face ID / Sidik Jari
    _authenticateBiometric();
  }

  // Timer detak detik buat ngitung mundur 24 jam secara realtime di UI
  void _startCountdownTimer(int targetTimestamp) {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      int diff = targetTimestamp - DateTime.now().millisecondsSinceEpoch;
      
      if (diff <= 0) {
        timer.cancel();
        final finance = Provider.of<FinanceProvider>(context, listen: false);
        finance.clearLockoutAndResetPin(); // Hapus sandi & kunci internal HP
        _unlockApp();
      } else {
        int h = (diff / (1000 * 60 * 60)).floor();
        int m = ((diff % (1000 * 60 * 60)) / (1000 * 60)).floor();
        int s = ((diff % (1000 * 60)) / 1000).floor();
        if (mounted) {
          setState(() {
            _timeLeft = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
          });
        }
      }
    });
  }

  Future<void> _authenticateBiometric() async {
    try {
      final bool canAuthenticate = await auth.canCheckBiometrics || await auth.isDeviceSupported();
      if (canAuthenticate) {
        final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Gunakan Sidik Jari atau Face ID untuk masuk',
        );
        if (didAuthenticate && mounted) _unlockApp();
      }
    } catch (e) {
      debugPrint("Error Biometric: $e");
    }
  }

  void _onNumPressed(String num) {
    HapticFeedback.lightImpact();
    if (enteredPin.length < 4) {
      setState(() {
        enteredPin += num;
        isError = false;
      });

      if (enteredPin.length == 4) {
        Future.delayed(const Duration(milliseconds: 100), _verifyPin);
      }
    }
  }

  void _onDeletePressed() {
    HapticFeedback.lightImpact();
    if (enteredPin.isNotEmpty) {
      setState(() {
        enteredPin = enteredPin.substring(0, enteredPin.length - 1);
        isError = false;
      });
    }
  }

  void _verifyPin() {
    final finance = Provider.of<FinanceProvider>(context, listen: false);
    if (enteredPin == finance.userPin) {
      _unlockApp();
    } else {
      HapticFeedback.heavyImpact();
      setState(() {
        isError = true;
        enteredPin = '';
      });
    }
  }

  void _triggerForgotPin(FinanceProvider finance) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: finance.themeBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: finance.themeBorder)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha:0.1), shape: BoxShape.circle), child: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 32)),
            const SizedBox(height: 16),
            Text("Lupa PIN?", style: TextStyle(color: finance.themeText, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text("Aplikasi akan dikunci selama 24 Jam demi keamanan, setelah itu PIN akan dihapus otomatis. Lanjutkan?", textAlign: TextAlign.center, style: TextStyle(color: finance.themeTextSub, fontSize: 12)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text("Batal", style: TextStyle(color: finance.themeTextSub)))),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      finance.startForgotPinLockout(); // Trigger 24 jam di Provider & Storage HP
                      _startCountdownTimer(finance.pinLockoutUntil);
                    },
                    child: const Text("Ya, Mulai", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _unlockApp() {
    HapticFeedback.lightImpact();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainAppShell()));
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    int now = DateTime.now().millisecondsSinceEpoch;
    bool isLockoutActive = finance.pinLockoutUntil > 0 && now < finance.pinLockoutUntil;

    // Pas app kebuka dan PIN emang kosong, kasih container kosong biar transisi ke dashboard bersih
    if (finance.userPin.isEmpty && !isLockoutActive) {
      return Scaffold(backgroundColor: finance.themeBg);
    }

    return Scaffold(
      backgroundColor: finance.themeBg,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            
            // TAMPILAN LOCKOUT 24 JAM
            if (isLockoutActive) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha:0.1), shape: BoxShape.circle, border: Border.all(color: Colors.orangeAccent.withValues(alpha:0.2))),
                child: const Icon(Icons.timer_rounded, color: Colors.orangeAccent, size: 54),
              ),
              const SizedBox(height: 24),
              Text("Akses Ditunda", style: TextStyle(color: finance.themeText, fontSize: 22, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text("Kamu memilih lupa sandi. Aplikasi dapat dibuka kembali tanpa PIN dalam waktu:", style: TextStyle(color: finance.themeTextSub, fontSize: 13), textAlign: TextAlign.center),
              ),
              const SizedBox(height: 32),
              Text(_timeLeft, style: const TextStyle(color: Colors.orangeAccent, fontSize: 44, fontWeight: FontWeight.w900, fontFamily: 'monospace', letterSpacing: 1.5, shadows: [Shadow(color: Colors.orangeAccent, blurRadius: 10)])),
              const Spacer(),
            ] 
            // TAMPILAN NORMAL MASUKIN PIN
            else ...[
              Icon(Icons.lock_outline_rounded, color: finance.themeAccent, size: 64),
              const SizedBox(height: 24),
              Text("Masukkan PIN", style: TextStyle(color: finance.themeText, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(isError ? "PIN Salah, coba lagi!" : "Amankan data keuanganmu", style: TextStyle(color: isError ? Colors.redAccent : finance.themeTextSub, fontSize: 14, fontWeight: FontWeight.bold)),
              
              const SizedBox(height: 40),

              // Indikator 4 Bulatan PIN
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  bool isFilled = index < enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 16, height: 16,
                    decoration: BoxDecoration(
                      color: isFilled ? finance.themeAccent : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(color: isFilled ? finance.themeAccent : finance.themeBorder, width: 2),
                    ),
                  );
                }),
              ),
              
              // 🟢 TOMBOL LUPA PIN JALUR RESMI
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => _triggerForgotPin(finance),
                child: const Text("Lupa PIN?", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.w900, fontSize: 13)),
              ),

              const Spacer(),

              // Numpad
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                child: Column(
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: ['1', '2', '3'].map((n) => _buildNumBtn(n, finance)).toList()),
                    const SizedBox(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: ['4', '5', '6'].map((n) => _buildNumBtn(n, finance)).toList()),
                    const SizedBox(height: 24),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: ['7', '8', '9'].map((n) => _buildNumBtn(n, finance)).toList()),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: _authenticateBiometric,
                          child: Container(width: 70, height: 70, alignment: Alignment.center, child: Icon(Icons.fingerprint_rounded, color: finance.themeAccent, size: 32)),
                        ),
                        _buildNumBtn('0', finance),
                        GestureDetector(
                          onTap: _onDeletePressed,
                          child: Container(width: 70, height: 70, alignment: Alignment.center, child: Icon(Icons.backspace_outlined, color: finance.themeTextSub, size: 28)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNumBtn(String num, FinanceProvider finance) {
    return GestureDetector(
      onTap: () => _onNumPressed(num),
      child: Container(
        width: 70, height: 70,
        decoration: const BoxDecoration(color: Colors.transparent, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: Text(num, style: TextStyle(color: finance.themeText, fontSize: 32, fontWeight: FontWeight.w400)),
      ),
    );
  }
}