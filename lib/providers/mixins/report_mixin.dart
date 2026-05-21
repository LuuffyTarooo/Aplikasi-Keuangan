// lib/providers/mixins/report_mixin.dart
import 'package:flutter/foundation.dart';
import 'package:aplikasi_keuangan/models/transaction_model.dart';
import 'package:aplikasi_keuangan/core/constants/app_constants.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';

// =======================================================
// 1. TOP-LEVEL FUNCTIONS UNTUK COMPUTE (ISOLATE)
// Harus di luar class, dan hanya menerima tipe primitif
// (Map/List/String/int/double) agar bisa melewati Isolate.
// =======================================================

/// Compute function untuk data Calendar (Daily/Weekly/Monthly stats)
Map<String, dynamic> _computeCalendarStats(Map<String, dynamic> args) {
  final List<TransactionModel> rawTxs = args['transaksi'] as List<TransactionModel>;
  final int year = args['year'];
  final int month = args['month'];

  final currentMonthTxs = rawTxs.where((t) {
    final txDate = DateTime.parse(t.tanggal);
    return txDate.month == month && txDate.year == year;
  }).toList();

  final currentYearTxs = rawTxs.where((t) {
    return DateTime.parse(t.tanggal).year == year;
  }).toList();

  // STATS HARIAN
  Map<int, Map<String, double>> dailyStats = {};
  for (var tx in currentMonthTxs) {
    int day = DateTime.parse(tx.tanggal).day;
    dailyStats.putIfAbsent(day, () => {'masuk': 0.0, 'keluar': 0.0});
    if (tx.jenis == TransactionTypes.income) {
      dailyStats[day]!['masuk'] =
          dailyStats[day]!['masuk']! + tx.nominal;
    }
    if (tx.jenis == TransactionTypes.expense) {
      dailyStats[day]!['keluar'] =
          dailyStats[day]!['keluar']! + tx.nominal;
    }
  }

  // STATS MINGGUAN (Dinamis)
  int daysInMonth = DateTime(year, month + 1, 0).day;
  int totalWeeks = (daysInMonth / 7).ceil();
  Map<int, Map<String, double>> weeklyStats = {};
  for (int w = 1; w <= totalWeeks; w++) {
    weeklyStats[w] = {'masuk': 0.0, 'keluar': 0.0};
  }
  for (var tx in currentMonthTxs) {
    int d = DateTime.parse(tx.tanggal).day;
    int weekIdx = ((d - 1) / 7).floor() + 1;
    if (weekIdx > totalWeeks) weekIdx = totalWeeks;
    if (tx.jenis == TransactionTypes.income) {
      weeklyStats[weekIdx]!['masuk'] =
          weeklyStats[weekIdx]!['masuk']! + tx.nominal;
    } else if (tx.jenis == TransactionTypes.expense) {
      weeklyStats[weekIdx]!['keluar'] =
          weeklyStats[weekIdx]!['keluar']! + tx.nominal;
    }
  }

  // STATS BULANAN
  Map<int, Map<String, double>> monthlyStats = {};
  for (int m = 1; m <= 12; m++) {
    monthlyStats[m] = {'masuk': 0.0, 'keluar': 0.0};
  }
  for (var tx in currentYearTxs) {
    int m = DateTime.parse(tx.tanggal).month;
    if (tx.jenis == TransactionTypes.income) {
      monthlyStats[m]!['masuk'] =
          monthlyStats[m]!['masuk']! + tx.nominal;
    }
    if (tx.jenis == TransactionTypes.expense) {
      monthlyStats[m]!['keluar'] =
          monthlyStats[m]!['keluar']! + tx.nominal;
    }
  }

  return {
    'dailyStats': dailyStats,
    'weeklyStats': weeklyStats,
    'monthlyStats': monthlyStats,
    'totalWeeks': totalWeeks,
  };
}

