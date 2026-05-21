// lib/utils/currency_manager.dart
import 'package:aplikasi_keuangan/models/currency_model.dart';
import 'package:aplikasi_keuangan/services/local_storage_service.dart';
import 'package:aplikasi_keuangan/core/constants/app_constants.dart';

class CurrencyManager {
  static final List<CurrencyModel> defaultCurrencies = [
    CurrencyModel(name: 'Indonesian Rupiah', code: 'IDR', symbol: 'Rp', exchangeRateToIdr: 1.0),
    CurrencyModel(name: 'US Dollar', code: 'USD', symbol: '\$', exchangeRateToIdr: 16200.0),
    CurrencyModel(name: 'Euro', code: 'EUR', symbol: '€', exchangeRateToIdr: 17500.0),
    CurrencyModel(name: 'Japanese Yen', code: 'JPY', symbol: '¥', exchangeRateToIdr: 105.0),
    CurrencyModel(name: 'British Pound', code: 'GBP', symbol: '£', exchangeRateToIdr: 20500.0),
    CurrencyModel(name: 'Indian Rupee', code: 'INR', symbol: '₹', exchangeRateToIdr: 195.0),
    CurrencyModel(name: 'Malaysian Ringgit', code: 'MYR', symbol: 'RM', exchangeRateToIdr: 3400.0),
  ];

  static Future<CurrencyModel> loadActiveCurrency() async {
    final data = await LocalStorageService.loadData(StorageKeys.activeCurrency);
    if (data != null && data is Map<String, dynamic>) {
      return CurrencyModel.fromJson(data);
    }
    return defaultCurrencies[0]; // Default IDR
  }

  static Future<void> saveActiveCurrency(CurrencyModel currency) async {
    await LocalStorageService.saveData(StorageKeys.activeCurrency, currency.toJson());
  }
}
