import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/env/env_config.dart';

/// Provider reaktif untuk menyimpan status login pengguna (true/false)
final StateProvider<bool> isLoggedInProvider = StateProvider<bool>((ref) {
  if (EnvConfig.isSupabaseConfigured) {
    final client = Supabase.instance.client;

    // Dengarkan perubahan status auth dari Supabase secara reaktif
    final subscription = client.auth.onAuthStateChange.listen((data) {
      ref.read(isLoggedInProvider.notifier).state = data.session != null;
    });

    ref.onDispose(() {
      subscription.cancel();
    });

    return client.auth.currentSession != null;
  }
  return false; // Default: belum login pada mode demo
});

/// Service class untuk mengelola alur login, registrasi, dan logout
class AuthService {
  final Ref _ref;

  AuthService(this._ref);

  /// Melakukan login akun melalui Backend API
  Future<void> login(String email, String password) async {
    if (EnvConfig.isSupabaseConfigured) {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        throw Exception(
          'Gagal masuk akun. Periksa kembali email dan password Anda.',
        );
      }
    } else {
      // Simulasi delay login mode demo
      await Future.delayed(const Duration(milliseconds: 1000));
      // Update status login secara manual khusus untuk mode demo
    }

    // Pastikan status login terupdate secara reaktif agar UI diarahkan ke halaman berikutnya
    _ref.read(isLoggedInProvider.notifier).state = true;
  }

  /// Melakukan registrasi akun baru
  Future<void> register(String email, String password, String fullName) async {
    if (EnvConfig.isSupabaseConfigured) {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.session == null && response.user == null) {
        throw Exception('Gagal membuat akun. Silakan coba lagi.');
      }
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
    // Update status login menjadi false secara manual (terutama untuk mode demo)
    _ref.read(isLoggedInProvider.notifier).state = false;
  }
}

/// Provider global untuk instance [AuthService]
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref);
});

/// FutureProvider reaktif untuk mengambil profil pengguna dari database
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  if (!EnvConfig.isSupabaseConfigured) {
    // Return mock user in demo mode
    return {
      'full_name': 'Abay (Demo)',
      'email': 'abay@kapanbasi.com',
      'avatar_url': null,
    };
  }

  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser != null) {
    return {
      'full_name':
          currentUser.userMetadata?['full_name'] ?? 'Pengguna KapanBasi',
      'email': currentUser.email ?? '',
      'avatar_url': currentUser.userMetadata?['avatar_url'],
    };
  }

  return null;
});
