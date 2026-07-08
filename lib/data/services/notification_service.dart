import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../models/food_model.dart';

/// Service terpusat untuk mengelola notifikasi lokal (pengingat) KapanBasi.
///
/// Aplikasi ini belum memiliki infrastruktur push notification di server,
/// sehingga seluruh pengingat dijadwalkan secara lokal di perangkat pengguna
/// menggunakan `flutter_local_notifications`. Ada dua jenis notifikasi:
///
/// 1. **Pengingat harian (umum)** — dijadwalkan berulang setiap hari pada jam
///    yang dipilih pengguna. Isinya diperbarui (di-reschedule) setiap kali
///    daftar bahan makanan disinkronkan agar tetap relevan dengan kondisi
///    pantry terakhir yang diketahui aplikasi.
/// 2. **Notifikasi kedaluwarsa per-item** — dijadwalkan otomatis untuk setiap
///    bahan makanan pada pagi hari tanggal kedaluwarsanya, dan dibatalkan
///    otomatis saat item tersebut dihapus atau ditandai selesai.
class NotificationService {
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// ID tetap untuk notifikasi pengingat harian (hanya ada 1 instance aktif).
  static const int dailyReminderNotificationId = 0;

  static const AndroidNotificationDetails _dailyAndroidDetails =
      AndroidNotificationDetails(
        'daily_reminder_channel',
        'Pengingat Harian',
        channelDescription:
            'Pengingat rutin untuk memeriksa kondisi pantry KapanBasi',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

  static const AndroidNotificationDetails _expiryAndroidDetails =
      AndroidNotificationDetails(
        'food_expiry_channel',
        'Peringatan Kedaluwarsa',
        channelDescription:
            'Notifikasi saat bahan makanan mencapai tanggal kedaluwarsa',
        importance: Importance.high,
        priority: Priority.high,
      );

  static const DarwinNotificationDetails _iosDetails =
      DarwinNotificationDetails();

  /// Inisialisasi plugin & zona waktu perangkat. Wajib dipanggil sekali di awal (main()).
  Future<void> initialize() async {
    if (_isInitialized) return;

    tz_data.initializeTimeZones();
    try {
      final currentTimeZone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(currentTimeZone.identifier));
    } catch (e) {
      debugPrint('Gagal mendeteksi zona waktu perangkat, fallback ke UTC: $e');
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
        macOS: iosSettings,
      ),
    );

    _isInitialized = true;
  }

  /// Meminta izin notifikasi ke pengguna. Wajib untuk Android 13+ dan iOS/macOS.
  Future<bool> requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    }
    if (Platform.isAndroid) {
      final result = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return result ?? false;
    }
    return true;
  }

  /// Menjadwalkan/memperbarui pengingat harian pada jam [hour]:[minute].
  /// Konten pesan disesuaikan dengan jumlah barang kritis/basi saat ini
  /// ([expiredCount]/[urgentCount]) agar tetap relevan setiap kali disinkronkan.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    int expiredCount = 0,
    int urgentCount = 0,
  }) async {
    if (!_isInitialized) return;

    final String body;
    if (expiredCount > 0 && urgentCount > 0) {
      body =
          'Ada $expiredCount barang sudah basi dan $urgentCount barang mendekati kedaluwarsa. Yuk cek pantry-mu!';
    } else if (expiredCount > 0) {
      body =
          'Ada $expiredCount barang di pantry-mu yang sudah basi. Segera cek dan bersihkan, ya!';
    } else if (urgentCount > 0) {
      body =
          'Ada $urgentCount barang yang mendekati tanggal kedaluwarsa. Yuk cek pantry-mu!';
    } else {
      body =
          'Jangan lupa cek pantry-mu hari ini supaya tidak ada bahan makanan yang terlewat.';
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id: dailyReminderNotificationId,
      title: 'KapanBasi Ingatkan Kamu!',
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: _dailyAndroidDetails,
        iOS: _iosDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Membatalkan pengingat harian (misalnya saat pengguna menonaktifkannya).
  Future<void> cancelDailyReminder() async {
    await _plugin.cancel(id: dailyReminderNotificationId);
  }

  /// Menjadwalkan notifikasi kedaluwarsa untuk satu bahan makanan pada pukul
  /// [hour]:[minute] di tanggal kedaluwarsanya. Tidak berlaku jika tanggal
  /// kedaluwarsa sudah lewat atau item sudah ditandai selesai.
  Future<void> scheduleFoodExpiryNotification(
    FoodModel food, {
    int hour = 8,
    int minute = 0,
  }) async {
    if (!_isInitialized || food.isConsumed) return;

    final now = tz.TZDateTime.now(tz.local);
    final expiry = food.expiryDate;
    var scheduledDate = tz.TZDateTime(
      tz.local,
      expiry.year,
      expiry.month,
      expiry.day,
      hour,
      minute,
    );

    // Jangan jadwalkan notifikasi untuk waktu yang sudah lewat.
    if (scheduledDate.isBefore(now)) return;

    await _plugin.zonedSchedule(
      id: _notificationIdFromFoodId(food.id),
      title: 'Sudah Waktunya! 🍽️',
      body:
          '"${food.name}" mencapai tanggal kedaluwarsa hari ini. Segera cek kondisinya!',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: _expiryAndroidDetails,
        iOS: _iosDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Membatalkan notifikasi kedaluwarsa milik satu bahan makanan (misalnya
  /// saat item dihapus atau ditandai selesai dikonsumsi).
  Future<void> cancelFoodExpiryNotification(String foodId) async {
    await _plugin.cancel(id: _notificationIdFromFoodId(foodId));
  }

  /// Menghasilkan ID notifikasi (int32 positif) yang stabil dari UUID bahan makanan.
  int _notificationIdFromFoodId(String foodId) {
    return foodId.hashCode & 0x7FFFFFFF;
  }
}
