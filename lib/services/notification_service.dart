// lib/services/notification_service.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();
      
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings initializationSettingsDarwin = DarwinInitializationSettings(
        requestSoundPermission: false,
        requestBadgePermission: false,
        requestAlertPermission: false,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsDarwin,
      );

      await _flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
      );
      
      _isInitialized = true;
      debugPrint("✅ NotificationService initialized.");
    } catch (e) {
      debugPrint("⚠️ Failed to initialize notifications: $e");
    }
  }

  Future<bool> requestPermissions() async {
    try {
      bool? isGranted = false;
      if (defaultTargetPlatform == TargetPlatform.android) {
        isGranted = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        isGranted = await _flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            );
      }
      return isGranted ?? false;
    } catch (e) {
      debugPrint("⚠️ Failed to request notification permissions: $e");
      return false;
    }
  }

  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint("🔔 Cancelled all notifications");
    } catch (e) {
      debugPrint("⚠️ Failed to cancel all notifications: $e");
    }
  }

  /// Menjadwalkan notifikasi menggunakan zona waktu lokal OS.
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    try {
      final notificationDetails = const NotificationDetails(
        android: AndroidNotificationDetails(
          'routine_channel',
          'Pengingat Rutinitas',
          channelDescription: 'Notifikasi untuk jadwal tagihan rutinitas Anda.',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      // Jangan jadwalkan jika waktu sudah lewat
      if (scheduledDate.isBefore(DateTime.now())) return;

      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
      
      debugPrint("🔔 Scheduled notification ID $id for $scheduledDate");
    } catch (e) {
      debugPrint("⚠️ Failed to schedule notification: $e");
    }
  }

  /// Membatalkan notifikasi spesifik jika tidak dibutuhkan lagi
  Future<void> cancelNotification(int id) async {
    try {
      await _flutterLocalNotificationsPlugin.cancel(id: id);
    } catch (e) {
      debugPrint("⚠️ Failed to cancel notification: $e");
    }
  }
}
