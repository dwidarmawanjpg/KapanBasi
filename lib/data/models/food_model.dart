import 'package:supabase_flutter/supabase_flutter.dart';

/// Model data untuk bahan makanan / produk ("Food").
/// Memiliki properti yang disesuaikan untuk aplikasi KapanBasi.
class FoodModel {
  final String id;
  final String name;
  final String category; // Makanan atau Minuman
  final String storageLocation; // Nama lokasi (default 'Disimpan')
  final DateTime startDate; // Tanggal Masuk (purchase_date)
  final DateTime expiryDate; // Tanggal Kedaluwarsa (expiry_date)
  final String? imageUrl;
  final bool isConsumed; // Apakah item sudah selesai dikonsumsi

  FoodModel({
    required this.id,
    required this.name,
    required this.category,
    required this.storageLocation,
    required this.startDate,
    required this.expiryDate,
    this.imageUrl,
    this.isConsumed = false,
  });

  /// Factory untuk membuat instance [FoodModel] dari JSON hasil query Supabase (aman & null-safe)
  factory FoodModel.fromJson(Map<String, dynamic> json) {
    // Mengekstrak tanggal masuk dari berbagai kemungkinan nama kolom
    final String? dateStr = json['purchase_date'] as String? ?? 
                           json['start_date'] as String? ?? 
                           json['created_at'] as String?;

    return FoodModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Tanpa Nama',
      category: json['category'] as String? ?? 'Makanan',
      storageLocation: json['storage_location'] as String? ?? 'Disimpan',
      startDate: DateTime.tryParse(dateStr ?? '') ?? DateTime.now(),
      expiryDate: DateTime.tryParse(json['expiry_date'] as String? ?? '') ?? DateTime.now(),
      imageUrl: json['image_url'] as String?,
      isConsumed: json['is_consumed'] as bool? ?? false,
    );
  }

  /// Mengonversi instance [FoodModel] ke bentuk JSON map untuk dikirim ke Supabase
  /// Menyertakan storage_location & user_id secara dinamis agar lolos RLS policy (Error 42501) & NOT NULL constraint (Error 23502)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'id': id,
      'name': name,
      'category': category,
      'storage_location': storageLocation, // Wajib dikirim karena NOT NULL di database
      'expiry_date': expiryDate.toIso8601String().split('T')[0],
      'image_url': imageUrl,
    };

    // Mengambil ID pengguna yang terautentikasi saat ini
    try {
      final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId != null) {
        data['user_id'] = currentUserId;
      }
    } catch (_) {
      // Abaikan jika dipanggil dalam lingkungan widget test
    }

    return data;
  }

  /// Helper untuk menyalin objek dengan modifikasi parsial
  FoodModel copyWith({
    String? id,
    String? name,
    String? category,
    String? storageLocation,
    DateTime? startDate,
    DateTime? expiryDate,
    String? imageUrl,
    bool? isConsumed,
  }) {
    return FoodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      storageLocation: storageLocation ?? this.storageLocation,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
      isConsumed: isConsumed ?? this.isConsumed,
    );
  }
}