/// Compute function untuk data Analytics (BarChart + DonutChart)
Map<String, dynamic> _computeAnalyticsStats(Map<String, dynamic> args) {
  final List<TransactionModel> rawTxs = args['transaksi'] as List<TransactionModel>;
  final int year = args['year'];
  final int month = args['month'];
  final String analysisMode = args['analysisMode'];
  final String trendFilter = args['trendFilter'];
  final int? selectedBarIndex = args['selectedBarIndex'];

  final modeTxs = rawTxs.where((t) => t.jenis == analysisMode).toList();

  // 1. BAR CHART DATA
  final trendTxs = modeTxs.where((t) {
    final d = DateTime.parse(t.tanggal);
    if (trendFilter == 'Monthly') return d.year == year;
    return d.year == year && d.month == month;
  }).toList();

  double trendTotalAmount = trendTxs.fold(
    0.0,
    (sum, curr) => sum + curr.nominal,
  );
  int daysInMonth = DateTime(year, month + 1, 0).day;
  int totalWeeks = (daysInMonth / 7).ceil();

  List<Map<String, dynamic>> barData = [];
  if (trendFilter == 'Daily') {
    for (int i = 1; i <= daysInMonth; i++) {
      barData.add({'label': '$i', 'nominal': 0.0});
    }
    for (var tx in trendTxs) {
      int d = DateTime.parse(tx.tanggal).day;
      barData[d - 1]['nominal'] =
          (barData[d - 1]['nominal'] as double) + tx.nominal;
    }
  } else if (trendFilter == 'Weekly') {
    for (int i = 1; i <= totalWeeks; i++) {
      barData.add({'label': 'Wk $i', 'nominal': 0.0});
    }
    for (var tx in trendTxs) {
      int d = DateTime.parse(tx.tanggal).day;
      int weekIdx = ((d - 1) / 7).floor();
      if (weekIdx >= totalWeeks) weekIdx = totalWeeks - 1;
      barData[weekIdx]['nominal'] =
          (barData[weekIdx]['nominal'] as double) + tx.nominal;
    }
  } else if (trendFilter == 'Monthly') {
    for (int i = 0; i < 12; i++) {
      barData.add({
        'label': Formatters.monthNames[i].substring(0, 3),
        'nominal': 0.0,
      });
    }
    for (var tx in trendTxs) {
      int m = DateTime.parse(tx.tanggal).month;
      barData[m - 1]['nominal'] =
          (barData[m - 1]['nominal'] as double) + tx.nominal;
    }
  }

  double maxNominal = barData.fold(
    0.0,
    (max, item) =>
        (item['nominal'] as double) > max ? (item['nominal'] as double) : max,
  );
  double safeMax = maxNominal > 0 ? maxNominal : 1;

  // 2. DONUT CHART DATA
  List<TransactionModel> sourceTxs = [];
  String periodLabel = '';

  if (selectedBarIndex != null) {
    if (trendFilter == 'Daily') {
      int selectedDay = selectedBarIndex + 1;
      sourceTxs = modeTxs.where((t) {
        final d = DateTime.parse(t.tanggal);
        return d.year == year && d.month == month && d.day == selectedDay;
      }).toList();
      periodLabel =
          '$selectedDay ${Formatters.monthNames[month - 1].substring(0, 3).toUpperCase()} $year';
    } else if (trendFilter == 'Weekly') {
      sourceTxs = modeTxs.where((t) {
        final d = DateTime.parse(t.tanggal);
        int weekIdx = ((d.day - 1) / 7).floor();
        if (weekIdx >= totalWeeks) weekIdx = totalWeeks - 1;
        return d.year == year &&
            d.month == month &&
            weekIdx == selectedBarIndex;
      }).toList();
      periodLabel = 'MINGGU ${selectedBarIndex + 1}';
    } else if (trendFilter == 'Monthly') {
      sourceTxs = modeTxs.where((t) {
        final d = DateTime.parse(t.tanggal);
        return d.year == year && d.month == (selectedBarIndex + 1);
      }).toList();
      periodLabel =
          '${Formatters.monthNames[selectedBarIndex].toUpperCase()} $year';
    }
  } else {
    sourceTxs = modeTxs.where((t) {
      final d = DateTime.parse(t.tanggal);
      return d.year == year && d.month == month;
    }).toList();
    periodLabel = '${Formatters.monthNames[month - 1].toUpperCase()} $year';
  }

  double sourceTotalAmount = sourceTxs.fold(
    0.0,
    (sum, t) => sum + t.nominal,
  );
  Map<String, double> kategoriMap = {};
  for (var tx in sourceTxs) {
    String cat = tx.kategori.isEmpty ? 'Lain-lain' : tx.kategori;
    kategoriMap[cat] = (kategoriMap[cat] ?? 0) + tx.nominal;
  }

  // Konversi MapEntry ke Map biasa agar bisa melewati Isolate.
  final chartData = kategoriMap.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final chartDataSerialized = chartData
      .map((e) => {'key': e.key, 'value': e.value})
      .toList();
  final chartValues = chartData.map((e) => e.value).toList();

  return {
    'hasModeTransactions': modeTxs.isNotEmpty,
    'trendTotalAmount': trendTotalAmount,
    'barData': barData,
    'safeMax': safeMax,
    'sourceTxs': sourceTxs.map((t) => t.toJson()).toList(), // Safe transport
    'periodLabel': periodLabel,
    'sourceTotalAmount': sourceTotalAmount,
    'chartData': chartDataSerialized,
    'chartValues': chartValues,
  };
}

