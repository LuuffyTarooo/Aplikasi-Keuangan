// lib/screens/report/widgets/analytics_section.dart
import 'dart:math'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:aplikasi_keuangan/models/transaction_model.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';
import 'package:aplikasi_keuangan/shared/widgets/glass_card.dart';

class AnalyticsSection extends StatefulWidget {
  final List<TransactionModel> transaksi;
  final DateTime currentDate;
  final Function(DateTime) onDateChange;

  const AnalyticsSection({
    super.key,
    required this.transaksi,
    required this.currentDate,
    required this.onDateChange,
  });

  @override
  State<AnalyticsSection> createState() => _AnalyticsSectionState();
}

class _AnalyticsSectionState extends State<AnalyticsSection> {
  String _analysisMode = 'Pengeluaran';
  String _trendFilter = 'Weekly';
  int? _selectedBarIndex;

  final List<Color> _donutColors = [
    const Color(0xFFA855F7), 
    const Color(0xFFD946EF), 
    const Color(0xFFEC4899), 
    const Color(0xFF8B5CF6), 
    const Color(0xFF6366F1), 
    const Color(0xFF3B82F6), 
    const Color(0xFF10B981), 
    const Color(0xFFF59E0B), 
  ];

  @override
  void didUpdateWidget(AnalyticsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDate != widget.currentDate) {
      _selectedBarIndex = null;
    }
  }

  Color get _themeColor => _analysisMode == 'Pemasukan' ? Colors.greenAccent : const Color(0xFFD946EF);

  @override
  Widget build(BuildContext context) {
    final modeTxs = widget.transaksi.where((t) => t.jenis == _analysisMode).toList();

    return Column(
      children: [
        // --- TABS (Pengeluaran | Pemasukan) ---
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: ['Pengeluaran', 'Pemasukan'].map((tab) {
              final isActive = _analysisMode == tab;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _analysisMode = tab;
                    _selectedBarIndex = null;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF9333EA) : Colors.white.withValues(alpha:0.05),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: isActive ? const Color(0xFF9333EA).withValues(alpha:0.5) : Colors.white10),
                    boxShadow: isActive ? [BoxShadow(color: const Color(0xFF9333EA).withValues(alpha:0.4), blurRadius: 15)] : null,
                  ),
                  child: Text(
                    tab,
                    style: TextStyle(
                      color: isActive ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        if (modeTxs.isEmpty)
          GlassCard(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 48, color: const Color(0xFFA855F7).withValues(alpha:0.3)),
                  const SizedBox(height: 12),
                  const Text("BELUM ADA DATA", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
                ],
              ),
            ),
          )
        else ...[
          // --- BAR CHART (TREND) ---
          _buildBarChart(modeTxs),
          const SizedBox(height: 16),
          // --- DONUT CHART (SOURCES) ---
          _buildDonutChart(modeTxs),
        ],
      ],
    );
  }

  // ====================================================
  // ⚡ 1. WIDGET BAR CHART (LOGIKA TREND)
  // ====================================================
  Widget _buildBarChart(List<TransactionModel> modeTxs) {
    final year = widget.currentDate.year;
    final month = widget.currentDate.month;

    final trendTxs = modeTxs.where((t) {
      final d = DateTime.parse(t.tanggal);
      if (_trendFilter == 'Monthly') return d.year == year;
      return d.year == year && d.month == month;
    }).toList();

    double trendTotalAmount = trendTxs.fold(0, (sum, curr) => sum + curr.nominal);

    List<Map<String, dynamic>> barData = [];
    if (_trendFilter == 'Daily') {
      int daysInMonth = DateTime(year, month + 1, 0).day;
      for (int i = 1; i <= daysInMonth; i++) { barData.add({'label': '$i', 'nominal': 0.0}); }
      for (var tx in trendTxs) {
        int d = DateTime.parse(tx.tanggal).day;
        barData[d - 1]['nominal'] += tx.nominal;
      }
    } else if (_trendFilter == 'Weekly') {
      for (int i = 1; i <= 5; i++) { barData.add({'label': 'Wk $i', 'nominal': 0.0}); }
      for (var tx in trendTxs) {
        int d = DateTime.parse(tx.tanggal).day;
        int weekIdx = ((d - 1) / 7).floor();
        if (weekIdx > 4) weekIdx = 4;
        barData[weekIdx]['nominal'] += tx.nominal;
      }
    } else if (_trendFilter == 'Monthly') {
      for (int i = 0; i < 12; i++) { barData.add({'label': Formatters.monthNames[i].substring(0, 3), 'nominal': 0.0}); }
      for (var tx in trendTxs) {
        int m = DateTime.parse(tx.tanggal).month;
        barData[m - 1]['nominal'] += tx.nominal;
      }
    }

    double maxNominal = barData.fold(0.0, (max, item) => item['nominal'] > max ? item['nominal'] : max);
    double safeMax = maxNominal > 0 ? maxNominal : 1;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_analysisMode == 'Pemasukan' ? 'Income Trend' : 'Expense Trend', style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(
                      Formatters.formatCurrency(trendTotalAmount),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(onTap: () => widget.onDateChange(DateTime(year, month - 1, 1)), child: const Icon(Icons.chevron_left_rounded, color: Colors.white54, size: 20)),
                        Text(_trendFilter == 'Monthly' ? 'TAHUN $year' : '${Formatters.monthNames[month - 1].toUpperCase()} $year', style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        GestureDetector(onTap: () => widget.onDateChange(DateTime(year, month + 1, 1)), child: const Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 20)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white10)),
                    child: Row(
                      children: ['Daily', 'Weekly', 'Monthly'].map((tf) {
                        bool isActive = _trendFilter == tf;
                        return GestureDetector(
                          onTap: () { HapticFeedback.lightImpact(); setState(() { _trendFilter = tf; _selectedBarIndex = null; }); },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: isActive ? const Color(0xFF9333EA) : Colors.transparent, borderRadius: BorderRadius.circular(6)),
                            child: Text(tf, style: TextStyle(color: isActive ? Colors.white : Colors.white54, fontSize: 8, fontWeight: FontWeight.w900)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  if (_selectedBarIndex != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: () { HapticFeedback.lightImpact(); setState(() => _selectedBarIndex = null); },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.pinkAccent.withValues(alpha:0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.pinkAccent.withValues(alpha:0.3))),
                          child: const Row(children: [Icon(Icons.close_rounded, color: Colors.pinkAccent, size: 10), SizedBox(width: 4), Text("Reset", style: TextStyle(color: Colors.pinkAccent, fontSize: 9, fontWeight: FontWeight.bold))]),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 🟢 FIX: Tinggi area chart dinaikin dikit biar tooltip gak nabrak atas/bawah
          SizedBox(
            height: 220, 
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    width: _trendFilter == 'Daily' ? 600 : constraints.maxWidth,
                    child: Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(5, (index) => Container(height: 1, color: Colors.white.withValues(alpha:0.05))),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: barData.asMap().entries.map((entry) {
                            int i = entry.key;
                            double nominal = entry.value['nominal'];
                            String label = entry.value['label'];
                            double percent = (nominal / safeMax).clamp(0.0, 1.0);
                            bool isZero = nominal == 0;
                            bool isSelected = _selectedBarIndex == i;
                            bool isDimmed = _selectedBarIndex != null && _selectedBarIndex != i;

                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (!isZero) {
                                    HapticFeedback.lightImpact();
                                    setState(() => _selectedBarIndex = _selectedBarIndex == i ? null : i);
                                  }
                                },
                                child: Container(
                                  color: Colors.transparent,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (isSelected && !isZero)
                                        // 🟢 FIX: UnconstrainedBox biar tooltip teks nominalnya gak ke-wrap memanjang ke bawah!
                                        UnconstrainedBox(
                                          alignment: Alignment.bottomCenter,
                                          child: Container(
                                            margin: const EdgeInsets.only(bottom: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(color: _themeColor.withValues(alpha:0.2), borderRadius: BorderRadius.circular(6), border: Border.all(color: _themeColor)),
                                            child: Text(Formatters.formatUangCompact(nominal), style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                          ),
                                        ),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 300),
                                        height: isZero ? 2 : (percent * 140),
                                        width: 16,
                                        margin: const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFF7C3AED), _themeColor]),
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                          boxShadow: isSelected ? [BoxShadow(color: _themeColor.withValues(alpha:0.6), blurRadius: 10)] : [],
                                          color: isZero ? Colors.white.withValues(alpha:0.1) : null,
                                        ),
                                        foregroundDecoration: BoxDecoration(color: isDimmed ? Colors.black.withValues(alpha:0.5) : Colors.transparent),
                                      ),
                                      Text(label, style: TextStyle(color: isSelected ? _themeColor : Colors.white54, fontSize: 9, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 4), // 🟢 FIX: Padding bawah biar label gak nempel banget ke lantai overflow
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================
  // ⚡ 2. WIDGET DONUT CHART & GRID (LOGIKA KATEGORI)
  // ====================================================
  Widget _buildDonutChart(List<TransactionModel> modeTxs) {
    final year = widget.currentDate.year;
    final month = widget.currentDate.month;

    List<TransactionModel> sourceTxs = [];
    String periodLabel = '';

    if (_selectedBarIndex != null) {
      if (_trendFilter == 'Daily') {
        int selectedDay = _selectedBarIndex! + 1;
        sourceTxs = modeTxs.where((t) {
          final d = DateTime.parse(t.tanggal);
          return d.year == year && d.month == month && d.day == selectedDay;
        }).toList();
        periodLabel = '$selectedDay ${Formatters.monthNames[month - 1].substring(0, 3).toUpperCase()} $year';
      } else if (_trendFilter == 'Weekly') {
        sourceTxs = modeTxs.where((t) {
          final d = DateTime.parse(t.tanggal);
          int weekIdx = ((d.day - 1) / 7).floor();
          if (weekIdx > 4) weekIdx = 4;
          return d.year == year && d.month == month && weekIdx == _selectedBarIndex;
        }).toList();
        periodLabel = 'MINGGU ${_selectedBarIndex! + 1}';
      } else if (_trendFilter == 'Monthly') {
        sourceTxs = modeTxs.where((t) {
          final d = DateTime.parse(t.tanggal);
          return d.year == year && d.month == (_selectedBarIndex! + 1);
        }).toList();
        periodLabel = '${Formatters.monthNames[_selectedBarIndex!].toUpperCase()} $year';
      }
    } else {
      sourceTxs = modeTxs.where((t) {
        final d = DateTime.parse(t.tanggal);
        return d.year == year && d.month == month;
      }).toList();
      periodLabel = '${Formatters.monthNames[month - 1].toUpperCase()} $year';
    }

    double sourceTotalAmount = sourceTxs.fold(0, (sum, t) => sum + t.nominal);

    Map<String, double> kategoriMap = {};
    for (var tx in sourceTxs) {
      String cat = tx.kategori.isEmpty ? 'Lain-lain' : tx.kategori;
      kategoriMap[cat] = (kategoriMap[cat] ?? 0) + tx.nominal;
    }

    List<MapEntry<String, double>> chartData = kategoriMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    List<double> chartValues = chartData.map((e) => e.value).toList();

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_analysisMode == 'Pemasukan' ? 'Income Sources' : 'Expense Sources', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white10)),
                child: Row(
                  children: [
                    const Icon(Icons.chevron_left_rounded, size: 14, color: Colors.white54),
                    const SizedBox(width: 4),
                    Text(periodLabel, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 14, color: Colors.white54),
                  ],
                ),
              ),
            ],
          ),
          
          if (chartData.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Text("Tidak ada data untuk periode ini.", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: CustomPaint(
                      painter: _DonutChartPainter(
                        values: chartValues,
                        colors: _donutColors,
                        strokeWidth: 35, 
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("TOTAL", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.formatUangCompact(sourceTotalAmount),
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ],
                  )
                ],
              ),
            ),

            // 🟢 FIX: Mengganti GridView jadi LayoutBuilder + Wrap biar otomatis nengah
            LayoutBuilder(
              builder: (context, constraints) {
                // Kalkulasi lebar 1 kotak (12 itu margin jarak antar kotak)
                double itemWidth = (constraints.maxWidth - 12) / 2;
                
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center, // Kunci utama biar ke tengah!
                  children: chartData.asMap().entries.map((entry) {
                    int idx = entry.key;
                    String catName = entry.value.key;
                    double nominal = entry.value.value;
                    double percent = sourceTotalAmount > 0 ? (nominal / sourceTotalAmount) * 100 : 0;
                    Color catColor = _donutColors[idx % _donutColors.length];

                    return SizedBox(
                      width: itemWidth,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showCategoryDetailModal(catName, sourceTxs.where((t) => t.kategori == catName).toList());
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1B38),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(width: 8, height: 8, decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      catName, 
                                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text("${percent.toStringAsFixed(0)}%", style: const TextStyle(color: Colors.white54, fontSize: 10)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                Formatters.formatCurrency(nominal), 
                                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              }
            ),
          ],
        ],
      ),
    );
  }

  // ====================================================
  // ⚡ 3. MODAL DETAIL KATEGORI (BOTTOM SHEET)
  // ====================================================
  void _showCategoryDetailModal(String categoryName, List<TransactionModel> txs) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Color(0xFF161B22), borderRadius: BorderRadius.vertical(top: Radius.circular(32)), border: Border(top: BorderSide(color: Colors.white10))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(categoryName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
              const Text("Rincian Transaksi", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: txs.length,
                  itemBuilder: (context, index) {
                    final tx = txs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha:0.05), borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tx.keterangan.isEmpty ? 'Tanpa Catatan' : tx.keterangan, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                Text(DateFormat('dd MMM yyyy').format(DateTime.parse(tx.tanggal)), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                              ],
                            ),
                          ),
                          Text(Formatters.formatCurrency(tx.nominal), style: TextStyle(color: _themeColor, fontSize: 14, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ==========================================================
// 🎨 CLASS CUSTOM PAINTER BUAT MENGGAMBAR DONAT ASLI 100%
// ==========================================================
class _DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;
  final double strokeWidth;

  _DonutChartPainter({
    required this.values,
    required this.colors,
    this.strokeWidth = 35.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double total = values.fold(0, (sum, v) => sum + v);
    if (total == 0) return;

    double startAngle = -pi / 2;
    
    final rect = Rect.fromLTWH(
      strokeWidth / 2, 
      strokeWidth / 2, 
      size.width - strokeWidth, 
      size.height - strokeWidth
    );

    for (int i = 0; i < values.length; i++) {
      final sweepAngle = (values[i] / total) * 2 * pi;
      
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt; 

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}