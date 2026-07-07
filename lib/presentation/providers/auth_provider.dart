import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:http/http.dart' as http;
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
      final response = await http.post(
        Uri.parse('${EnvConfig.backendUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Gagal masuk akun ke server backend.');
      }

      final data = jsonDecode(response.body);
      final session = data['session'];

      if (session != null) {
        final refreshToken = session['refresh_token'] as String?;
        final accessToken = session['access_token'] as String?;
        if (refreshToken != null && accessToken != null) {
          // Set session lokal menggunakan refresh_token dan access_token agar SDK Supabase sinkron
          await Supabase.instance.client.auth.setSession(
            refreshToken,
            accessToken: accessToken,
          );
        } else {
          throw Exception('Token sesi tidak lengkap dari server backend.');
        }
      } else {
        throw Exception('Sesi tidak valid.');
      }
    } else {
      // Simulasi delay login mode demo
      await Future.delayed(const Duration(milliseconds: 1000));
      // Update status login secara manual khusus untuk mode demo
      _ref.read(isLoggedInProvider.notifier).state = true;
    }
  }

  /// Melakukan registrasi akun baru melalui Backend API
  Future<void> register(String email, String password, String fullName) async {
    if (EnvConfig.isSupabaseConfigured) {
      final response = await http.post(
        Uri.parse('${EnvConfig.backendUrl}/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'full_name': fullName,
        }),
      );

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Gagal membuat akun ke server backend.');
      }

      final data = jsonDecode(response.body);
      final session = data['session'];

      if (session != null) {
        final refreshToken = session['refresh_token'] as String?;
        final accessToken = session['access_token'] as String?;
        if (refreshToken != null && accessToken != null) {
          // Set session lokal menggunakan refresh_token dan access_token agar SDK Supabase sinkron
          await Supabase.instance.client.auth.setSession(
            refreshToken,
            accessToken: accessToken,
          );
        }
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

/// FutureProvider reaktif untuk mengambil profil pengguna dari database melalui Backend API
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  if (!EnvConfig.isSupabaseConfigured) {
    // Return mock user in demo mode
    return {
      'full_name': 'Abay (Demo)',
      'email': 'abay@kapanbasi.com',
      'avatar_url': null,
    };
  }
  
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) return null;
  
  try {
    final response = await http.get(
      Uri.parse('${EnvConfig.backendUrl}/api/profile'),
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
        'Content-Type': 'application/json',
      },
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
  } catch (e) {
    // Abaikan dan gunakan fallback metadata
  }
  
  // Fallback to metadata
  final currentUser = Supabase.instance.client.auth.currentUser;
  if (currentUser != null) {
    return {
      'full_name': currentUser.userMetadata?['full_name'] ?? 'Pengguna KapanBasi',
      'email': currentUser.email ?? '',
      'avatar_url': currentUser.userMetadata?['avatar_url'],
    };
  }
  
  return null;
});