// =======================================================
// 2. DATA TRANSFER OBJECTS UNTUK WIDGET
// =======================================================

class CalendarReportData {
  final Map<int, Map<String, double>> dailyStats;
  final Map<int, Map<String, double>> weeklyStats;
  final Map<int, Map<String, double>> monthlyStats;
  final int totalWeeks;

  const CalendarReportData({
    required this.dailyStats,
    required this.weeklyStats,
    required this.monthlyStats,
    required this.totalWeeks,
  });

  factory CalendarReportData.fromMap(Map<String, dynamic> map) {
    return CalendarReportData(
      dailyStats: _decodeStats(map['dailyStats']),
      weeklyStats: _decodeStats(map['weeklyStats']),
      monthlyStats: _decodeStats(map['monthlyStats']),
      totalWeeks: map['totalWeeks'] as int,
    );
  }

  static Map<int, Map<String, double>> _decodeStats(Object? raw) {
    final rawMap = Map<dynamic, dynamic>.from(raw as Map);
    return rawMap.map((key, value) {
      final stats = Map<dynamic, dynamic>.from(value as Map);
      return MapEntry(
        key is int ? key : int.parse(key.toString()),
        stats.map((statKey, statValue) {
          return MapEntry(statKey.toString(), (statValue as num).toDouble());
        }),
      );
    });
  }
}

class BarChartPoint {
  final String label;
  final double nominal;

  const BarChartPoint({required this.label, required this.nominal});

  factory BarChartPoint.fromMap(Map<String, dynamic> map) {
    return BarChartPoint(
      label: map['label'] as String,
      nominal: (map['nominal'] as num).toDouble(),
    );
  }
}

class CategoryChartPoint {
  final String name;
  final double nominal;

  const CategoryChartPoint({required this.name, required this.nominal});

  factory CategoryChartPoint.fromMap(Map<String, dynamic> map) {
    return CategoryChartPoint(
      name: map['key'] as String,
      nominal: (map['value'] as num).toDouble(),
    );
  }
}

class AnalyticsReportData {
  final bool hasModeTransactions;
  final double trendTotalAmount;
  final List<BarChartPoint> barData;
  final double safeMax;
  final List<TransactionModel> sourceTxs;
  final String periodLabel;
  final double sourceTotalAmount;
  final List<CategoryChartPoint> chartData;
  final List<double> chartValues;

  const AnalyticsReportData({
    required this.hasModeTransactions,
    required this.trendTotalAmount,
    required this.barData,
    required this.safeMax,
    required this.sourceTxs,
    required this.periodLabel,
    required this.sourceTotalAmount,
    required this.chartData,
    required this.chartValues,
  });

