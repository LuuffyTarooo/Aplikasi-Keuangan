// lib/providers/mixins/reminder_mixin.dart
import 'package:flutter/foundation.dart';
import 'package:aplikasi_keuangan/models/reminder_model.dart';
import 'package:aplikasi_keuangan/models/user_model.dart';
import 'package:aplikasi_keuangan/core/utils/formatters.dart';
import 'package:aplikasi_keuangan/services/notification_service.dart';
import 'package:aplikasi_keuangan/services/local_storage_service.dart';
import 'package:aplikasi_keuangan/core/constants/app_constants.dart';

/// Mixin untuk mengelola fitur pengingat tagihan/jadwal.
mixin ReminderMixin on ChangeNotifier {
  List<ReminderModel> get allReminders;
  set allReminders(List<ReminderModel> val);
  UserModel? get currentUser;
  void syncToStorage();

  /// Menambahkan pengingat baru, lalu mengurutkan berdasarkan tanggal jatuh tempo.
  void addReminder(ReminderModel r) {
    try {
      allReminders.add(r);
      allReminders.sort((a, b) => DateTime.parse(a.dueDate).compareTo(DateTime.parse(b.dueDate)));
      syncToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Gagal menambah pengingat: $e');
    }
  }

  /// Menandai pengingat sebagai selesai. Jika berulang, buat pengingat bulan berikutnya.
  void payReminder(String id, bool isRecurring, DateTime nextMonth) {
    try {
      final user = currentUser;
      if (user == null) return;

      final index = allReminders.indexWhere((r) => r.id == id);
      if (index != -1) {
        allReminders[index].isDone = true;
        if (isRecurring) {
          allReminders.add(ReminderModel(
            id: 'rem_${DateTime.now().millisecondsSinceEpoch}',
            title: allReminders[index].title,
            kategori: allReminders[index].kategori,
            nominal: allReminders[index].nominal,
            dueDate: nextMonth.toIso8601String(),
            userId: user.id,
          ));
          allReminders.sort((a, b) => DateTime.parse(a.dueDate).compareTo(DateTime.parse(b.dueDate)));
        }
        syncToStorage();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Gagal memproses pengingat: $e');
    }
  }

  /// Menghapus pengingat berdasarkan ID.
  void deleteReminder(String id) {
    try {
      allReminders.removeWhere((r) => r.id == id);
      syncToStorage();
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Gagal menghapus pengingat: $e');
    }
  }

  bool _isNotificationEnabled = true;
  bool get isNotificationEnabled => _isNotificationEnabled;

  Future<void> loadNotificationPreferences() async {
    try {
      final val = await LocalStorageService.loadData(StorageKeys.isNotificationsEnabled);
      if (val != null && val is bool) {
        _isNotificationEnabled = val;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Gagal load preferensi notifikasi: $e');
    }
  }

  Future<void> toggleNotification(bool val) async {
    try {
      if (val) {
        final hasPermission = await NotificationService().requestPermissions();
        if (!hasPermission) {
          _isNotificationEnabled = false;
        } else {
          _isNotificationEnabled = true;
        }
      } else {
        _isNotificationEnabled = false;
      }

      await LocalStorageService.saveData(StorageKeys.isNotificationsEnabled, _isNotificationEnabled);

      if (_isNotificationEnabled) {
        await checkAndScheduleNotifications();
      } else {
        await NotificationService().cancelAllNotifications();
        for (var r in allReminders) {
          r.lastNotifiedPhase = null;
        }
        syncToStorage();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ Gagal toggle notifikasi: $e');
    }
  }

  /// Mengecek seluruh rutinitas dan mendaftarkan jadwal ke OS menggunakan NotificationService.
  Future<void> checkAndScheduleNotifications() async {
    if (!_isNotificationEnabled) return;

    bool hasChanges = false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var r in allReminders) {
      if (r.isDone) continue;

      final due = DateTime.parse(r.dueDate);
      final dueDateOnly = DateTime(due.year, due.month, due.day);
      final difference = dueDateOnly.difference(today).inDays;
      
      String targetPhase = '';
      DateTime scheduleTime;
      
      if (difference == 3) {
        targetPhase = 'H-3';
        scheduleTime = due.subtract(const Duration(days: 3));
      } else if (difference == 1) {
        targetPhase = 'H-1';
        scheduleTime = due.subtract(const Duration(days: 1));
      } else if (difference == 0) {
        targetPhase = 'H-0';
        scheduleTime = due;
      } else if (difference < 0) {
        targetPhase = 'OVERDUE';
        scheduleTime = now.add(const Duration(seconds: 10)); // Segera kirim kalau terlewat
      } else {
        continue; // Belum masuk window H-3
      }

      // Pastikan jam pengiriman logis (misal jam 09:00 pagi jika waktunya jam 00:00)
      if (scheduleTime.hour == 0) {
        scheduleTime = DateTime(scheduleTime.year, scheduleTime.month, scheduleTime.day, 9, 0);
      }
      
      // Jika waktu sudah lewat hari ini, jalankan dalam 10 detik dari sekarang 
      if (scheduleTime.isBefore(now)) {
        scheduleTime = now.add(const Duration(seconds: 10));
      }

      // Cek apakah fase ini belum dinotifikasi sebelumnya
      if (r.lastNotifiedPhase != targetPhase) {
        r.lastNotifiedPhase = targetPhase;
        hasChanges = true;

        final notifId = r.id.hashCode;
        final title = 'Jatuh Tempo: ${r.title}';
        final body = 'Jangan lupa bayar ${Formatters.formatCurrency(r.nominal)} hari ini!';

        await NotificationService().scheduleNotification(
          id: notifId,
          title: title,
          body: body,
          scheduledDate: scheduleTime,
        );
      }
    }

    if (hasChanges) {
      syncToStorage();
    }
  }
}
