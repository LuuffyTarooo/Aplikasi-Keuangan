// lib/screens/settings/dialogs/pin_manager_dialog.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PinManagerScreen extends StatefulWidget {
  final String currentPin;
  final Function(String?) onPinChanged; // Null kalau dinonaktifkan

  const PinManagerScreen({super.key, required this.currentPin, required this.onPinChanged});

  static void show(BuildContext context, String currentPin, Function(String?) onPinChanged) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // Biar background transparan
        pageBuilder: (context, animation, secondaryAnimation) => PinManagerScreen(currentPin: currentPin, onPinChanged: onPinChanged),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0); // Muncul dari kanan
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  @override
  State<PinManagerScreen> createState() => _PinManagerScreenState();
}

class _PinManagerScreenState extends State<PinManagerScreen> with SingleTickerProviderStateMixin {
  String _step = 'NEW'; // VERIFY, NEW, CONFIRM, COUNTDOWN
  String _actionTarget = 'CHANGE'; // CHANGE, DISABLE
  
  String _pin = '';
  String _tempPin = '';
  bool _error = false;

  int? _resetAvailableAt;
  String _timeLeft = '';
  Timer? _timer;

  // Animasi Shake pas error
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 0.0), weight: 1),
    ]).animate(_shakeController);

    _initPinLogic();
  }

  void _initPinLogic() {
    // Catatan: Nanti ganti pake SharedPreferences di production
    // String? resetTime; // Di-komen biar gak warning unused
    
    _step = widget.currentPin.isNotEmpty ? 'VERIFY' : 'NEW';
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resetAvailableAt == null) return;
      int diff = _resetAvailableAt! - DateTime.now().millisecondsSinceEpoch;
      if (diff <= 0) {
        if (!mounted) return; // 🟢 Proteksi async
        setState(() {
          _timeLeft = '00:00:00';
          _step = 'NEW';
          widget.onPinChanged(null); // Reset PIN
        });
        timer.cancel();
      } else {
        int h = (diff / (1000 * 60 * 60)).floor();
        int m = ((diff % (1000 * 60 * 60)) / (1000 * 60)).floor();
        int s = ((diff % (1000 * 60)) / 1000).floor();
        if (!mounted) return; // 🟢 Proteksi async
        setState(() {
          _timeLeft = '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _showToast(String message, {bool isError = false}) {
    if (!mounted) return; // 🟢 Proteksi async
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(isError ? Icons.gpp_bad_rounded : Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: isError ? Colors.pinkAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleNumpad(String val) {
    HapticFeedback.lightImpact();
    setState(() => _error = false);

    if (val == 'delete') {
      if (_pin.isNotEmpty) {
        setState(() => _pin = _pin.substring(0, _pin.length - 1));
      }
      return;
    }

    if (_pin.length < 4) {
      setState(() => _pin += val);
      if (_pin.length == 4) {
        Future.delayed(const Duration(milliseconds: 100), () => _processPin(_pin));
      }
    }
  }

  void _processPin(String currentPin) {
    if (_step == 'VERIFY') {
      if (currentPin == widget.currentPin) {
        if (_actionTarget == 'DISABLE') {
          HapticFeedback.heavyImpact();
          widget.onPinChanged(null);
          _showToast("Kode PIN dinonaktifkan!");
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) Navigator.pop(context); // 🟢 Proteksi async
          });
        } else {
          HapticFeedback.mediumImpact();
          setState(() { _step = 'NEW'; _pin = ''; });
        }
      } else {
        _triggerError();
      }
    } else if (_step == 'NEW') {
      HapticFeedback.lightImpact();
      setState(() { _tempPin = currentPin; _step = 'CONFIRM'; _pin = ''; });
    } else if (_step == 'CONFIRM') {
      if (currentPin == _tempPin) {
        HapticFeedback.heavyImpact();
        widget.onPinChanged(currentPin);
        _showToast("Kode PIN berhasil diperbarui!");
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) Navigator.pop(context); // 🟢 Proteksi async
        });
      } else {
        _triggerError();
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) { // 🟢 Proteksi async
            setState(() { _pin = ''; _tempPin = ''; _step = 'NEW'; });
          }
        });
      }
    }
  }

  void _triggerError() {
    HapticFeedback.heavyImpact();
    setState(() => _error = true);
    _shakeController.forward(from: 0.0);
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _pin = ''); // 🟢 Proteksi async
    });
  }

  void _triggerForgotPin() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.white10)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha:0.1), shape: BoxShape.circle), child: const Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 32)),
            const SizedBox(height: 16),
            const Text("Lupa PIN?", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text("Sistem akan menunda pergantian PIN selama 24 Jam ke depan demi keamanan. Yakin dilanjutkan?", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Batal", style: TextStyle(color: Colors.white54)))),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      int unlockTime = DateTime.now().millisecondsSinceEpoch + (24 * 60 * 60 * 1000);
                      // Catatan: Save to SharedPreferences
                      setState(() {
                        _resetAvailableAt = unlockTime;
                        _step = 'COUNTDOWN';
                      });
                      _startTimer();
                      if (dialogContext.mounted) {
                         Navigator.pop(dialogContext);
                      }
                    },
                    child: const Text("Ya, Lanjut", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color activeColor = _error ? Colors.pinkAccent : (_step == 'COUNTDOWN' ? Colors.orangeAccent : Colors.greenAccent);
    IconData statusIcon = _step == 'COUNTDOWN' ? Icons.timer_rounded : (_error ? Icons.gpp_bad_rounded : Icons.shield_rounded);

    return Scaffold(
      backgroundColor: const Color(0xFF05010D).withValues(alpha:0.8),
      body: Stack(
        children: [
          // Background Blur
          Positioned.fill(child: Container(color: Colors.black54)),
          
          SafeArea(
            child: Column(
              children: [
                // Header Navigasi
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                        child: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), shape: BoxShape.circle), child: const Icon(Icons.close_rounded, color: Colors.white, size: 20)),
                      ),
                      const SizedBox(width: 16),
                      Text(_step == 'COUNTDOWN' ? "RESET DITUNDA" : "KEAMANAN", style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
                    ],
                  ),
                ),

                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ikon Status
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 80, height: 80,
                        decoration: BoxDecoration(color: activeColor.withValues(alpha:0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: activeColor.withValues(alpha:0.3)), boxShadow: [BoxShadow(color: activeColor.withValues(alpha:0.2), blurRadius: 20)]),
                        child: Icon(statusIcon, size: 40, color: activeColor),
                      ),
                      const SizedBox(height: 24),

                      // Judul
                      Text(
                        _step == 'VERIFY' && _actionTarget == 'CHANGE' ? "Masukkan PIN Lama" :
                        _step == 'VERIFY' && _actionTarget == 'DISABLE' ? "Masukkan PIN untuk Nonaktifkan" :
                        _step == 'NEW' && widget.currentPin.isNotEmpty ? "Buat PIN Baru" :
                        _step == 'NEW' ? "Buat Kode PIN" :
                        _step == 'CONFIRM' ? "Konfirmasi PIN Baru" :
                        "Proses Keamanan",
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Subjudul
                      Text(
                        _error ? "PIN tidak cocok. Coba lagi." :
                        _step == 'COUNTDOWN' ? "Pergantian PIN ditunda untuk mencegah akses tidak sah." :
                        "Masukkan 4 digit angka",
                        style: TextStyle(color: _error ? Colors.pinkAccent : Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Titik-Titik PIN atau Countdown
                      if (_step == 'COUNTDOWN')
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.white10)),
                          child: Column(
                            children: [
                              const Text("PIN DAPAT DIUBAH DALAM", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                              const SizedBox(height: 8),
                              Text(_timeLeft, style: const TextStyle(color: Colors.orangeAccent, fontSize: 40, fontWeight: FontWeight.w900, fontFamily: 'monospace', shadows: [Shadow(color: Colors.orangeAccent, blurRadius: 10)])),
                            ],
                          ),
                        )
                      else
                        AnimatedBuilder(
                          animation: _shakeAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(_shakeAnimation.value, 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(4, (index) {
                                  bool isFilled = index < _pin.length;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: isFilled ? 20 : 16,
                                    height: isFilled ? 20 : 16,
                                    margin: const EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: isFilled ? const Color(0xFFA855F7) : Colors.white.withValues(alpha:0.1),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: isFilled ? const Color(0xFFA855F7) : Colors.white24),
                                      boxShadow: isFilled ? [const BoxShadow(color: Color(0xFFA855F7), blurRadius: 10)] : null,
                                    ),
                                  );
                                }),
                              ),
                            );
                          }
                        ),

                      // Tombol Bantuan (Lupa PIN / Batal)
                      if (_step == 'VERIFY' && widget.currentPin.isNotEmpty) ...[
                        const SizedBox(height: 32),
                        if (_actionTarget == 'CHANGE')
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(onPressed: _triggerForgotPin, child: const Text("Lupa PIN?", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold))),
                              const SizedBox(width: 16),
                              TextButton(onPressed: () { HapticFeedback.lightImpact(); setState(() { _actionTarget = 'DISABLE'; _pin = ''; _error = false; }); }, child: const Text("Nonaktifkan PIN", style: TextStyle(color: Colors.pinkAccent, fontWeight: FontWeight.bold))),
                            ],
                          )
                        else
                          TextButton(onPressed: () { HapticFeedback.lightImpact(); setState(() { _actionTarget = 'CHANGE'; _pin = ''; _error = false; }); }, child: const Text("Batal Nonaktifkan", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold))),
                      ]
                    ],
                  ),
                ),

                // Numpad Bawah
                if (_step != 'COUNTDOWN')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                    decoration: BoxDecoration(color: const Color(0xFF161B22), borderRadius: const BorderRadius.vertical(top: Radius.circular(40)), border: const Border(top: BorderSide(color: Colors.white10)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.5), blurRadius: 40, offset: const Offset(0, -10))]),
                    child: GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 3,
                      childAspectRatio: 1.5,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: [
                        _buildNumpadBtn('1'), _buildNumpadBtn('2', sub: 'ABC'), _buildNumpadBtn('3', sub: 'DEF'),
                        _buildNumpadBtn('4', sub: 'GHI'), _buildNumpadBtn('5', sub: 'JKL'), _buildNumpadBtn('6', sub: 'MNO'),
                        _buildNumpadBtn('7', sub: 'PQRS'), _buildNumpadBtn('8', sub: 'TUV'), _buildNumpadBtn('9', sub: 'WXYZ'),
                        const SizedBox.shrink(), _buildNumpadBtn('0'), _buildNumpadBtn('delete', icon: Icons.backspace_rounded),
                      ],
                    ),
                  )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpadBtn(String val, {String? sub, IconData? icon}) {
    return GestureDetector(
      onTap: () => _handleNumpad(val),
      child: Container(
        color: Colors.transparent, // Biar area tap gede
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, color: Colors.white, size: 28)
            else
              Text(val, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w400)),
            if (sub != null)
              Text(sub, style: const TextStyle(color: Colors.white30, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}