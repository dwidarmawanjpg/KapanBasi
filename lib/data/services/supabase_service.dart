
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/env/env_config.dart';
import '../models/food_model.dart';

/// Service class yang berinteraksi dengan Custom Backend API.
/// Menyediakan fungsi CRUD database dan upload asset/media.
class SupabaseService {
  /// Mengambil JWT token dari session aktif lokal
  String? get _token {
    try {
      if (EnvConfig.isSupabaseConfigured) {
        return Supabase.instance.client.auth.currentSession?.accessToken;
      }
    } catch (_) {}
    return null;
  }

  /// Helper untuk headers standar yang menyertakan token otentikasi
  Map<String, String> get _headers {
    final token = _token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Mengambil daftar bahan makanan yang masih AKTIF (belum ditandai selesai/`is_consumed = false`).
  /// Digunakan oleh halaman Home agar hanya menampilkan barang yang masih perlu dipantau.
  Future<List<FoodModel>> getFoods() async {
    final allFoods = await getAllFoods();
    // Filter lokal untuk isConsumed agar terhindar dari sisa item selesai
    return allFoods.where((food) => !food.isConsumed).toList();
  }

  /// Mengambil SELURUH daftar bahan makanan tanpa filter status (termasuk yang sudah selesai/`is_consumed = true`).
  /// Digunakan oleh halaman Collection sebagai riwayat lengkap.
  Future<List<FoodModel>> getAllFoods() async {
    try {
      final response = await http.get(
        Uri.parse('${EnvConfig.backendUrl}/api/foods'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Gagal mengambil data dari backend.');
      }

      final List<dynamic> list = jsonDecode(response.body);
      return list
          .map((json) => FoodModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error getAllFoods: $e');
      throw Exception('Gagal mengambil daftar makanan dari Backend: $e');
    }
  }

  /// Menambahkan bahan makanan baru melalui API backend
  Future<FoodModel> insertFood(FoodModel food) async {
    try {
      final response = await http.post(
        Uri.parse('${EnvConfig.backendUrl}/api/foods'),
        headers: _headers,
        body: jsonEncode(food.toJson()),
      );

      if (response.statusCode != 201 && response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Gagal menyimpan ke backend.');
      }

      final Map<String, dynamic> json = jsonDecode(response.body);
      return FoodModel.fromJson(json);
    } catch (e) {
      debugPrint('Error insertFood: $e');
      throw Exception('Gagal menyimpan bahan makanan ke Backend: $e');
    }
  }

  /// Memperbarui data bahan makanan melalui API backend
  Future<FoodModel> updateFood(FoodModel food) async {
    try {
      final response = await http.put(
        Uri.parse('${EnvConfig.backendUrl}/api/foods/${food.id}'),
        headers: _headers,
        body: jsonEncode(food.toJson()),
      );

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Gagal memperbarui data di backend.');
      }

      final Map<String, dynamic> json = jsonDecode(response.body);
      return FoodModel.fromJson(json);
    } catch (e) {
      debugPrint('Error updateFood: $e');
      throw Exception('Gagal memperbarui bahan makanan di Backend: $e');
    }
  }

  /// Menghapus bahan makanan melalui API backend
  Future<void> deleteFood(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${EnvConfig.backendUrl}/api/foods/$id'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Gagal menghapus data di backend.');
      }
    } catch (e) {
      debugPrint('Error deleteFood: $e');
      throw Exception('Gagal menghapus bahan makanan di Backend: $e');
    }
  }

  /// Mengambil daftar semua lokasi penyimpanan dari API backend
  Future<List<Map<String, dynamic>>> getStorageLocations() async {
    try {
      final response = await http.get(
        Uri.parse('${EnvConfig.backendUrl}/api/storage-locations'),
        headers: _headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Gagal memuat storage locations.');
      }

      final List<dynamic> list = jsonDecode(response.body);
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error getStorageLocations: $e');
      // Fallback default jika backend offline / belum siap
      return [
        {'id': 'd1', 'name': 'Kulkas Bawah'},
        {'id': 'd2', 'name': 'Freezer'},
        {'id': 'd3', 'name': 'Lemari Dapur'},
        {'id': 'd4', 'name': 'Meja Makan'},
      ];
    }
  }

  /// Memperbarui profil pengguna (full_name dan/atau avatar_url) melalui backend.
  Future<Map<String, dynamic>> updateProfile({
    required String fullName,
    String? avatarUrl,
  }) async {
    try {
      final body = <String, dynamic>{'full_name': fullName};
      if (avatarUrl != null) body['avatar_url'] = avatarUrl;

      final response = await http.put(
        Uri.parse('${EnvConfig.backendUrl}/api/profile'),
        headers: _headers,
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Gagal memperbarui profil.');
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error updateProfile: $e');
      throw Exception('Gagal memperbarui profil: $e');
    }
  }

  /// Mengganti password pengguna melalui backend.
  Future<void> changePassword(String newPassword) async {
    try {
      final response = await http.put(
        Uri.parse('${EnvConfig.backendUrl}/api/profile/password'),
        headers: _headers,
        body: jsonEncode({'new_password': newPassword}),
      );

      if (response.statusCode != 200) {
        final err = jsonDecode(response.body);
        throw Exception(err['error'] ?? 'Gagal mengganti password.');
      }
    } catch (e) {
      debugPrint('Error changePassword: $e');
      throw Exception('Gagal mengganti password: $e');
    }
  }

  /// Mengunggah gambar makanan melalui API backend.
  Future<String?> uploadImage(String filePath, String fileName) async {
    try {
      final token = _token;
      if (token == null) throw Exception('Pengguna tidak terautentikasi.');

      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File lokal tidak ditemukan di path: $filePath');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${EnvConfig.backendUrl}/api/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('image', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode != 200) {
        final body = jsonDecode(response.body);
        throw Exception(body['error'] ?? 'Gagal mengunggah gambar ke backend.');
      }

      final data = jsonDecode(response.body);
      return data['imageUrl'] as String?;
    } catch (e) {
      debugPrint('Error uploadImage (Abaikan jika gagal): $e');
      return null;
    }
  }
}
