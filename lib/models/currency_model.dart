// lib/models/currency_model.dart

class CurrencyModel {
  final String name;
  final String code;
  final String symbol;
  final double exchangeRateToIdr;

  CurrencyModel({
    required this.name,
    required this.code,
    required this.symbol,
    required this.exchangeRateToIdr,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'code': code,
      'symbol': symbol,
      'exchangeRateToIdr': exchangeRateToIdr,
    };
  }

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    return CurrencyModel(
      name: json['name'] ?? 'Indonesian Rupiah',
      code: json['code'] ?? 'IDR',
      symbol: json['symbol'] ?? 'Rp',
      exchangeRateToIdr: (json['exchangeRateToIdr'] ?? 1.0).toDouble(),
    );
  }
}
