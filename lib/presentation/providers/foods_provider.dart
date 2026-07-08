import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/food_model.dart';
import '../../data/services/supabase_service.dart';
import '../providers/settings_provider.dart';

/// Provider global untuk instance [SupabaseService].
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// FutureProvider reaktif untuk memuat SELURUH riwayat bahan makanan
/// (termasuk yang sudah selesai/basi) dari database.
///
/// Ini adalah SATU-SATUNYA sumber data (single source of truth) untuk daftar
/// bahan makanan di seluruh aplikasi. [foodsProvider] di bawah hanya
/// menyaring hasil dari provider ini secara lokal, TIDAK melakukan fetch
/// terpisah. Ini memastikan Home dan Search/History selalu menampilkan data
/// yang identik & sinkron, karena keduanya berasal dari future yang sama.
final collectionFoodsProvider = FutureProvider<List<FoodModel>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getAllFoods();
});

/// FutureProvider reaktif untuk memuat SEMUA bahan makanan. Digunakan oleh
/// halaman Home. Sama seperti [collectionFoodsProvider] datanya (tanpa
/// filter isConsumed, karena aplikasi ini hanya mengenal 3 status murni
/// berdasar sisa hari ke kedaluwarsa: Aman / Kritis / Basi), hanya berbeda
/// di urutan (created_at descending) dan efek samping reschedule notifikasi.
///
/// Tetap "watch" ke [collectionFoodsProvider] (bukan fetch terpisah) supaya
/// Home selalu sinkron dengan Search/History.
final foodsProvider = FutureProvider<List<FoodModel>>((ref) async {
  final allFoods = await ref.watch(collectionFoodsProvider.future);

  // Urutkan agar barang yang paling baru ditambahkan tampil paling atas
  // (created_at descending, fallback ke startDate bila created_at kosong).
  final sortedFoods = [...allFoods]
    ..sort(
      (a, b) =>
          (b.createdAt ?? b.startDate).compareTo(a.createdAt ?? a.startDate),
    );

  // Reschedule pengingat harian dengan konten terbaru (fire-and-forget)
  ref
      .read(settingsServiceProvider)
      .refreshDailyReminderContent(sortedFoods)
      .ignore();

  return sortedFoods;
});

/// FutureProvider reaktif untuk memuat daftar lokasi penyimpanan dari database Supabase.
final storageLocationsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getStorageLocations();
});