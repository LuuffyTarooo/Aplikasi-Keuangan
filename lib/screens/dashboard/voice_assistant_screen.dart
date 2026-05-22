// lib/screens/dashboard/voice_assistant_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';
import 'package:aplikasi_keuangan/shared/widgets/custom_button.dart';
import 'package:aplikasi_keuangan/screens/transaction/transaction_form_screen.dart';

class VoiceAssistantSheet extends StatefulWidget {
  const VoiceAssistantSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false, 
      builder: (context) => const VoiceAssistantSheet(),
    );
  }

  @override
  State<VoiceAssistantSheet> createState() => _VoiceAssistantSheetState();
}

class _VoiceAssistantSheetState extends State<VoiceAssistantSheet> with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isListening = false;
  String _voiceText = '';
  String _errorMsg = '';
  Map<String, dynamic>? _parsedData;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListening();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speech.cancel();
    super.dispose();
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
      _parsedData = null;
      _errorMsg = '';
      _voiceText = '';
    });
    HapticFeedback.lightImpact();

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && _isListening) {
              setState(() => _isListening = false);
              if (_voiceText.isNotEmpty && _parsedData == null && _errorMsg.isEmpty) {
                _processVoiceCommand(_voiceText, Provider.of<FinanceProvider>(context, listen: false));
              } else if (_voiceText.isEmpty) {
                setState(() => _errorMsg = "Nggak ada suara yang kedengeran Jar. Coba lagi.");
              }
            }
          });
        }
      },
      onError: (val) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _errorMsg = "Suara nggak jelas atau Mic belum diizinin. (${val.errorMsg})";
          });
        }
      },
    );

    if (available) {
      _speech.listen(
        localeId: 'id_ID',
        onResult: (val) {
          if (mounted) {
            setState(() {
              _voiceText = val.recognizedWords;
            });
            if (val.hasConfidenceRating && val.finalResult) {
               _processVoiceCommand(val.recognizedWords, Provider.of<FinanceProvider>(context, listen: false));
            }
          }
        },
      );
    } else {
      setState(() {
        _isListening = false;
        _errorMsg = "Browser / HP lu nggak dukung fitur suara (Mic) Jar.";
      });
    }
  }

  void _processVoiceCommand(String text, FinanceProvider finance) async {
    if (!mounted) return;
    
    try {
      final parsed = await finance.parseVoiceIntent(text);
      if (!mounted) return;
      setState(() {
        _parsedData = parsed;
        _isListening = false;
        _errorMsg = '';
      });
      HapticFeedback.lightImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMsg = e.toString().replaceAll('Exception: ', '');
        _isListening = false;
        _parsedData = null;
      });
      HapticFeedback.heavyImpact();
    }
  }

  void _simulasikanSuara(FinanceProvider finance) {
    _speech.stop();
    setState(() { _voiceText = "Beli kopi starbucks 50 ribu pakai gopay"; });
    _processVoiceCommand("Beli kopi starbucks 50 ribu pakai gopay", finance);
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    
    return Container(
      height: MediaQuery.of(context).size.height, 
      color: finance.themeBg.withValues(alpha: 0.98), 
      child: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: finance.themeCard, shape: BoxShape.circle, border: Border.all(color: finance.themeBorder)),
                    child: Icon(Icons.close_rounded, color: finance.themeTextSub, size: 24),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildContent(finance),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(FinanceProvider finance) {
    if (_isListening && _parsedData == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onDoubleTap: () => _simulasikanSuara(finance), 
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.8),
                      child: Opacity(
                        opacity: 1.0 - _pulseController.value,
                        child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: finance.themeAccent)),
                      ),
                    ),
                    Transform.scale(
                      scale: 1.0 + (_pulseController.value * 0.3),
                      child: Opacity(
                        opacity: 1.0 - _pulseController.value,
                        child: Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: finance.themeAccent.withValues(alpha:0.5))),
                      ),
                    ),
                    Container(width: 120, height: 120, decoration: BoxDecoration(shape: BoxShape.circle, color: finance.themeAccent), child: const Icon(Icons.mic_rounded, size: 50, color: Colors.white)),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 40),
          Text("Lagi Dengerin...", style: TextStyle(color: finance.themeText, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          const SizedBox(height: 12),
          Text("Sebutin aja pengeluaran kamu,\nmisal: \"Kopi starbucks 50 ribu pakai GoPay\"", textAlign: TextAlign.center, style: TextStyle(color: finance.themeTextSub, fontSize: 14, height: 1.5)),
          if (_voiceText.isNotEmpty) ...[
            const SizedBox(height: 32),
            // 🟢 FIX WARNING: Interpolasi string udah dibenerin
            Text('"$_voiceText"', textAlign: TextAlign.center, style: TextStyle(color: finance.themeAccent, fontSize: 16, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold)),
          ]
        ],
      );
    }

    if (!_isListening && _errorMsg.isNotEmpty && _parsedData == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), shape: BoxShape.circle, border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3))),
            child: const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 50),
          ),
          const SizedBox(height: 32),
          Text(_errorMsg, textAlign: TextAlign.center, style: TextStyle(color: finance.themeText, fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          if (_voiceText.isNotEmpty)
            // 🟢 FIX WARNING: Interpolasi string udah dibenerin
            Text('Kata yang ketangkep:\n"$_voiceText"', textAlign: TextAlign.center, style: TextStyle(color: finance.themeTextSub, fontSize: 14, fontStyle: FontStyle.italic)),
          const SizedBox(height: 40),
          CustomButton(
            text: "Coba Ngomong Lagi", icon: Icons.mic_rounded, variant: ButtonVariant.primary,
            onPressed: _startListening,
          )
        ],
      );
    }

    if (!_isListening && _parsedData != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(32), border: Border.all(color: finance.themeBorder)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.green.withValues(alpha:0.1), shape: BoxShape.circle), child: const Icon(Icons.check_rounded, color: Colors.green, size: 40)),
            const SizedBox(height: 16),
            Text("Berhasil Ditangkap", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2.0)),
            Text(Formatters.formatCurrency(_parsedData!['nominal']), style: TextStyle(color: _parsedData!['jenis'] == 'Pengeluaran' ? Colors.redAccent : Colors.green, fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -1)),
            const SizedBox(height: 24),
            
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: finance.themeBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: finance.themeBorder)),
              child: Column(
                children: [
                  _buildDetailRow("Jenis", _parsedData!['jenis'], finance),
                  Divider(color: finance.themeBorder, height: 24),
                  if (_parsedData!['jenis'] != 'Transfer') ...[
                    _buildDetailRow("Kategori", _parsedData!['kategori'], finance),
                    Divider(color: finance.themeBorder, height: 24),
                    _buildDetailRow("Dompet", _parsedData!['nama_dompet'], finance),
                  ] else ...[
                    _buildDetailRow("Dari Dompet", _parsedData!['nama_dompet'], finance),
                    Divider(color: finance.themeBorder, height: 24),
                    _buildDetailRow("Ke Dompet", _parsedData!['nama_dompet_tujuan'] ?? '-', finance),
                  ],
                  Divider(color: finance.themeBorder, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Catatan", style: TextStyle(color: finance.themeTextSub, fontSize: 12, fontWeight: FontWeight.bold)),
                      Flexible(child: Text('"${_parsedData!['keterangan']}"', textAlign: TextAlign.right, style: TextStyle(color: finance.themeText, fontSize: 12, fontStyle: FontStyle.italic, fontWeight: FontWeight.w900))),
                    ],
                  ),
                ],
              ),
            ),
            if (_parsedData!['tts_message'] != null) ...[
              const SizedBox(height: 16),
              Text(_parsedData!['tts_message'], textAlign: TextAlign.center, style: TextStyle(color: finance.themeAccent, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: CustomButton(
                    text: "", icon: Icons.edit_rounded, variant: ButtonVariant.secondary, 
                    onPressed: () {
                      final tx = TransactionModel(
                        idTransaksi: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                        jenis: _parsedData!['jenis'],
                        nominal: _parsedData!['nominal'],
                        idDana: _parsedData!['id_dana'],
                        idDanaTujuan: _parsedData!['id_dana_tujuan'] ?? '',
                        kategori: _parsedData!['kategori'],
                        keterangan: _parsedData!['keterangan'],
                        tanggal: _parsedData!['tanggal'],
                        userId: finance.currentUser!.id,
                      );
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => TransactionFormScreen(initialData: tx)));
                    }
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: CustomButton(
                    text: "Simpan Transaksi", 
                    variant: ButtonVariant.primary,
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      final tx = TransactionModel(
                        idTransaksi: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                        jenis: _parsedData!['jenis'],
                        nominal: _parsedData!['nominal'],
                        idDana: _parsedData!['id_dana'],
                        idDanaTujuan: _parsedData!['id_dana_tujuan'] ?? '',
                        kategori: _parsedData!['kategori'],
                        keterangan: _parsedData!['keterangan'],
                        tanggal: _parsedData!['tanggal'],
                        userId: finance.currentUser!.id,
                      );
                      
                      finance.handleSaveTransaksi(tx);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Transaksi suara berhasil dicatat!"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
                    },
                  ),
                ),
              ],
            )
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDetailRow(String label, String value, FinanceProvider finance) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: finance.themeTextSub, fontSize: 12, fontWeight: FontWeight.bold)),
        Text(value, style: TextStyle(color: finance.themeText, fontSize: 14, fontWeight: FontWeight.w900)),
      ],
    );
  }
}