  factory AnalyticsReportData.fromMap(Map<String, dynamic> map) {
    return AnalyticsReportData(
      hasModeTransactions: map['hasModeTransactions'] as bool,
      trendTotalAmount: (map['trendTotalAmount'] as num).toDouble(),
      barData: (map['barData'] as List)
          .map(
            (item) =>
                BarChartPoint.fromMap(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
      safeMax: (map['safeMax'] as num).toDouble(),
      sourceTxs: (map['sourceTxs'] as List)
          .map(
            (item) => TransactionModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      periodLabel: map['periodLabel'] as String,
      sourceTotalAmount: (map['sourceTotalAmount'] as num).toDouble(),
      chartData: (map['chartData'] as List)
          .map(
            (item) => CategoryChartPoint.fromMap(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      chartValues: (map['chartValues'] as List)
          .map((item) => (item as num).toDouble())
          .toList(),
    );
  }
}

// =======================================================
// 3. MIXIN KELAS UTAMA
// =======================================================

mixin ReportMixin on ChangeNotifier {
  /// In-memory cache: navigasi bulan yang pernah dikunjungi = 0 ms (Zero-Jank)
  final Map<String, Object> _reportCache = {};

  /// Bersihkan cache saat ada transaksi baru (dipanggil dari TransactionMixin)
  void clearReportCache() {
    _reportCache.clear();
  }

  /// Hitung jumlah minggu dinamis untuk bulan tertentu
  int getWeeksInMonth(int year, int month) {
    int daysInMonth = DateTime(year, month + 1, 0).day;
    return (daysInMonth / 7).ceil();
  }

  bool isCalendarCached({
    required int txCount,
    required int year,
    required int month,
  }) {
    String cacheKey = 'cal_${year}_${month}_$txCount';
    return _reportCache.containsKey(cacheKey);
  }

  /// Kalkulasi Calendar Stats via Isolate + Cache
  Future<CalendarReportData> getCalendarStatsAsync({
    required List<TransactionModel> transaksi,
    required int year,
    required int month,
  }) async {
    String cacheKey = 'cal_${year}_${month}_${transaksi.length}';
    if (_reportCache.containsKey(cacheKey)) {
      return _reportCache[cacheKey] as CalendarReportData; // Instan dari cache!
    }

    // Pass directly, no toJson overhead!
    final rawResult = await compute(_computeCalendarStats, {
      'transaksi': transaksi,
      'year': year,
      'month': month,
    });
    final result = CalendarReportData.fromMap(rawResult);

    _reportCache[cacheKey] = result;
    return result;
  }

  bool isAnalyticsCached({
    required int txCount,
    required int year,
    required int month,
    required String analysisMode,
    required String trendFilter,
    int? selectedBarIndex,
  }) {
    String cacheKey = 'ana_${year}_${month}_${analysisMode}_${trendFilter}_${selectedBarIndex}_$txCount';
    return _reportCache.containsKey(cacheKey);
  }

  /// Kalkulasi Analytics Stats via Isolate + Cache
  Future<AnalyticsReportData> getAnalyticsStatsAsync({
    required List<TransactionModel> transaksi,
    required int year,
    required int month,
    required String analysisMode,
    required String trendFilter,
    int? selectedBarIndex,
  }) async {
    String cacheKey =
        'ana_${year}_${month}_${analysisMode}_${trendFilter}_${selectedBarIndex}_${transaksi.length}';
    if (_reportCache.containsKey(cacheKey)) {
      return _reportCache[cacheKey]
          as AnalyticsReportData; // Instan dari cache!
    }

    // Pass directly, no toJson overhead!
    final rawResult = await compute(_computeAnalyticsStats, {
      'transaksi': transaksi,
      'year': year,
      'month': month,
      'analysisMode': analysisMode,
      'trendFilter': trendFilter,
      'selectedBarIndex': selectedBarIndex,
    });
    final result = AnalyticsReportData.fromMap(rawResult);

    _reportCache[cacheKey] = result;
    return result;
  }
}
