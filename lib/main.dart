import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Import core architecture components & presentation layout
import 'core/constants/app_theme.dart';
import 'core/env/env_config.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/login_register_screen.dart';
import 'presentation/screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi dotenv untuk mengambil environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Gagal memuat berkas .env: $e');
  }

  bool isSupabaseConfigured = false;

  // Inisialisasi Supabase secara aman menggunakan EnvConfig dari .env
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

  runApp(
    ProviderScope(
      child: MyApp(isSupabaseConfigured: isSupabaseConfigured),
    ),
  );
}

class MyApp extends ConsumerWidget {
  final bool isSupabaseConfigured;

  const MyApp({super.key, required this.isSupabaseConfigured});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Memantau status login reaktif dari auth_provider
    final isLoggedIn = ref.watch(isLoggedInProvider);

    return MaterialApp(
      title: 'KapanBasi?',
      debugShowCheckedModeBanner: false,
      
      // Menggunakan tema terpusat dari core/app_theme.dart (Tanpa Hardcode Warna)
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Menyesuaikan dengan pengaturan OS
      
      // Jika sudah login tampilkan MainLayout, jika belum tampilkan layar Login/Register
      home: isLoggedIn 
          ? MainLayout(isSupabaseConfigured: isSupabaseConfigured)
          : const LoginRegisterScreen(),
    );
  }
}
