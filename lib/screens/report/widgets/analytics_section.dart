// lib/screens/report/widgets/analytics_section.dart
import 'dart:math'; 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:aplikasi_keuangan/providers/finance_provider.dart';
import 'package:aplikasi_keuangan/providers/mixins/report_mixin.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';
import 'package:aplikasi_keuangan/shared/widgets/toggle_button_group.dart';

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
  String _trendFilter = 'Daily';
  int? _selectedBarIndex;

  @override
  void didUpdateWidget(AnalyticsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentDate != widget.currentDate) {
      _selectedBarIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final finance = Provider.of<FinanceProvider>(context);
    
    // 🟢 AUTO-SYNC: Bikin daftar warna Donut Chart dinamis! 
    final List<Color> donutColors = [
      finance.themeAccent,     
      const Color(0xFF3B82F6), // Biru
      const Color(0xFFF59E0B), // Oranye
      const Color(0xFFEC4899), // Pink
      const Color(0xFF8B5CF6), // Ungu
      const Color(0xFF10B981), // Emerald
      const Color(0xFFEF4444), // Merah
      const Color(0xFF06B6D4), // Cyan
    ];

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
                    color: isActive ? finance.themeAccent : finance.themeCard,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: isActive ? finance.themeAccent : finance.themeBorder),
                    boxShadow: isActive ? [BoxShadow(color: finance.themeAccent.withValues(alpha:0.3), blurRadius: 15)] : null,
                  ),
                  child: Text(
                    tab,
                    style: TextStyle(
                      color: isActive ? Colors.white : finance.themeTextSub,
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

        FutureBuilder<AnalyticsReportData>(
          future: finance.getAnalyticsStatsAsync(
            transaksi: widget.transaksi,
            year: widget.currentDate.year,
            month: widget.currentDate.month,
            analysisMode: _analysisMode,
            trendFilter: _trendFilter,
            selectedBarIndex: _selectedBarIndex,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Padding(
                padding: EdgeInsets.all(40.0),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final data = snapshot.data!;
            if (!data.hasModeTransactions) {
              return Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: finance.themeBorder)),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.pie_chart_outline_rounded, size: 48, color: finance.themeTextSub.withValues(alpha:0.3)),
                      const SizedBox(height: 12),
                      Text("BELUM ADA DATA", style: TextStyle(color: finance.themeTextSub, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 2)),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                _buildBarChart(data, finance),
                const SizedBox(height: 16),
                _buildDonutChart(data, finance, donutColors),
              ],
            );
          },
        ),
      ],
    );
  }

  // ====================================================
  // ⚡ 1. WIDGET BAR CHART (LOGIKA TREND)
  // ====================================================
  Widget _buildBarChart(AnalyticsReportData data, FinanceProvider finance) {
    final year = widget.currentDate.year;
    final month = widget.currentDate.month;
    final colorUtama = finance.themeAccent;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: finance.themeBorder)),
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
                    Text(_analysisMode == 'Pemasukan' ? 'Income Trend' : 'Expense Trend', style: TextStyle(color: finance.themeTextSub, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(
                      Formatters.formatCurrency(data.trendTotalAmount),
                      style: TextStyle(color: finance.themeText, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        GestureDetector(onTap: () => widget.onDateChange(DateTime(year, month - 1, 1)), child: Icon(Icons.chevron_left_rounded, color: finance.themeTextSub, size: 20)),
                        Text(_trendFilter == 'Monthly' ? 'TAHUN $year' : '${Formatters.monthNames[month - 1].toUpperCase()} $year', style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        GestureDetector(onTap: () => widget.onDateChange(DateTime(year, month + 1, 1)), child: Icon(Icons.chevron_right_rounded, color: finance.themeTextSub, size: 20)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: finance.themeBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: finance.themeBorder)),
                    child: ToggleButtonGroup(
                      options: const ['Daily', 'Weekly', 'Monthly'],
                      selected: _trendFilter,
                      onSelected: (val) {
                        setState(() {
                          _trendFilter = val;
                          _selectedBarIndex = null;
                        });
                      },
                    ),
                  ),
                  if (_selectedBarIndex != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: () { HapticFeedback.lightImpact(); setState(() => _selectedBarIndex = null); },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha:0.1), borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.redAccent.withValues(alpha:0.3))),
                          child: const Row(children: [Icon(Icons.close_rounded, color: Colors.redAccent, size: 10), SizedBox(width: 4), Text("Reset", style: TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold))]),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 220, 
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(5, (index) => Container(height: 1, width: constraints.maxWidth, color: finance.themeBorder)),
                    ),
                    ListView.builder(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: data.barData.length,
                      itemBuilder: (context, index) {
                        final point = data.barData[index];
                        double nominal = point.nominal;
                        String label = point.label;
                        double percent = (nominal / data.safeMax).clamp(0.0, 1.0);
                        bool isZero = nominal == 0;
                        bool isSelected = _selectedBarIndex == index;
                        bool isDimmed = _selectedBarIndex != null && _selectedBarIndex != index;
                        
                        // Menyesuaikan lebar item ListView
                        double itemWidth;
                        if (_trendFilter == 'Daily') {
                          itemWidth = 32.0; 
                        } else if (_trendFilter == 'Weekly') {
                          itemWidth = constraints.maxWidth / data.barData.length;
                        } else {
                          itemWidth = constraints.maxWidth / 6;
                        }

                        return SizedBox(
                          width: itemWidth,
                          child: GestureDetector(
                            onTap: () {
                              if (!isZero) {
                                HapticFeedback.lightImpact();
                                setState(() => _selectedBarIndex = _selectedBarIndex == index ? null : index);
                              }
                            },
                            child: Container(
                              color: Colors.transparent,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (isSelected && !isZero)
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Container(
                                        margin: const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: colorUtama.withValues(alpha:0.2), borderRadius: BorderRadius.circular(6), border: Border.all(color: colorUtama)),
                                        child: Text(Formatters.formatUangCompact(nominal), style: TextStyle(color: finance.themeText, fontSize: 9, fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    height: isZero ? 2 : (percent * 140),
                                    width: 16,
                                    margin: const EdgeInsets.only(bottom: 8),
                                    decoration: BoxDecoration(
                                      color: isZero ? finance.themeBorder : colorUtama,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                      boxShadow: isSelected ? [BoxShadow(color: colorUtama.withValues(alpha:0.6), blurRadius: 10)] : [],
                                    ),
                                    foregroundDecoration: BoxDecoration(color: isDimmed ? Colors.black.withValues(alpha:0.5) : Colors.transparent),
                                  ),
                                  Text(label, style: TextStyle(color: isSelected ? colorUtama : finance.themeTextSub, fontSize: 9, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  // ====================================================
  // ⚡ 2. WIDGET DONUT CHART & GRID (LOGIKA KATEGORI)
  // ====================================================
  Widget _buildDonutChart(AnalyticsReportData data, FinanceProvider finance, List<Color> donutColors) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(24), border: Border.all(color: finance.themeBorder)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_analysisMode == 'Pemasukan' ? 'Income Sources' : 'Expense Sources', style: TextStyle(color: finance.themeText, fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: finance.themeBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: finance.themeBorder)),
                child: Row(
                  children: [
                    Icon(Icons.chevron_left_rounded, size: 14, color: finance.themeTextSub),
                    const SizedBox(width: 4),
                    Text(data.periodLabel, style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    const SizedBox(width: 4),
                    Icon(Icons.chevron_right_rounded, size: 14, color: finance.themeTextSub),
                  ],
                ),
              ),
            ],
          ),
          
          if (data.chartData.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text("Tidak ada data untuk periode ini.", style: TextStyle(color: finance.themeTextSub, fontSize: 12, fontWeight: FontWeight.bold)),
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
                        values: data.chartValues,
                        colors: donutColors, 
                        strokeWidth: 35, 
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("TOTAL", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.formatUangCompact(data.sourceTotalAmount),
                        style: TextStyle(color: finance.themeText, fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                    ],
                  )
                ],
              ),
            ),

            LayoutBuilder(
              builder: (context, constraints) {
                double itemWidth = (constraints.maxWidth - 12) / 2;
                
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center, 
                  children: data.chartData.asMap().entries.map((entry) {
                    int idx = entry.key;
                    String catName = entry.value.name;
                    double nominal = entry.value.nominal;
                    double percent = data.sourceTotalAmount > 0 ? (nominal / data.sourceTotalAmount) * 100 : 0;
                    
                    Color catColor = donutColors[idx % donutColors.length];

                    return SizedBox(
                      width: itemWidth,
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _showCategoryDetailModal(catName, data.sourceTxs.where((t) => t.kategori == catName).toList(), finance);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: finance.themeBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: finance.themeBorder),
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
                                      style: TextStyle(color: finance.themeTextSub, fontSize: 11, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text("${percent.toStringAsFixed(0)}%", style: TextStyle(color: finance.themeTextSub, fontSize: 10)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                Formatters.formatCurrency(nominal), 
                                style: TextStyle(color: finance.themeText, fontSize: 13, fontWeight: FontWeight.bold)
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
  void _showCategoryDetailModal(String categoryName, List<TransactionModel> txs, FinanceProvider finance) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: finance.themeBg, borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), border: Border(top: BorderSide(color: finance.themeBorder))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(categoryName, style: TextStyle(color: finance.themeText, fontSize: 18, fontWeight: FontWeight.w900)),
              Text("Rincian Transaksi", style: TextStyle(color: finance.themeTextSub, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: txs.length,
                  itemBuilder: (context, index) {
                    final tx = txs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: finance.themeCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: finance.themeBorder)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tx.keterangan.isEmpty ? 'Tanpa Catatan' : tx.keterangan, style: TextStyle(color: finance.themeText, fontSize: 12, fontWeight: FontWeight.bold)),
                                Text(DateFormat('dd MMM yyyy').format(DateTime.parse(tx.tanggal)), style: TextStyle(color: finance.themeTextSub, fontSize: 10)),
                              ],
                            ),
                          ),
                          Text(Formatters.formatCurrency(tx.nominal), style: TextStyle(color: finance.themeAccent, fontSize: 14, fontWeight: FontWeight.w900)),
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