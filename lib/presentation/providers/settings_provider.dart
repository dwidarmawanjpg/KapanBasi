import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/food_model.dart';
import '../../data/services/notification_service.dart';

/// Kunci penyimpanan preferensi lokal pengguna di [SharedPreferences].
class _PrefKeys {
  static const themeMode = 'settings_theme_mode'; // 'system' | 'light' | 'dark'
  static const reminderEnabled = 'settings_reminder_enabled';
  static const reminderHour = 'settings_reminder_hour';
  static const reminderMinute = 'settings_reminder_minute';
}

/// Kumpulan preferensi yang dimuat sekali dari SharedPreferences sebelum `runApp()`
/// dipanggil, lalu dipakai untuk mengisi nilai awal provider di bawah melalui
/// `ProviderScope(overrides: ...)` pada `main.dart`.
class AppSettingsSnapshot {
  final ThemeMode themeMode;
  final bool reminderEnabled;
  final TimeOfDay reminderTime;

  const AppSettingsSnapshot({
    required this.themeMode,
    required this.reminderEnabled,
    required this.reminderTime,
  });

  static Future<AppSettingsSnapshot> load() async {
    final prefs = await SharedPreferences.getInstance();

    final themeMode = switch (prefs.getString(_PrefKeys.themeMode)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final reminderEnabled = prefs.getBool(_PrefKeys.reminderEnabled) ?? true;
    final hour = prefs.getInt(_PrefKeys.reminderHour) ?? 8;
    final minute = prefs.getInt(_PrefKeys.reminderMinute) ?? 0;

    return AppSettingsSnapshot(
      themeMode: themeMode,
      reminderEnabled: reminderEnabled,
      reminderTime: TimeOfDay(hour: hour, minute: minute),
    );
  }
}

/// Status tema aplikasi aktif. Nilai awal di-override dari SharedPreferences di `main.dart`.
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

/// Status aktif/nonaktif pengingat harian.
final reminderEnabledProvider = StateProvider<bool>((ref) => true);

/// Jam pengingat harian dijadwalkan.
final reminderTimeProvider = StateProvider<TimeOfDay>(
  (ref) => const TimeOfDay(hour: 8, minute: 0),
);

/// Service yang menggabungkan perubahan preferensi pengguna dengan proses
/// penyimpanan (SharedPreferences) dan penjadwalan ulang notifikasi terkait,
/// sehingga UI cukup memanggil satu method tanpa mengurus detail persistensinya.
class SettingsService {
  final Ref _ref;
  SettingsService(this._ref);

  /// Mengganti tema aplikasi (Terang/Gelap/Ikuti Sistem) dan menyimpannya secara permanen.
  Future<void> setThemeMode(ThemeMode mode) async {
    _ref.read(themeModeProvider.notifier).state = mode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_PrefKeys.themeMode, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

  /// Mengaktifkan/menonaktifkan pengingat harian pada jam tertentu, sekaligus
  /// menjadwalkan ulang (atau membatalkan) notifikasi lokal terkait.
  /// [foods] dipakai untuk merangkum kondisi pantry terkini di isi notifikasi.
  Future<void> setDailyReminder({
    required bool enabled,
    required TimeOfDay time,
    List<FoodModel> foods = const [],
  }) async {
    _ref.read(reminderEnabledProvider.notifier).state = enabled;
    _ref.read(reminderTimeProvider.notifier).state = time;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_PrefKeys.reminderEnabled, enabled);
    await prefs.setInt(_PrefKeys.reminderHour, time.hour);
    await prefs.setInt(_PrefKeys.reminderMinute, time.minute);

    final notificationService = NotificationService();
    if (enabled) {
      await notificationService.requestPermissions();
      final (expired, urgent) = _computeCounts(foods);
      await notificationService.scheduleDailyReminder(
        hour: time.hour,
        minute: time.minute,
        expiredCount: expired,
        urgentCount: urgent,
      );
    } else {
      await notificationService.cancelDailyReminder();
    }
  }

  /// Dipanggil setiap kali daftar bahan makanan berhasil disinkronkan (lihat
  /// `foodsProvider`) agar isi pengingat harian tetap relevan dengan kondisi
  /// pantry terkini, tanpa perlu pengguna membuka halaman pengaturan lagi.
  Future<void> refreshDailyReminderContent(List<FoodModel> foods) async {
    final enabled = _ref.read(reminderEnabledProvider);
    if (!enabled) return;

    final time = _ref.read(reminderTimeProvider);
    final (expired, urgent) = _computeCounts(foods);

    await NotificationService().scheduleDailyReminder(
      hour: time.hour,
      minute: time.minute,
      expiredCount: expired,
      urgentCount: urgent,
    );
  }

  (int, int) _computeCounts(List<FoodModel> foods) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int expired = 0;
    int urgent = 0;
    for (final food in foods) {
      if (food.isConsumed) continue;
      final expiry = DateTime(
        food.expiryDate.year,
        food.expiryDate.month,
        food.expiryDate.day,
      );
      final diff = expiry.difference(today).inDays;
      if (diff < 0) {
        expired++;
      } else if (diff <= 3) {
        urgent++;
      }
    }
    return (expired, urgent);
  }
}

final settingsServiceProvider = Provider<SettingsService>(
  (ref) => SettingsService(ref),
);
