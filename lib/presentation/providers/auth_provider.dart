import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/env/env_config.dart';
import 'foods_provider.dart';

/// Provider reaktif untuk menyimpan status login pengguna (true/false)
final StateProvider<bool> isLoggedInProvider = StateProvider<bool>((ref) {
  if (EnvConfig.isSupabaseConfigured) {
    final client = Supabase.instance.client;

    // Dengarkan perubahan status auth dari Supabase secara reaktif
    final subscription = client.auth.onAuthStateChange.listen((data) {
      ref.read(isLoggedInProvider.notifier).state = data.session != null;

      // PENTING: Bersihkan cache provider yang menyimpan data milik pengguna
      // (profil, daftar makanan) setiap kali ada pergantian sesi (login/register/
      // logout). Tanpa ini, FutureProvider akan tetap menampilkan data pengguna
      // SEBELUMNYA yang sudah ter-cache, sehingga pengguna baru bisa "melihat"
      // akun/data milik pengguna lain di sesi yang sama.
      if (data.event == AuthChangeEvent.signedIn ||
          data.event == AuthChangeEvent.signedOut ||
          data.event == AuthChangeEvent.initialSession) {
        // Menggunakan ref.refresh() memastikan data diambil ulang dengan sesi
        // yang baru meskipun UI (ProfileScreen) sedang tidak aktif di layar.
        // Jika kita hanya invalidate(), cache memang terhapus, tapi refetch
        // tertunda sampai ProfileScreen dibuka, dan bisa nyangkut status lamanya.
        ref.refresh(userProfileProvider.future).ignore();
        ref.refresh(foodsProvider.future).ignore();
        ref.refresh(collectionFoodsProvider.future).ignore();
      }
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

  /// Melakukan registrasi akun baru.
  /// Mengembalikan `true` jika akun langsung memiliki sesi aktif (auto-login),
  /// atau `false` jika akun berhasil dibuat namun masih menunggu konfirmasi
  /// email (belum ada sesi valid, sehingga pengguna TIDAK boleh diarahkan
  /// langsung ke halaman utama).
  Future<bool> register(String email, String password, String fullName) async {
    if (EnvConfig.isSupabaseConfigured) {
      final client = Supabase.instance.client;

      // Pastikan tidak ada sesi akun lain yang masih aktif sebelum mendaftar.
      // Jika dibiarkan, Supabase tidak akan mengganti sesi lama dengan sesi
      // akun baru ketika email konfirmasi masih diperlukan, sehingga aplikasi
      // bisa tampak "login" ke akun yang salah (akun lama yang belum logout).
      if (client.auth.currentSession != null) {
        await client.auth.signOut();
      }

      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );

      if (response.user == null) {
        throw Exception('Gagal membuat akun. Silakan coba lagi.');
      }

      // Jika project mewajibkan konfirmasi email, signUp tidak menghasilkan
      // sesi aktif. Jangan paksa status login menjadi true di sini karena
      // belum ada sesi valid untuk akun yang baru dibuat.
      if (response.session == null) {
        return false;
      }
    } else {
      // Simulasi delay register mode demo
      await Future.delayed(const Duration(milliseconds: 1000));
    }

    // Update status login menjadi true hanya jika sesi baru benar-benar ada
    _ref.read(isLoggedInProvider.notifier).state = true;
    return true;
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
