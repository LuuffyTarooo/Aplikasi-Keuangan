// lib/providers/mixins/pin_mixin.dart
import 'package:flutter/foundation.dart';
import 'package:aplikasi_keuangan/core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mixin untuk mengelola PIN keamanan dan mekanisme lockout.
mixin PinMixin on ChangeNotifier {
  String _userPin = '';
  int _pinLockoutUntil = 0;

  String get userPin => _userPin;
  int get pinLockoutUntil => _pinLockoutUntil;

  /// Memuat PIN dari penyimpanan lokal.
  Future<void> loadPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userPin = prefs.getString(StorageKeys.userPin) ?? '';
    } catch (e) {
      debugPrint('⚠️ Gagal memuat PIN: $e');
    }
  }

  /// Memperbarui PIN pengguna. Kirim `null` untuk menonaktifkan PIN.
  Future<void> updateUserPin(String? newPin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (newPin == null) {
        _userPin = '';
        await prefs.remove(StorageKeys.userPin);
      } else {
        _userPin = newPin;
        await prefs.setString(StorageKeys.userPin, newPin);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Gagal memperbarui PIN: $e');
    }
  }

  /// Memuat data lockout. Jika waktu lockout sudah lewat, PIN direset otomatis.
  Future<void> loadLockout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pinLockoutUntil = prefs.getInt(StorageKeys.pinLockoutUntil) ?? 0;

      if (_pinLockoutUntil > 0 && DateTime.now().millisecondsSinceEpoch >= _pinLockoutUntil) {
        _userPin = '';
        _pinLockoutUntil = 0;
        await prefs.remove(StorageKeys.userPin);
        await prefs.remove(StorageKeys.pinLockoutUntil);
      }
    } catch (e) {
      debugPrint('⚠️ Gagal memuat lockout: $e');
    }
  }

  /// Mengaktifkan lockout 24 jam (untuk fitur "Lupa PIN").
  Future<void> startForgotPinLockout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _pinLockoutUntil = DateTime.now().millisecondsSinceEpoch + (24 * 60 * 60 * 1000);
      await prefs.setInt(StorageKeys.pinLockoutUntil, _pinLockoutUntil);
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Gagal mengaktifkan lockout: $e');
    }
  }

  /// Membersihkan lockout dan mereset PIN secara paksa.
  Future<void> clearLockoutAndResetPin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userPin = '';
      _pinLockoutUntil = 0;
      await prefs.remove(StorageKeys.userPin);
      await prefs.remove(StorageKeys.pinLockoutUntil);
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Gagal mereset PIN: $e');
    }
  }
}
