import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Konfigurasi Environment & Kredensial API pihak ketiga (Supabase, dll).
/// Membaca parameter yang dideklarasikan di dalam file .env.
class EnvConfig {
  EnvConfig._();

  /// URL Supabase untuk instance backend.
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  /// Anon Key Supabase untuk autentikasi client-side.
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  /// URL Backend kustom.
  static String get backendUrl => dotenv.env['BACKEND_URL'] ?? 'http://localhost:5000';

  /// Menentukan apakah Supabase telah dikonfigurasi dengan benar.
  static bool get isSupabaseConfigured {
    return supabaseUrl.isNotEmpty && 
           supabaseUrl.startsWith('http') && 
           supabaseAnonKey.isNotEmpty;
  }
}
