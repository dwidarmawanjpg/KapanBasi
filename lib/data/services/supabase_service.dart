import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/env/env_config.dart';
import '../models/food_model.dart';

/// Service class yang berinteraksi langsung dengan Supabase API.
/// Menyediakan fungsi CRUD database dan upload asset/media.
class SupabaseService {
  
  /// Lazily get the client only if Supabase is configured.
  SupabaseClient get _client {
    if (!EnvConfig.isSupabaseConfigured) {
      throw Exception('Supabase belum terkonfigurasi di berkas .env.');
    }
    return Supabase.instance.client;
  }

  /// Mengambil semua daftar bahan makanan dari tabel 'foods'
  /// Melakukan filter lokal untuk is_consumed agar aman dari error kolom tidak ditemukan
  Future<List<FoodModel>> getFoods() async {
    try {
      final List<Map<String, dynamic>> response = await _client
          .from('foods')
          .select()
          .order('expiry_date', ascending: true);

      final List<FoodModel> allFoods = response.map((json) => FoodModel.fromJson(json)).toList();
      
      // Filter lokal untuk isConsumed agar terhindar dari crash SQL
      return allFoods.where((food) => !food.isConsumed).toList();
    } catch (e) {
      debugPrint('Error getFoods: $e');
      throw Exception('Gagal mengambil daftar makanan dari Supabase: $e');
    }
  }

  /// Menambahkan bahan makanan baru ke tabel 'foods'
  Future<FoodModel> insertFood(FoodModel food) async {
    try {
      final Map<String, dynamic> response = await _client
          .from('foods')
          .insert(food.toJson())
          .select()
          .single();

      return FoodModel.fromJson(response);
    } catch (e) {
      debugPrint('Error insertFood: $e');
      throw Exception('Gagal menyimpan bahan makanan ke Supabase: $e');
    }
  }

  /// Memperbarui data bahan makanan (termasuk status is_consumed) di tabel 'foods'
  /// Memiliki penanganan fallback jika kolom is_consumed tidak ada di database online
  Future<FoodModel> updateFood(FoodModel food) async {
    try {
      final Map<String, dynamic> updateData = food.toJson();
      // Tambahkan is_consumed secara dinamis untuk dicoba
      updateData['is_consumed'] = food.isConsumed;

      final Map<String, dynamic> response = await _client
          .from('foods')
          .update(updateData)
          .eq('id', food.id)
          .select()
          .single();

      return FoodModel.fromJson(response);
    } catch (e) {
      debugPrint('Error updateFood (Mencoba fallback): $e');
      
      // Fallback 1: Jika user klik selesai, tapi kolom is_consumed tidak ada,
      // maka kita hapus item tersebut agar secara fungsi beranda tetap bersih.
      if (food.isConsumed) {
        try {
          await deleteFood(food.id);
          return food; // Kembalikan objek agar flow UI tidak crash
        } catch (_) {}
      }

      // Fallback 2: Jika kegagalan terjadi saat melakukan edit biasa (nama/kategori),
      // coba lakukan update tanpa menyertakan kolom is_consumed
      try {
        final Map<String, dynamic> response = await _client
            .from('foods')
            .update(food.toJson()) // Hanya memuat field dasar
            .eq('id', food.id)
            .select()
            .single();
        return FoodModel.fromJson(response);
      } catch (err2) {
        throw Exception('Gagal memperbarui bahan makanan di Supabase: $err2');
      }
    }
  }

  /// Menghapus bahan makanan dari tabel 'foods'
  Future<void> deleteFood(String id) async {
    try {
      await _client
          .from('foods')
          .delete()
          .eq('id', id);
    } catch (e) {
      debugPrint('Error deleteFood: $e');
      throw Exception('Gagal menghapus bahan makanan di Supabase: $e');
    }
  }

  /// Mengambil daftar semua lokasi penyimpanan untuk diisi di dropdown Form Tambah Makanan
  Future<List<Map<String, dynamic>>> getStorageLocations() async {
    try {
      final List<Map<String, dynamic>> response = await _client
          .from('storage_locations')
          .select();
      return response;
    } catch (e) {
      debugPrint('Error getStorageLocations: $e');
      // Fallback default jika tabel belum disiapkan / diisi agar form tidak crash
      return [
        {'id': 'd1', 'name': 'Kulkas Bawah'},
        {'id': 'd2', 'name': 'Freezer'},
        {'id': 'd3', 'name': 'Lemari Dapur'},
        {'id': 'd4', 'name': 'Meja Makan'},
      ];
    }
  }

  /// Mengunggah gambar makanan ke Supabase Storage Bucket bernama 'food-images'.
  /// Menggunakan penanganan error yang aman (tidak menggagalkan proses simpan jika upload gagal)
  Future<String?> uploadImage(String filePath, String fileName) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('File lokal tidak ditemukan di path: $filePath');
      }

      // Mengunggah file ke bucket 'food-images'
      await _client.storage.from('food-images').upload(
            fileName,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: true,
            ),
          );

      // Mengambil URL Publik agar bisa diakses oleh aplikasi
      final String publicUrl = _client.storage.from('food-images').getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      // Log error storage tetapi jangan digagalkan di form agar tetap bisa menyimpan teks data
      debugPrint('Error uploadImage (Abaikan jika bucket/policy belum di-set): $e');
      return null;
    }
  }
}
