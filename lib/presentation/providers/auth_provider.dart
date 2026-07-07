import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/env/env_config.dart';

/// Provider reaktif untuk menyimpan status login pengguna (true/false)
final isLoggedInProvider = StateProvider<bool>((ref) {
  if (EnvConfig.isSupabaseConfigured) {
    // Jika Supabase aktif, periksa apakah sesi user saat ini ada
    return Supabase.instance.client.auth.currentSession != null;
  }
  return false; // Default: belum login pada mode demo
});

/// Service class untuk mengelola alur login, registrasi, dan logout
class AuthService {
  final Ref _ref;

  AuthService(this._ref);

  /// Melakukan login akun
  Future<void> login(String email, String password) async {
    if (EnvConfig.isSupabaseConfigured) {
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } else {
      // Simulasi delay login mode demo
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    // Update status login menjadi true
    _ref.read(isLoggedInProvider.notifier).state = true;
  }

  /// Melakukan registrasi akun baru
  Future<void> register(String email, String password) async {
    if (EnvConfig.isSupabaseConfigured) {
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );
    } else {
      // Simulasi delay register mode demo
      await Future.delayed(const Duration(milliseconds: 1000));
    }
    // Update status login menjadi true
    _ref.read(isLoggedInProvider.notifier).state = true;
  }

  /// Mengeluarkan akun (logout)
  Future<void> logout() async {
    if (EnvConfig.isSupabaseConfigured) {
      await Supabase.instance.client.auth.signOut();
    }
    // Update status login menjadi false
    _ref.read(isLoggedInProvider.notifier).state = false;
  }
}

/// Provider global untuk instance [AuthService]
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref);
});
