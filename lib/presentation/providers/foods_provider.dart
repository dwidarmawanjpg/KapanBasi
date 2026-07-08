import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/food_model.dart';
import '../../data/services/supabase_service.dart';
import '../providers/settings_provider.dart';

/// Provider global untuk instance [SupabaseService].
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

/// FutureProvider reaktif untuk memuat daftar bahan makanan AKTIF (belum selesai) dari database Supabase.
/// Digunakan oleh halaman Home. Setiap kali data berhasil dimuat, pengingat harian
/// di-reschedule agar isinya mencerminkan kondisi pantry terkini.
final foodsProvider = FutureProvider<List<FoodModel>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  final foods = await service.getFoods();

  // Reschedule pengingat harian dengan konten terbaru (fire-and-forget)
  ref.read(settingsServiceProvider).refreshDailyReminderContent(foods).ignore();

  return foods;
});

/// FutureProvider reaktif untuk memuat SELURUH riwayat bahan makanan (termasuk yang sudah selesai/basi).
/// Digunakan oleh halaman Collection.
final collectionFoodsProvider = FutureProvider<List<FoodModel>>((ref) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getAllFoods();
});

/// FutureProvider reaktif untuk memuat daftar lokasi penyimpanan dari database Supabase.
final storageLocationsProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getStorageLocations();
});
