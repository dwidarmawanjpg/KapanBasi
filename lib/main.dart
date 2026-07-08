import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/constants/app_theme.dart';
import 'core/env/env_config.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'data/services/notification_service.dart';
import 'presentation/screens/login_register_screen.dart';
import 'presentation/screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Gagal memuat berkas .env: $e');
  }

  bool isSupabaseConfigured = false;

  if (EnvConfig.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: EnvConfig.supabaseUrl,
        publishableKey: EnvConfig.supabaseAnonKey,
      );
      isSupabaseConfigured = true;
    } catch (e) {
      debugPrint('Gagal menginisialisasi Supabase: $e');
    }
  }

  // Muat preferensi pengguna (tema, pengingat) dari penyimpanan lokal
  final settings = await AppSettingsSnapshot.load();

  // Inisialisasi plugin notifikasi & zona waktu perangkat
  await NotificationService().initialize();

  // Jadwalkan pengingat harian jika sudah diaktifkan sebelumnya
  if (settings.reminderEnabled) {
    await NotificationService().requestPermissions();
    await NotificationService().scheduleDailyReminder(
      hour: settings.reminderTime.hour,
      minute: settings.reminderTime.minute,
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        themeModeProvider.overrideWith((ref) => settings.themeMode),
        reminderEnabledProvider.overrideWith((ref) => settings.reminderEnabled),
        reminderTimeProvider.overrideWith((ref) => settings.reminderTime),
      ],
      child: MyApp(isSupabaseConfigured: isSupabaseConfigured),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final bool isSupabaseConfigured;
  const MyApp({super.key, required this.isSupabaseConfigured});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoggedIn = ref.watch(isLoggedInProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'KapanBasi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: isLoggedIn
          ? MainLayout(isSupabaseConfigured: isSupabaseConfigured)
          : const LoginRegisterScreen(),
    );
  }
}
