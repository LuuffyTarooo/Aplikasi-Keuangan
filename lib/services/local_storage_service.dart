// lib/services/local_storage_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart'; // 🟢 Tambahan buat fungsi debugPrint
import 'package:shared_preferences/shared_preferences.dart';

/// 🛠️ CUSTOM SERVICE: LocalStorageService
/// Kelas sakti buat urusan sinkronisasi Data dengan memori internal HP.
/// Pengganti window.localStorage di React.
class LocalStorageService {
  
  // 1. Fungsi buat nyimpen data (Setara useEffect nyiram data)
  static Future<void> saveData(String key, dynamic value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Ubah list/map jadi teks JSON persis kayak JSON.stringify
      final jsonString = jsonEncode(value); 
      await prefs.setString(key, jsonString);
    } catch (error) {
      debugPrint('❌ Error simpan data $key ke SharedPreferences: $error'); // 🟢 Ganti print jadi debugPrint
    }
  }

  // 2. Fungsi buat ngambil data (Setara inisialisasi useState)
  static Future<dynamic> loadData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(key);
      
      // Ubah teks JSON balik jadi List/Map persis kayak JSON.parse
      if (jsonString != null) {
        return jsonDecode(jsonString); 
      }
      return null;
    } catch (error) {
      debugPrint('❌ Error ambil data $key dari SharedPreferences: $error'); // 🟢 Ganti print jadi debugPrint
      return null;
    }
  }

  // 3. Fungsi buat ngehapus data (Berguna buat fitur Reset Data Akun)
  static Future<void> removeData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (error) {
      debugPrint('❌ Error hapus data $key: $error'); // 🟢 Ganti print jadi debugPrint
    }
  }
}