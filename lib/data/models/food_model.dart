import 'package:supabase_flutter/supabase_flutter.dart';

/// Model data untuk bahan makanan / produk ("Food").
/// Memiliki properti yang disesuaikan untuk aplikasi KapanBasi.
class FoodModel {
  final String id;
  final String? userId; // ID pengguna pemilik item
  final String name;
  final String category; // Buah, Sayur, Minuman, dll.
  final String storageLocation; // Tempat penyimpanan (Kulkas Bawah, Freezer, dll)
  final DateTime startDate; // Tanggal Masuk (purchase_date)
  final DateTime expiryDate; // Tanggal Kedaluwarsa (expiry_date)
  final String? imageUrl;
  final bool isConsumed; // Apakah item sudah selesai dikonsumsi
  final int quantity; // Jumlah stok barang
  final String unit; // Satuan (Liter, Kg, Pcs, dll)
  final String? notes; // Catatan tambahan opsional

  FoodModel({
    required this.id,
    this.userId,
    required this.name,
    required this.category,
    required this.storageLocation,
    required this.startDate,
    required this.expiryDate,
    this.imageUrl,
    this.isConsumed = false,
    this.quantity = 1,
    this.unit = 'pcs',
    this.notes,
  });

  /// Factory untuk membuat instance [FoodModel] dari JSON hasil query Supabase (aman & null-safe)
  factory FoodModel.fromJson(Map<String, dynamic> json) {
    // Mengekstrak tanggal masuk dari berbagai kemungkinan nama kolom
    final String? dateStr = json['purchase_date'] as String? ?? 
                           json['start_date'] as String? ?? 
                           json['created_at'] as String?;

    return FoodModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String?,
      name: json['name'] as String? ?? 'Tanpa Nama',
      category: json['category'] as String? ?? 'Makanan',
      storageLocation: json['storage_location'] as String? ?? 'Disimpan',
      startDate: DateTime.tryParse(dateStr ?? '') ?? DateTime.now(),
      expiryDate: DateTime.tryParse(json['expiry_date'] as String? ?? '') ?? DateTime.now(),
      imageUrl: json['image_url'] as String?,
      isConsumed: json['is_consumed'] as bool? ?? false,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unit: json['unit'] as String? ?? 'pcs',
      notes: json['notes'] as String?,
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
      'purchase_date': startDate.toIso8601String().split('T')[0],
      'image_url': imageUrl,
      'quantity': quantity,
      'unit': unit,
      'notes': notes,
      'is_consumed': isConsumed,
    };

    // Mengambil ID pengguna yang terautentikasi saat ini
    if (userId != null) {
      data['user_id'] = userId;
    } else {
      try {
        final String? currentUserId = Supabase.instance.client.auth.currentUser?.id;
        if (currentUserId != null) {
          data['user_id'] = currentUserId;
        }
      } catch (_) {
        // Abaikan jika dipanggil dalam lingkungan widget test
      }
    }

    return data;
  }

  /// Helper untuk menyalin objek dengan modifikasi parsial
  FoodModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? category,
    String? storageLocation,
    DateTime? startDate,
    DateTime? expiryDate,
    String? imageUrl,
    bool? isConsumed,
    int? quantity,
    String? unit,
    String? notes,
  }) {
    return FoodModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      category: category ?? this.category,
      storageLocation: storageLocation ?? this.storageLocation,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      imageUrl: imageUrl ?? this.imageUrl,
      isConsumed: isConsumed ?? this.isConsumed,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
    );
  }
}
